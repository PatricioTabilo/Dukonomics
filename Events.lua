-- Dukonomics: Event handling for auction house posting
--
-- AUCTION TRACKING SYSTEM:
--
-- This module tracks auction postings and cancellations using WoW's Auction House API.
-- Since auctionID is not immediately available when posting, we use a two-phase approach:
--
-- 1. POSTING PHASE:
--    - Hook PostItem/PostCommodity to save posting data immediately
--    - Trigger OWNED_AUCTIONS_UPDATED event to populate auctionID cache
--
-- 2. CACHING PHASE:
--    - OWNED_AUCTIONS_UPDATED event rebuilds ownedAuctionsCache with all active auctions
--    - Cache maps auctionID -> auction details (quantity, price, itemName, etc.)
--
-- 3. CANCELLATION PHASE:
--    - OnCancelAuction receives auctionID from WoW API
--    - Compares current auction info with cached info to detect partial sales
--    - Updates posting records accordingly
--
-- PARTIAL SALE DETECTION:
--    If cachedQuantity > currentQuantity, items were sold before cancellation
--    We track both the sold amount and the cancelled amount

Dukonomics.Events = {}

-- Cache of owned auctions (indexed by auctionID)
-- Used to detect which auctions were cancelled by comparing before/after
local ownedAuctionsCache = {}
local previousAuctionsCache = {}

-- Queue of postings awaiting auctionID linkage
local pendingLinkQueue = {}

-- Local sequence to disambiguate identical postings
local postingSequence = 0

local function NextPostingSequence()
  postingSequence = postingSequence + 1
  return postingSequence
end

local function DebugPendingLinkQueue(context)
  if not pendingLinkQueue or #pendingLinkQueue == 0 then
    Dukonomics.Logger.debug("  Cola de pendientes: vacía" .. (context and (" (" .. context .. ")") or ""))
    return
  end

  Dukonomics.Logger.debug("  Cola de pendientes" .. (context and (" (" .. context .. ")") or "") .. ":")
  for i = #pendingLinkQueue, 1, -1 do
    local pending = pendingLinkQueue[i]
    if pending and pending.posting then
      Dukonomics.Logger.debug("    [" .. i .. "] seq=" .. tostring(pending.postingSeq) ..
        " itemID=" .. tostring(pending.itemID) ..
        " cant=" .. tostring(pending.quantity) ..
        " unit=" .. tostring(pending.unitPrice) ..
        " total=" .. tostring(pending.totalPrice) ..
        " altUnit=" .. tostring(pending.altUnitPrice) ..
        " altTotal=" .. tostring(pending.altTotalPrice) ..
        " link=" .. tostring(pending.linked))
    end
  end
end

local function PriceMatchesPending(pending, cacheUnitPrice, cacheTotalPrice)
  if not pending then return false end

  local candidates = {
    pending.unitPrice,
    pending.totalPrice,
    pending.altUnitPrice,
    pending.altTotalPrice
  }

  for _, price in ipairs(candidates) do
    if price and (price == cacheUnitPrice or price == cacheTotalPrice) then
      return true
    end
  end

  return false
end

local function PriceMatchesPosting(posting, cacheUnitPrice, cacheTotalPrice, quantity)
  if not posting or not posting.price then
    return false
  end

  local candidates = {
    posting.price,
    posting.totalPrice
  }

  if quantity and quantity > 1 then
    table.insert(candidates, posting.price * quantity)
    table.insert(candidates, math.floor(posting.price / quantity))
  end

  for _, price in ipairs(candidates) do
    if price and (price == cacheUnitPrice or price == cacheTotalPrice) then
      return true
    end
  end

  return false
end

