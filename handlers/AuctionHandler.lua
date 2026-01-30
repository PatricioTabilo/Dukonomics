-- Auction House event handling: tracks postings, cancellations, and maintains auction cache

Dukonomics.AuctionHandler = {}

local ownedAuctionsCache = {}
local previousAuctionsCache = {}
local pendingLinkQueue = {}
local recentlyRemovedAuctions = {}
local lastCancelledAuctionID = nil
local postingSequence = 0

-- =============================================================================
-- UTILITIES
-- =============================================================================

local function NextPostingSequence()
  postingSequence = postingSequence + 1
  return postingSequence
end

local function NormalizeName(name)
  return name and name:match("^%s*(.-)%s*$"):lower() or ""
end

local function PriceMatchesPending(pending, cacheUnitPrice, cacheTotalPrice)
  if not pending then return false end
  local candidates = { pending.unitPrice, pending.totalPrice, pending.altUnitPrice, pending.altTotalPrice }
  for _, price in ipairs(candidates) do
    if price and (price == cacheUnitPrice or price == cacheTotalPrice) then
      return true
    end
  end
  return false
end

local function PriceMatchesPosting(posting, cacheUnitPrice, cacheTotalPrice, quantity)
  if not posting or not posting.price then return false end
  local candidates = { posting.price, posting.totalPrice }
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
  if not auctionInfo then return 0, 0 end

  local quantity = auctionInfo.quantity or 1
  local rawPrice = auctionInfo.buyoutAmount or auctionInfo.bidAmount or 0
  local itemID = auctionInfo.itemID or (auctionInfo.itemKey and auctionInfo.itemKey.itemID)

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

  return quantity > 0 and math.floor(rawPrice / quantity) or rawPrice, rawPrice
end

local function IsAuctionIDLinked(auctionID)
  local data = Dukonomics.Data.GetDataStore()
  if not auctionID or not data or not data.postings then return false end
  for _, posting in ipairs(data.postings) do
    if posting.auctionID == auctionID then return true end
  end
  return false
end

local function GetItemInfoFromLocation(location)
  if not location then return nil end
  local itemID = C_Item.GetItemID(location)
  if not itemID then return nil end
  local itemName, itemLink = C_Item.GetItemInfo(itemID)
  return itemID, itemLink, itemName
end

-- =============================================================================
-- AUCTION ID LINKING
-- =============================================================================

local function LinkAuctionToPosting(auctionID, auctionInfo)
  if not auctionInfo then return end
  if IsAuctionIDLinked(auctionID) then return true end

  local itemID = auctionInfo.itemKey and auctionInfo.itemKey.itemID
  local itemName = itemID and C_Item.GetItemInfo(itemID)
  local quantity = auctionInfo.quantity or 1
  local unitPrice, totalPrice = InferPricesForAuction(auctionInfo)
  local searchName = NormalizeName(itemName)

  if not itemID and searchName == "" then return end

  -- Try pending queue first (newest first)
  for i = #pendingLinkQueue, 1, -1 do
    local pending = pendingLinkQueue[i]
    if pending and not pending.linked and
       ((pending.itemID and itemID and pending.itemID == itemID) or (pending.itemName == searchName and searchName ~= "")) and
       pending.quantity == quantity and
       PriceMatchesPending(pending, unitPrice, totalPrice) then
      local posting = pending.posting
      if posting and posting.status == "active" and not posting.auctionID then
        posting.auctionID = auctionID
        posting.linkedByAuctionID = true
        pending.linked = true
        Dukonomics.Logger.debug("  ✅ Linked auctionID " .. auctionID .. " to pending posting")
        return true
      end
    end
  end

  -- Fallback: search postings (newest first)
  local data = Dukonomics.Data.GetDataStore()
  if data and data.postings then
    for i = #data.postings, 1, -1 do
      local posting = data.postings[i]
      if posting.status == "active" and not posting.auctionID and
         ((posting.itemID and itemID and posting.itemID == itemID) or
          (posting.itemName and NormalizeName(posting.itemName) == searchName and searchName ~= "")) and
         posting.count == quantity and
         PriceMatchesPosting(posting, unitPrice, totalPrice, quantity) then
        posting.auctionID = auctionID
        posting.linkedByAuctionID = true
        Dukonomics.Logger.debug("  ✅ Linked auctionID " .. auctionID .. " to posting [" .. i .. "]")
        return true
      end
    end
  end

  return false
end

-- =============================================================================
-- CANCELLATION HANDLING
-- =============================================================================

local function ApplyImmediateCancellation(posting, cancelQuantity)
  if not posting or not cancelQuantity or cancelQuantity <= 0 then return false end

  posting.pendingRemoval = nil
  posting.pendingRemovalType = nil
  posting.pendingRemovalQuantity = nil
  posting.cancelledByEvent = true
  Dukonomics.Data.ReducePostingQuantity(posting, cancelQuantity, "cancelled")
  lastCancelledAuctionID = nil
  return true
end

local function DetectCancelledAuctions(newCache)
  recentlyRemovedAuctions = {}

  for auctionID, oldInfo in pairs(previousAuctionsCache) do
    if not newCache[auctionID] then
      Dukonomics.Logger.debug("Auction " .. auctionID .. " disappeared from owned list")
      recentlyRemovedAuctions[auctionID] = oldInfo

      local data = Dukonomics.Data.GetDataStore()
      if data and data.postings then
        for _, posting in ipairs(data.postings) do
          if posting.auctionID == auctionID and posting.status == "active" then
            if lastCancelledAuctionID and auctionID == lastCancelledAuctionID then
              local qty = posting.pendingRemovalQuantity or oldInfo.quantity or posting.count or 1
              posting.cancelledByEvent = true
              Dukonomics.Data.ReducePostingQuantity(posting, qty, "cancelled")
              lastCancelledAuctionID = nil
            else
              posting.pendingRemoval = true
              posting.pendingRemovalType = "unknown"
            end
            break
          end
        end
      end
    end
  end
end

local function OnCancelAuction(auctionID)
  Dukonomics.Logger.debug("🚫 CancelAuction: auctionID = " .. tostring(auctionID))
  lastCancelledAuctionID = auctionID

  local auctionInfo = ownedAuctionsCache[auctionID]
  local found = false

  local data = Dukonomics.Data.GetDataStore()
  if auctionID and data and data.postings then
    -- Try by auctionID first
    for _, posting in ipairs(data.postings) do
      if posting.auctionID == auctionID and posting.status == "active" then
        local qty = auctionInfo and auctionInfo.quantity or posting.count
        ApplyImmediateCancellation(posting, qty)
        found = true
        break
      end
    end

    -- Try linking if not found
    if not found and auctionInfo then
      local itemName = auctionInfo.itemName
      local itemID = auctionInfo.itemID
      local quantity = auctionInfo.quantity
      local unitPrice = auctionInfo.unitPrice
      local totalPrice = auctionInfo.totalPrice
      local searchName = NormalizeName(itemName)

      -- Try pending queue
      for i = #pendingLinkQueue, 1, -1 do
        local pending = pendingLinkQueue[i]
        if pending and not pending.linked and
           ((pending.itemID and itemID and pending.itemID == itemID) or (pending.itemName == searchName)) and
           pending.quantity == quantity and
           PriceMatchesPending(pending, unitPrice, totalPrice) then
          local posting = pending.posting
          if posting and posting.status == "active" and not posting.auctionID then
            posting.auctionID = auctionID
            posting.linkedByAuctionID = true
            pending.linked = true
            ApplyImmediateCancellation(posting, quantity)
            found = true
            break
          end
        end
      end

      -- Fallback: search postings
      if not found then
        for i = #data.postings, 1, -1 do
          local posting = data.postings[i]
          if posting.status == "active" and not posting.auctionID and
             ((posting.itemID and itemID and posting.itemID == itemID) or
              (posting.itemName and NormalizeName(posting.itemName) == searchName)) and
             posting.count == quantity and
             PriceMatchesPosting(posting, unitPrice, totalPrice, quantity) then
            posting.auctionID = auctionID
            posting.linkedByAuctionID = true
            ApplyImmediateCancellation(posting, quantity)
            found = true
            break
          end
        end
      end
    end
  end

  if not found then
    Dukonomics.Logger.debug("  ❌ No posting found for auctionID " .. tostring(auctionID))
  end