local function InferPricesForAuction(auctionInfo)
  if not auctionInfo then
    return 0, 0
  end

  local quantity = auctionInfo.quantity or 1
  local rawPrice = auctionInfo.buyoutAmount or auctionInfo.bidAmount or 0
  local itemID = auctionInfo.itemID or (auctionInfo.itemKey and auctionInfo.itemKey.itemID)

  -- Intentamos inferir si el precio de Blizzard es unitario o total,
  -- comparándolo con la cola de postings pendientes.
  if itemID and quantity > 0 and rawPrice > 0 then
    for i = #pendingLinkQueue, 1, -1 do
      local pending = pendingLinkQueue[i]
      if pending and not pending.linked and pending.itemID == itemID and pending.quantity == quantity then
        if pending.unitPrice == rawPrice or pending.altUnitPrice == rawPrice then
          return rawPrice, rawPrice * quantity
        end
        if pending.totalPrice == rawPrice or pending.altTotalPrice == rawPrice then
          return math.floor(rawPrice / quantity), rawPrice
        end
      end
    end
  end

  if quantity > 0 then
    return math.floor(rawPrice / quantity), rawPrice
  end

  return rawPrice, rawPrice
end

local function IsAuctionIDLinked(auctionID)
  if not auctionID or not DUKONOMICS_DATA or not DUKONOMICS_DATA.postings then
    return false
  end

  for _, posting in ipairs(DUKONOMICS_DATA.postings) do
    if posting.auctionID == auctionID then
      return true
    end
  end

  return false
end

-- Event handler to track auction creation
local function OnAuctionHouseShow()
  Dukonomics.Logger.debug("Auction House opened, registering for owned auction updates")
end

-- Try to link auctionID to our posting records
local function LinkAuctionToPosting(auctionID, auctionInfo)
  if not auctionInfo then return end

  if IsAuctionIDLinked(auctionID) then
    Dukonomics.Logger.debug("LinkAuctionToPosting: auctionID ya estaba vinculado, se omite")
    return true
  end

  local itemID = auctionInfo.itemKey and auctionInfo.itemKey.itemID
  local itemName = itemID and C_Item.GetItemInfo(itemID)
  local quantity = auctionInfo.quantity or 1
  local unitPrice, totalPrice = InferPricesForAuction(auctionInfo)

  local searchName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or ""

  Dukonomics.Logger.debug("LinkAuctionToPosting: intentando linkear auctionID")
  Dukonomics.Logger.debug("  auctionID=" .. tostring(auctionID) ..
                  " itemID=" .. tostring(itemID) ..
                  " itemName=" .. tostring(itemName) ..
                  " cant=" .. tostring(quantity))
  Dukonomics.Logger.debug("  precios (inferidos): unit=" .. tostring(unitPrice) ..
                  " total=" .. tostring(totalPrice))

  if not itemID and searchName == "" then
    Dukonomics.Logger.debug("  LinkAuctionToPosting: falta itemID y itemName, no se puede linkear")
    return
  end

  -- Prefer matching from the pending link queue (most recent first)
  for i = #pendingLinkQueue, 1, -1 do
    local pending = pendingLinkQueue[i]
    if pending and not pending.linked and
       ((pending.itemID and itemID and pending.itemID == itemID) or
        (pending.itemName == searchName and searchName ~= "")) and
       pending.quantity == quantity and
       PriceMatchesPending(pending, unitPrice, totalPrice) then
      local posting = pending.posting
      if posting and posting.status == "active" and not posting.auctionID then
        posting.auctionID = auctionID
        posting.linkedByAuctionID = true
        pending.linked = true
        Dukonomics.Logger.debug("  ✅ Link exitoso: auctionID " .. auctionID .. " asignado al posting pendiente")
        return true
      end
    end
  end

  -- Fallback: Find an active posting that matches AND doesn't have an auctionID yet
  -- Search in REVERSE order (newest first) to link most recent postings first
  if DUKONOMICS_DATA and DUKONOMICS_DATA.postings then
    for i = #DUKONOMICS_DATA.postings, 1, -1 do
      local posting = DUKONOMICS_DATA.postings[i]
      if posting.status == "active" and
         not posting.auctionID and
         ((posting.itemID and itemID and posting.itemID == itemID) or
          (posting.itemName and posting.itemName:lower() == searchName and searchName ~= "")) and
      posting.count == quantity and
      PriceMatchesPosting(posting, unitPrice, totalPrice, quantity) then
        posting.auctionID = auctionID
        posting.linkedByAuctionID = true
        Dukonomics.Logger.debug("  ✅ Link exitoso: auctionID " .. auctionID .. " asignado al posting [" .. i .. "]")
        return true
      end
    end
  end

  Dukonomics.Logger.debug("  ❌ No hubo match para auctionID " .. tostring(auctionID))
  DebugPendingLinkQueue("sin match")
  return false
end

-- Detect cancelled auctions by comparing caches
-- Stores the info of recently removed auctions for Mail.lua to use
local recentlyRemovedAuctions = {}

-- Store the auctionID that was just cancelled (set by CancelAuction hook)
local lastCancelledAuctionID = nil

local function DetectCancelledAuctions(newCache)
  -- Clear old removed auctions (keep only recent ones)
  recentlyRemovedAuctions = {}

  for auctionID, oldInfo in pairs(previousAuctionsCache) do
    if not newCache[auctionID] then
      -- This auction no longer exists - it was cancelled, expired, or sold
      Dukonomics.Logger.debug("Auction " .. auctionID .. " disappeared from owned list")

      -- Store the removed auction info for Mail.lua to use
      recentlyRemovedAuctions[auctionID] = oldInfo

      -- Find our posting with this auctionID and mark it as "pending_removal"
      if DUKONOMICS_DATA and DUKONOMICS_DATA.postings then
        for _, posting in ipairs(DUKONOMICS_DATA.postings) do
          if posting.auctionID == auctionID and posting.status == "active" then
            if lastCancelledAuctionID and auctionID == lastCancelledAuctionID then
              local cancelQuantity = posting.pendingRemovalQuantity or oldInfo.quantity or posting.count or 1
              posting.pendingRemoval = nil
              posting.pendingRemovalType = nil
              posting.pendingRemovalQuantity = nil
              posting.cancelledByEvent = true
              Dukonomics.Data.ReducePostingQuantity(posting, cancelQuantity, "cancelled")
              Dukonomics.Logger.debug("  ✅ Marked posting as cancelled (event): " .. tostring(posting.itemName) ..
                              " x" .. tostring(cancelQuantity) .. " @ " .. tostring(posting.price))
              lastCancelledAuctionID = nil
            else
              posting.pendingRemoval = true
              posting.pendingRemovalType = "unknown"
              Dukonomics.Logger.debug("  Marked posting as pendingRemoval: " .. tostring(posting.itemName) ..
                              " x" .. tostring(posting.count) .. " @ " .. tostring(posting.price))
            end
            break
          end
        end
      end
    end
  end
end

-- Public function to get recently removed auction info
-- Called by Mail.lua to find the correct posting when processing cancellation mail
function Dukonomics.Events.GetRemovedAuctionByItem(itemName, quantity)
  local searchName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or ""

  for auctionID, info in pairs(recentlyRemovedAuctions) do
    local infoName = info.itemName and info.itemName:match("^%s*(.-)%s*$"):lower() or ""
    if infoName == searchName and info.quantity == quantity then
      Dukonomics.Logger.debug("GetRemovedAuctionByItem: Found auctionID " .. auctionID .. " for " .. itemName)
      return auctionID, info
    end
  end

  Dukonomics.Logger.debug("GetRemovedAuctionByItem: NOT FOUND for " .. tostring(itemName) .. " x" .. tostring(quantity))
  return nil, nil
end

-- Hook for CancelAuction - just capture the auctionID
-- The auctionID is passed directly as parameter, we don't need auction info
local function ApplyImmediateCancellation(posting, cancelQuantity)
  if not posting or not cancelQuantity or cancelQuantity <= 0 then
    return false
  end

  posting.pendingRemoval = nil
  posting.pendingRemovalType = nil
  posting.pendingRemovalQuantity = nil
  posting.cancelledByEvent = true
  Dukonomics.Data.ReducePostingQuantity(posting, cancelQuantity, "cancelled")
  lastCancelledAuctionID = nil
  return true
end