end

-- =============================================================================
-- EVENT HANDLERS
-- =============================================================================

local function OnOwnedAuctionsUpdated()
  Dukonomics.Logger.debug("Refreshing auction cache...")

  previousAuctionsCache = ownedAuctionsCache
  ownedAuctionsCache = {}

  local numAuctions = C_AuctionHouse.GetNumOwnedAuctions()

  for i = 1, numAuctions do
    local auctionInfo = C_AuctionHouse.GetOwnedAuctionInfo(i)
    if auctionInfo and auctionInfo.auctionID then
      local auctionID = auctionInfo.auctionID
      local itemID = auctionInfo.itemKey and auctionInfo.itemKey.itemID
      local itemName = itemID and C_Item.GetItemInfo(itemID)
      local quantity = auctionInfo.quantity or 1
      local unitPrice, totalPrice = InferPricesForAuction(auctionInfo)

      ownedAuctionsCache[auctionID] = {
        itemID = itemID,
        itemName = itemName,
        quantity = quantity,
        buyoutAmount = auctionInfo.buyoutAmount,
        bidAmount = auctionInfo.bidAmount,
        unitPrice = unitPrice,
        totalPrice = totalPrice,
        timeLeft = auctionInfo.timeLeft,
        status = auctionInfo.status
      }

      LinkAuctionToPosting(auctionID, auctionInfo)
    end
  end

  -- Clean linked pending entries
  for i = #pendingLinkQueue, 1, -1 do
    if pendingLinkQueue[i] and pendingLinkQueue[i].linked then
      table.remove(pendingLinkQueue, i)
    end
  end

  DetectCancelledAuctions(ownedAuctionsCache)
end

local function OnPostItem(location, duration, quantity, bid, buyout)
  local itemID, itemLink, itemName = GetItemInfoFromLocation(location)
  if not itemID then return end

  local deposit = C_AuctionHouse.CalculateItemDeposit(location, duration, quantity)
  local rawPrice = buyout or bid or 0
  local unitPrice = quantity > 1 and math.floor(rawPrice / quantity) or rawPrice
  local postingSeq = NextPostingSequence()

  local posting = {
    itemID = itemID,
    itemLink = itemLink,
    itemName = itemName,
    buyout = buyout,
    bid = bid,
    count = quantity,
    deposit = deposit,
    duration = duration,
    price = unitPrice,
    timestamp = time(),
    status = "active",
    postingSeq = postingSeq,
    totalPrice = rawPrice
  }

  Dukonomics.Data.AddPosting(posting)

  table.insert(pendingLinkQueue, {
    posting = posting,
    postingSeq = postingSeq,
    itemID = itemID,
    itemName = NormalizeName(itemName),
    quantity = quantity,
    unitPrice = unitPrice,
    totalPrice = rawPrice,
    altUnitPrice = rawPrice,
    altTotalPrice = rawPrice * quantity,
    timestamp = time(),
    linked = false
  })

  C_Timer.After(0.5, function() C_AuctionHouse.QueryOwnedAuctions({}) end)
end

local function OnPostCommodity(location, duration, quantity, unitPrice)
  local itemID, itemLink, itemName = GetItemInfoFromLocation(location)
  if not itemID then return end

  local deposit = C_AuctionHouse.CalculateCommodityDeposit(itemID, duration, quantity)
  local rawPrice = unitPrice or 0
  local postingSeq = NextPostingSequence()

  local posting = {
    itemID = itemID,
    itemLink = itemLink,
    itemName = itemName,
    buyout = unitPrice,
    bid = nil,
    count = quantity,
    deposit = deposit,
    duration = duration,
    price = unitPrice,
    timestamp = time(),
    status = "active",
    postingSeq = postingSeq,
    totalPrice = rawPrice
  }

  Dukonomics.Data.AddPosting(posting)

  table.insert(pendingLinkQueue, {
    posting = posting,
    postingSeq = postingSeq,
    itemID = itemID,
    itemName = NormalizeName(itemName),
    quantity = quantity,
    unitPrice = unitPrice,
    totalPrice = rawPrice,
    altUnitPrice = quantity > 1 and math.floor(rawPrice / quantity) or rawPrice,
    altTotalPrice = rawPrice * quantity,
    timestamp = time(),
    linked = false
  })

  C_Timer.After(0.5, function() C_AuctionHouse.QueryOwnedAuctions({}) end)