local function OnCancelAuction(auctionID)
  Dukonomics.Logger.debug("========================================")
  Dukonomics.Logger.debug("🚫 CancelAuction hook fired: auctionID = " .. tostring(auctionID))
  lastCancelledAuctionID = auctionID

  -- First, try to get info about this auction from the cache
  local auctionInfo = ownedAuctionsCache[auctionID]

  -- Mark the posting with this auctionID as pending cancellation
  local found = false
  if auctionID and DUKONOMICS_DATA and DUKONOMICS_DATA.postings then
    -- Try to find by auctionID first
    for i, posting in ipairs(DUKONOMICS_DATA.postings) do
      if posting.auctionID == auctionID and posting.status == "active" then
        posting.pendingRemoval = true
        posting.pendingRemovalType = "cancelled"
        posting.pendingRemovalQuantity = auctionInfo and auctionInfo.quantity or posting.count
        posting.cancelledAuctionID = auctionID
        Dukonomics.Logger.debug("  ✅ Marked posting [" .. i .. "] for cancellation (by auctionID):")
        Dukonomics.Logger.debug("     Item: " .. tostring(posting.itemName))
        Dukonomics.Logger.debug("     Quantity: " .. tostring(posting.count))
        Dukonomics.Logger.debug("     Price: " .. tostring(posting.price) .. "c")
        local cancelQuantity = posting.pendingRemovalQuantity or posting.count or 1
        if ApplyImmediateCancellation(posting, cancelQuantity) then
          Dukonomics.Logger.debug("  ✅ Cancelación aplicada inmediatamente: " .. tostring(cancelQuantity))
        end
        found = true
        break
      end
    end

    -- If not found by auctionID, try to link it now using cached auction info
    if not found and auctionInfo then
      local itemName = auctionInfo.itemName
      local itemID = auctionInfo.itemID
      local quantity = auctionInfo.quantity
      local unitPrice = auctionInfo.unitPrice
      local totalPrice = auctionInfo.totalPrice
      if not unitPrice or not totalPrice then
        local rawPrice = auctionInfo.buyoutAmount or auctionInfo.bidAmount or 0
        unitPrice = quantity and quantity > 0 and math.floor(rawPrice / quantity) or rawPrice
        totalPrice = rawPrice
      end
      local searchName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or ""

  Dukonomics.Logger.debug("  Intentando linkear con cache (CancelAuction):")
  Dukonomics.Logger.debug("     Item: " .. tostring(itemName))
  Dukonomics.Logger.debug("     Cantidad: " .. tostring(quantity))
  Dukonomics.Logger.debug("     Precio unit: " .. tostring(unitPrice) .. " | total: " .. tostring(totalPrice))

   -- Prefer pending queue match first
   for i = #pendingLinkQueue, 1, -1 do
        local pending = pendingLinkQueue[i]
        if pending and not pending.linked and
     ((pending.itemID and itemID and pending.itemID == itemID) or
      (pending.itemName == searchName and searchName ~= "")) and
     pending.quantity == quantity and
     PriceMatchesPending(pending, unitPrice, totalPrice) then
          local posting = pending.posting
          if posting and posting.status == "active" and not posting.auctionID then
            posting.auctionID = auctionID
            posting.pendingRemoval = true
            posting.pendingRemovalType = "cancelled"
            posting.pendingRemovalQuantity = quantity
            posting.cancelledAuctionID = auctionID
            posting.linkedByAuctionID = true
            pending.linked = true
            Dukonomics.Logger.debug("  ✅ Link OK (pending) + marcado cancelación:")
            Dukonomics.Logger.debug("     Item: " .. tostring(posting.itemName))
            Dukonomics.Logger.debug("     Cantidad: " .. tostring(posting.count))
            Dukonomics.Logger.debug("     Precio unit: " .. tostring(posting.price) .. "c")
            local cancelQuantity = posting.pendingRemovalQuantity or posting.count or quantity or 1
            if ApplyImmediateCancellation(posting, cancelQuantity) then
              Dukonomics.Logger.debug("  ✅ Cancelación aplicada inmediatamente: " .. tostring(cancelQuantity))
            end
            found = true
            break
          end
        end
      end

      -- Fallback: Find matching posting and link it (search newest first - LIFO)
      if not found then
     for i = #DUKONOMICS_DATA.postings, 1, -1 do
          local posting = DUKONOMICS_DATA.postings[i]
          if posting.status == "active" and
             not posting.auctionID and
             ((posting.itemID and itemID and posting.itemID == itemID) or
              (posting.itemName and itemName and posting.itemName:lower() == searchName and searchName ~= "")) and
       posting.count == quantity and
       PriceMatchesPosting(posting, unitPrice, totalPrice, quantity) then
            -- Link it!
            posting.auctionID = auctionID
            posting.pendingRemoval = true
            posting.pendingRemovalType = "cancelled"
            posting.pendingRemovalQuantity = quantity
            posting.cancelledAuctionID = auctionID
            posting.linkedByAuctionID = true
            Dukonomics.Logger.debug("  ✅ Link OK (fallback) + marcado cancelación [" .. i .. "]:")
            Dukonomics.Logger.debug("     Item: " .. tostring(posting.itemName))
            Dukonomics.Logger.debug("     Cantidad: " .. tostring(posting.count))
            Dukonomics.Logger.debug("     Precio unit: " .. tostring(posting.price) .. "c")
            local cancelQuantity = posting.pendingRemovalQuantity or posting.count or quantity or 1
            if ApplyImmediateCancellation(posting, cancelQuantity) then
              Dukonomics.Logger.debug("  ✅ Cancelación aplicada inmediatamente: " .. tostring(cancelQuantity))
            end
            found = true
            break
          end
        end
      end
    end
  end

  if not found then
    Dukonomics.Logger.debug("  ❌ WARNING: No posting found for auctionID " .. tostring(auctionID))
    if auctionInfo then
      Dukonomics.Logger.debug("  Auction info: " .. tostring(auctionInfo.itemName) .. " x" .. tostring(auctionInfo.quantity) .. " @ " .. tostring(auctionInfo.buyoutAmount or auctionInfo.bidAmount))
    else
      Dukonomics.Logger.debug("  No cached info for this auctionID")
    end
    Dukonomics.Logger.debug("  Active postings without auctionID:")
    if DUKONOMICS_DATA and DUKONOMICS_DATA.postings then
      local count = 0
      for i, posting in ipairs(DUKONOMICS_DATA.postings) do
        if posting.status == "active" and not posting.auctionID then
          count = count + 1
          Dukonomics.Logger.debug("     [" .. i .. "] " .. tostring(posting.itemName) .. " x" .. tostring(posting.count) .. " @ " .. tostring(posting.price) .. "c")
        end
      end
      if count == 0 then
        Dukonomics.Logger.debug("     (none - all active postings have auctionIDs)")
      end
    end
  end

  Dukonomics.Logger.debug("========================================")
end

-- Public function to get the last cancelled auctionID
function Dukonomics.Events.GetLastCancelledAuctionID()
  return lastCancelledAuctionID
end

-- Public function to find posting marked as pending removal
function Dukonomics.Events.FindPendingRemovalPosting(itemName, quantity)
  if not DUKONOMICS_DATA or not DUKONOMICS_DATA.postings then return nil end

  local searchName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or ""

  for _, posting in ipairs(DUKONOMICS_DATA.postings) do
    local postingName = posting.itemName and posting.itemName:match("^%s*(.-)%s*$"):lower() or ""
    if posting.pendingRemoval and
       posting.status == "active" and
       postingName == searchName and
       posting.count == quantity then
      Dukonomics.Logger.debug("FindPendingRemovalPosting: FOUND for " .. itemName)
      return posting
    end
  end

  Dukonomics.Logger.debug("FindPendingRemovalPosting: NOT FOUND for " .. tostring(itemName))
  return nil
end

-- Event handler for owned auctions list update
local function OnOwnedAuctionsUpdated()
  Dukonomics.Logger.debug("Owned auctions updated, refreshing cache...")

  -- Save previous cache for comparison
  previousAuctionsCache = ownedAuctionsCache
  ownedAuctionsCache = {}

  -- Rebuild cache from current owned auctions
  local numAuctions = C_AuctionHouse.GetNumOwnedAuctions()
  Dukonomics.Logger.debug("Found " .. numAuctions .. " owned auctions")

  for i = 1, numAuctions do
    local auctionInfo = C_AuctionHouse.GetOwnedAuctionInfo(i)
    if auctionInfo then
      local auctionID = auctionInfo.auctionID
      if auctionID then
        local itemID = auctionInfo.itemKey and auctionInfo.itemKey.itemID
        local itemName = itemID and C_Item.GetItemInfo(itemID)
        local quantity = auctionInfo.quantity or 1
        local buyoutAmount = auctionInfo.buyoutAmount
        local bidAmount = auctionInfo.bidAmount
        local unitPrice, totalPrice = InferPricesForAuction(auctionInfo)

        -- Store detailed cache info
        ownedAuctionsCache[auctionID] = {
          itemID = itemID,
          itemName = itemName,
          quantity = quantity,
          buyoutAmount = buyoutAmount,
          bidAmount = bidAmount,
          unitPrice = unitPrice,
          totalPrice = totalPrice,
          timeLeft = auctionInfo.timeLeft,
          status = auctionInfo.status
        }

  Dukonomics.Logger.debug("  Cache AH [" .. auctionID .. "]: " ..
      tostring(itemName) .. " x" .. quantity ..
      " | unit=" .. tostring(unitPrice) .. "c | total=" .. tostring(totalPrice) .. "c")

        -- Try to link this auction to a posting that doesn't have an auctionID yet
        if not itemName and itemID then
          Dukonomics.Logger.debug("  Cached auction missing itemName, itemID=" .. tostring(itemID))
        end

        LinkAuctionToPosting(auctionID, auctionInfo)
      end
    end
  end

  -- Count cache entries
  local cacheCount = 0
  for _ in pairs(ownedAuctionsCache) do cacheCount = cacheCount + 1 end
  Dukonomics.Logger.debug("Cache updated with " .. cacheCount .. " auctions")

  -- Clean up linked pending entries
  for i = #pendingLinkQueue, 1, -1 do
    if pendingLinkQueue[i] and pendingLinkQueue[i].linked then
      table.remove(pendingLinkQueue, i)
    end
  end

  DebugPendingLinkQueue("después de actualizar cache")

  -- Detect which auctions disappeared (cancelled/expired/sold)
  DetectCancelledAuctions(ownedAuctionsCache)