end

-- =============================================================================
-- PUBLIC API
-- =============================================================================

function Dukonomics.AuctionHandler.GetRemovedAuctionByItem(itemName, quantity)
  local searchName = NormalizeName(itemName)
  for auctionID, info in pairs(recentlyRemovedAuctions) do
    if NormalizeName(info.itemName) == searchName and info.quantity == quantity then
      return auctionID, info
    end
  end
  return nil, nil
end

function Dukonomics.AuctionHandler.GetLastCancelledAuctionID()
  return lastCancelledAuctionID
end

function Dukonomics.AuctionHandler.FindPendingRemovalPosting(itemName, quantity)
  local data = Dukonomics.Data.GetDataStore()
  if not data or not data.postings then return nil end
  local searchName = NormalizeName(itemName)

  for _, posting in ipairs(data.postings) do
    if posting.pendingRemoval and
       posting.status == "active" and
       NormalizeName(posting.itemName) == searchName and
       posting.count == quantity then
      return posting
    end
  end
  return nil
end

function Dukonomics.AuctionHandler.IsAuctionActive(auctionID)
  if not auctionID then return false end
  if ownedAuctionsCache[auctionID] then return true end
  if Dukonomics._testActiveAuctions and Dukonomics._testActiveAuctions[auctionID] then return true end
  return false
end

function Dukonomics.AuctionHandler.GetActiveAuctionInfo(auctionID)
  if not auctionID then return nil end
  if ownedAuctionsCache[auctionID] then return ownedAuctionsCache[auctionID] end
  if Dukonomics._testActiveAuctions then return Dukonomics._testActiveAuctions[auctionID] end
  return nil
end

function Dukonomics.AuctionHandler.IsPostingStillInAH(posting)
  if not posting then return false end
  if not posting.auctionID then return nil end

  local isActive = ownedAuctionsCache[posting.auctionID] ~= nil
  if not isActive and Dukonomics._testActiveAuctions then
    isActive = Dukonomics._testActiveAuctions[posting.auctionID] ~= nil
  end

  if isActive then
    Dukonomics.Logger.debug("IsPostingStillInAH: " .. posting.auctionID .. " IS ACTIVE")
  end

  return isActive
end

function Dukonomics.AuctionHandler.GetAuctionQuantityInAH(posting)
  if not posting or not posting.auctionID then return nil end
  local info = ownedAuctionsCache[posting.auctionID]
  return info and info.quantity or 0
end

function Dukonomics.AuctionHandler.RefreshOwnedAuctions()
  if C_AuctionHouse and C_AuctionHouse.QueryOwnedAuctions then
    C_AuctionHouse.QueryOwnedAuctions({})
  end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function Dukonomics.AuctionHandler.Initialize()
  Dukonomics.Logger.debug("Initializing AuctionHandler")

  hooksecurefunc(C_AuctionHouse, "PostItem", OnPostItem)
  hooksecurefunc(C_AuctionHouse, "PostCommodity", OnPostCommodity)
  hooksecurefunc(C_AuctionHouse, "CancelAuction", OnCancelAuction)

  local eventFrame = CreateFrame("Frame")
  eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")
  eventFrame:RegisterEvent("OWNED_AUCTIONS_UPDATED")

  eventFrame:SetScript("OnEvent", function(self, event)
    if event == "OWNED_AUCTIONS_UPDATED" then
      OnOwnedAuctionsUpdated()
    end
  end)

  Dukonomics.Logger.debug("AuctionHandler initialized")
end

-- Backward compatibility alias
Dukonomics.Events = Dukonomics.AuctionHandler