end

-- Get item info from location (after posting, item is gone from bag)
local function GetItemInfoFromLocation(location)
  if not location then
    Dukonomics.Logger.debug("GetItemInfoFromLocation: location es nil")
    return nil
  end

  -- Try to get itemID from the location object itself
  local itemID = C_Item.GetItemID(location)
  if not itemID then
    Dukonomics.Logger.debug("GetItemInfoFromLocation: C_Item.GetItemID retornó nil")
    return nil
  end

  -- Get basic item info
  local itemName, itemLink = C_Item.GetItemInfo(itemID)

  Dukonomics.Logger.debug("GetItemInfoFromLocation: itemID=" .. tostring(itemID) .. ", link=" .. tostring(itemLink))

  return itemID, itemLink, itemName
end

-- Hook into PostItem (for regular items)
local function OnPostItem(location, duration, quantity, bid, buyout)
  local itemID, itemLink, itemName = GetItemInfoFromLocation(location)
  if not itemID then return end

  local deposit = C_AuctionHouse.CalculateItemDeposit(location, duration, quantity)
  local timestamp = time()

  -- For PostItem, buyout and bid are usually TOTAL prices, so calculate unit price
  local rawPrice = buyout or bid or 0
  local unitPrice = rawPrice
  if quantity > 1 then
    unitPrice = math.floor(rawPrice / quantity)
  end
  local altUnitPrice = rawPrice
  local altTotalPrice = rawPrice * (quantity or 1)

  local postingSeq = NextPostingSequence()

  -- Create ONE posting for the entire stack
  local posting = {
    itemID = itemID,
    itemLink = itemLink,
    itemName = itemName,
    buyout = buyout,
    bid = bid,
    count = quantity,  -- Track the actual quantity posted
    deposit = deposit,
    duration = duration,
    price = unitPrice,  -- Store UNIT price for matching
    timestamp = timestamp,
    status = "active",
    postingSeq = postingSeq,
    totalPrice = rawPrice
  }

  Dukonomics.Data.AddPosting(posting)

  table.insert(pendingLinkQueue, {
    posting = posting,
    postingSeq = postingSeq,
    itemID = itemID,
    itemName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or "",
    quantity = quantity,
    unitPrice = unitPrice,
    totalPrice = rawPrice,
    altUnitPrice = altUnitPrice,
    altTotalPrice = altTotalPrice,
    timestamp = timestamp,
    linked = false
  })

  Dukonomics.Logger.debug("Posting en cola: seq=" .. tostring(postingSeq) ..
                   " itemID=" .. tostring(itemID) ..
                   " cant=" .. tostring(quantity) ..
                   " unit=" .. tostring(unitPrice) ..
                   " total=" .. tostring(rawPrice) ..
                   " (precios del posteo)")

  -- Request an update of owned auctions to link the auctionID
  -- Use a small delay to ensure the auction is created
  C_Timer.After(0.5, function()
    C_AuctionHouse.QueryOwnedAuctions({})
  end)
end

-- Hook into PostCommodity (for stackable commodities)
local function OnPostCommodity(location, duration, quantity, unitPrice)
  local itemID, itemLink, itemName = GetItemInfoFromLocation(location)
  if not itemID then return end

  local deposit = C_AuctionHouse.CalculateCommodityDeposit(itemID, duration, quantity)
  local timestamp = time()

  local postingSeq = NextPostingSequence()

  local rawPrice = unitPrice or 0
  local altUnitPrice = quantity > 1 and math.floor(rawPrice / quantity) or rawPrice
  local altTotalPrice = rawPrice * (quantity or 1)

  -- Create ONE posting for the entire stack
  local posting = {
    itemID = itemID,
    itemLink = itemLink,
    itemName = itemName,
    buyout = unitPrice,
    bid = nil,
    count = quantity,  -- Track the actual quantity posted
    deposit = deposit,
    duration = duration,
    price = unitPrice,
    timestamp = timestamp,
    status = "active",
    postingSeq = postingSeq,
    totalPrice = rawPrice
  }

  Dukonomics.Data.AddPosting(posting)

  table.insert(pendingLinkQueue, {
    posting = posting,
    postingSeq = postingSeq,
    itemID = itemID,
    itemName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or "",
    quantity = quantity,
    unitPrice = unitPrice,
    totalPrice = rawPrice,
    altUnitPrice = altUnitPrice,
    altTotalPrice = altTotalPrice,
    timestamp = timestamp,
    linked = false
  })

  Dukonomics.Logger.debug("Posting en cola: seq=" .. tostring(postingSeq) ..
                   " itemID=" .. tostring(itemID) ..
                   " cant=" .. tostring(quantity) ..
                   " unit=" .. tostring(unitPrice) ..
                   " total=" .. tostring(rawPrice) ..
                   " (precios del posteo)")

  -- Request an update of owned auctions to link the auctionID
  C_Timer.After(0.5, function()
    C_AuctionHouse.QueryOwnedAuctions({})
  end)
end

function Dukonomics.Events.Initialize()
  Dukonomics.Logger.debug("Initializing posting event handlers")

  -- Register hooks for posting
  hooksecurefunc(C_AuctionHouse, "PostItem", OnPostItem)
  hooksecurefunc(C_AuctionHouse, "PostCommodity", OnPostCommodity)

  -- Hook CancelAuction to capture the auctionID BEFORE it's removed
  -- We only need the auctionID parameter, not the auction info
  hooksecurefunc(C_AuctionHouse, "CancelAuction", OnCancelAuction)

  -- Create event frame for auction house events
  local eventFrame = CreateFrame("Frame")
  eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
  eventFrame:RegisterEvent("OWNED_AUCTIONS_UPDATED")

  eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "AUCTION_HOUSE_SHOW" then
      OnAuctionHouseShow()
    elseif event == "OWNED_AUCTIONS_UPDATED" then
      OnOwnedAuctionsUpdated()
    end
  end)

  Dukonomics.Logger.debug("Posting event handlers registered")
end
