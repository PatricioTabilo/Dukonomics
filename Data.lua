-- Dukonomics: Data persistence and storage

Dukonomics.Data = {}

local refreshPending = false

local function ScheduleUIRefresh()
  if not (Dukonomics and Dukonomics.UI and Dukonomics.UI.Refresh) then
    return
  end

  if refreshPending then
    return
  end

  refreshPending = true
  C_Timer.After(0.1, function()
    refreshPending = false
    Dukonomics.UI.Refresh()
  end)
end

-- Get current player info
local function GetPlayerSource()
  return {
    character = UnitName("player"),
    realm = GetRealmName(),
    faction = UnitFactionGroup("player")
  }
end

-- Initialize saved variables
function Dukonomics.Data.Initialize()
  -- Create default structure if doesn't exist
  if not DUKONOMICS_DATA then
    DUKONOMICS_DATA = {
      postings = {},
      purchases = {},
      config = {
        debug = true
      }
    }
    Dukonomics.Logger.debug("Created new DUKONOMICS_DATA")
  else
    Dukonomics.Logger.debug("Loaded existing DUKONOMICS_DATA with " .. #DUKONOMICS_DATA.postings .. " postings")
  end
end

-- Add posting to logs
function Dukonomics.Data.AddPosting(posting)
  posting.source = GetPlayerSource()
  table.insert(DUKONOMICS_DATA.postings, posting)
  Dukonomics.Logger.debug("Posting saved: " .. (posting.itemName or "?") .. " x" .. posting.count)
  ScheduleUIRefresh()
end

-- Add purchase to logs
function Dukonomics.Data.AddPurchase(purchase)
  purchase.source = GetPlayerSource()
  table.insert(DUKONOMICS_DATA.purchases, purchase)
  Dukonomics.Logger.debug("Purchase saved: " .. (purchase.itemName or "?") .. " x" .. purchase.count)
  ScheduleUIRefresh()
end

-- Find active posting by item/price/count (for mail matching of sales)
function Dukonomics.Data.FindActivePosting(itemName, price, count)
  for _, posting in ipairs(DUKONOMICS_DATA.postings) do
    if posting.status == "active" and
       posting.itemName == itemName and
       posting.price == price and
       posting.count == count then
      return posting
    end
  end
  return nil
end

-- Find posting for returned items (cancelled/expired) - only active
function Dukonomics.Data.FindActivePostingByItem(itemName, count)
  for _, posting in ipairs(DUKONOMICS_DATA.postings) do
    if posting.status == "active" and
       posting.itemName == itemName and
       posting.count == count then
      return posting
    end
  end
  return nil
end

-- Find active posting by auctionID (exact match)
function Dukonomics.Data.FindPostingByAuctionID(auctionID)
  if not auctionID or not DUKONOMICS_DATA or not DUKONOMICS_DATA.postings then
    return nil
  end

  for _, posting in ipairs(DUKONOMICS_DATA.postings) do
    if posting.auctionID == auctionID and posting.status == "active" then
      Dukonomics.Logger.debug("FindPostingByAuctionID: FOUND posting for auctionID " .. auctionID)
      return posting
    end
  end

  Dukonomics.Logger.debug("FindPostingByAuctionID: NOT FOUND for auctionID " .. auctionID)
  return nil
end

-- Find active posting that has at least 'minCount' items
-- If price is provided, match it exactly; otherwise match by item name only (FIFO - oldest first)
function Dukonomics.Data.FindActivePostingWithQuantity(itemName, price, minCount)
  -- Normalize the search name (trim whitespace, lowercase)
  local searchName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or ""

  Dukonomics.Logger.debug("FindActivePosting: searching for '" .. searchName .. "' with minCount=" .. tostring(minCount) .. ", price=" .. tostring(price))

  for i, posting in ipairs(DUKONOMICS_DATA.postings) do
    -- Normalize posting name for comparison
    local postingName = posting.itemName and posting.itemName:match("^%s*(.-)%s*$"):lower() or ""

    local nameMatch = postingName == searchName
    local statusMatch = posting.status == "active"
    local countMatch = (posting.count or 0) >= (minCount or 1)
    local priceMatch = (price == nil or posting.price == price)

    if statusMatch and nameMatch and countMatch and priceMatch then
      Dukonomics.Logger.debug("  FOUND at index " .. i .. ": '" .. posting.itemName .. "' count=" .. posting.count)
      return posting
    end
  end

  -- Debug: show what we have
  Dukonomics.Logger.debug("  NOT FOUND. Active postings:")
  for i, posting in ipairs(DUKONOMICS_DATA.postings) do
    if posting.status == "active" then
      local postingName = posting.itemName and posting.itemName:match("^%s*(.-)%s*$"):lower() or ""
      Dukonomics.Logger.debug("    [" .. i .. "] '" .. postingName .. "' (original: '" .. tostring(posting.itemName) .. "') count=" .. tostring(posting.count))
    end
  end

  return nil
end

function Dukonomics.Data.FindActivePostingWithTotalPrice(itemName, totalPrice, minCount)
  -- Normalize the search name (trim whitespace, lowercase)
  local searchName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or ""

  Dukonomics.Logger.debug("FindActivePostingWithTotalPrice: searching for '" .. searchName .. "' with minCount=" .. tostring(minCount) .. ", totalPrice=" .. tostring(totalPrice))

  for i, posting in ipairs(DUKONOMICS_DATA.postings) do
    -- Normalize posting name for comparison
    local postingName = posting.itemName and posting.itemName:match("^%s*(.-)%s*$"):lower() or ""

    local nameMatch = postingName == searchName
    local statusMatch = posting.status == "active"
    local countMatch = (posting.count or 0) >= (minCount or 1)
    local totalPriceMatch = (totalPrice == nil or posting.totalPrice == totalPrice)

    if statusMatch and nameMatch and countMatch and totalPriceMatch then
      Dukonomics.Logger.debug("  FOUND at index " .. i .. ": '" .. posting.itemName .. "' count=" .. posting.count .. " totalPrice=" .. tostring(posting.totalPrice))
      return posting
    end
  end

  -- Debug: show what we have
  Dukonomics.Logger.debug("  NOT FOUND. Active postings:")
  for i, posting in ipairs(DUKONOMICS_DATA.postings) do
    if posting.status == "active" then
      local postingName = posting.itemName and posting.itemName:match("^%s*(.-)%s*$"):lower() or ""
      Dukonomics.Logger.debug("    [" .. i .. "] '" .. postingName .. "' (original: '" .. tostring(posting.itemName) .. "') count=" .. tostring(posting.count) .. " totalPrice=" .. tostring(posting.totalPrice))
    end
  end

  return nil
end

function Dukonomics.Data.FindNewestActivePostingWithQuantity(itemName, minCount)
  -- Normalize the search name (trim whitespace, lowercase)
  local searchName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or ""

  Dukonomics.Logger.debug("FindNewestActivePostingWithQuantity: searching for '" .. searchName .. "' with minCount=" .. tostring(minCount))

  local newestPosting = nil
  local newestTimestamp = 0  -- Start with minimum possible timestamp

  for i, posting in ipairs(DUKONOMICS_DATA.postings) do
    -- Normalize posting name for comparison
    local postingName = posting.itemName and posting.itemName:match("^%s*(.-)%s*$"):lower() or ""

    local nameMatch = postingName == searchName
    local statusMatch = posting.status == "active"
    local countMatch = (posting.count or 0) >= (minCount or 1)
    local timestamp = posting.timestamp or 0

    if statusMatch and nameMatch and countMatch and timestamp > newestTimestamp then
      newestPosting = posting
      newestTimestamp = timestamp
      Dukonomics.Logger.debug("  Found candidate at index " .. i .. ": '" .. posting.itemName .. "' count=" .. posting.count .. " timestamp=" .. timestamp)
    end
  end

  if newestPosting then
    Dukonomics.Logger.debug("  NEWEST FOUND: '" .. newestPosting.itemName .. "' count=" .. newestPosting.count .. " timestamp=" .. newestTimestamp)
  else
    Dukonomics.Logger.debug("  NOT FOUND. Active postings with sufficient quantity:")
    for i, posting in ipairs(DUKONOMICS_DATA.postings) do
      if posting.status == "active" then
        local postingName = posting.itemName and posting.itemName:match("^%s*(.-)%s*$"):lower() or ""
        local countMatch = (posting.count or 0) >= (minCount or 1)
        if postingName == searchName and countMatch then
          Dukonomics.Logger.debug("    [" .. i .. "] '" .. postingName .. "' count=" .. tostring(posting.count) .. " timestamp=" .. tostring(posting.timestamp))
        end
      end
    end
  end

  return newestPosting
end

function Dukonomics.Data.FindActivePostingsWithTotalPrice(itemName, totalPrice)
  -- Normalize the search name (trim whitespace, lowercase)
  local searchName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or ""

  Dukonomics.Logger.debug("FindActivePostingsWithTotalPrice: searching for '" .. searchName .. "' with totalPrice=" .. tostring(totalPrice))

  local matchingPostings = {}

  for i, posting in ipairs(DUKONOMICS_DATA.postings) do
    -- Normalize posting name for comparison
    local postingName = posting.itemName and posting.itemName:match("^%s*(.-)%s*$"):lower() or ""

    local nameMatch = postingName == searchName
    local statusMatch = posting.status == "active"
    local totalPriceMatch = (totalPrice == nil or posting.totalPrice == totalPrice)

    if statusMatch and nameMatch and totalPriceMatch then
      table.insert(matchingPostings, posting)
      Dukonomics.Logger.debug("  Found matching posting at index " .. i .. ": count=" .. posting.count .. " totalPrice=" .. tostring(posting.totalPrice))
    end
  end

  Dukonomics.Logger.debug("  Found " .. #matchingPostings .. " matching postings")
  return matchingPostings
end

function Dukonomics.Data.FindActivePostingsWithQuantity(itemName, minCount)
  -- Normalize the search name (trim whitespace, lowercase)
  local searchName = itemName and itemName:match("^%s*(.-)%s*$"):lower() or ""

  Dukonomics.Logger.debug("FindActivePostingsWithQuantity: searching for '" .. searchName .. "' with minCount=" .. tostring(minCount))

  local matchingPostings = {}

  for i, posting in ipairs(DUKONOMICS_DATA.postings) do
    -- Normalize posting name for comparison
    local postingName = posting.itemName and posting.itemName:match("^%s*(.-)%s*$"):lower() or ""

    local nameMatch = postingName == searchName
    local statusMatch = posting.status == "active"
    local countMatch = (posting.count or 0) >= (minCount or 1)

    if statusMatch and nameMatch and countMatch then
      table.insert(matchingPostings, posting)
      Dukonomics.Logger.debug("  Found matching posting at index " .. i .. ": count=" .. posting.count)
    end
  end

  Dukonomics.Logger.debug("  Found " .. #matchingPostings .. " matching postings")
  return matchingPostings
end

-- Reduce quantity from an active posting (for partial sales/cancellations)
-- Returns true if posting was fully consumed (count reached 0)
function Dukonomics.Data.ReducePostingQuantity(posting, quantity, newStatus)
  if not posting or quantity <= 0 then
    return false
  end

  local remaining = posting.count - quantity

  if remaining <= 0 then
    -- Full stack consumed
    posting.status = newStatus
    posting[newStatus .. "At"] = time()
    posting.pendingRemoval = nil
    posting.pendingRemovalType = nil
    posting.pendingRemovalQuantity = nil
    posting.cancelledByEvent = nil

    -- Calculate profit if sold
    if newStatus == "sold" then
      posting.soldPrice = posting.price
      posting.profit = (posting.price * quantity) - posting.deposit
    end

    Dukonomics.Logger.debug("Posting fully " .. newStatus .. ": " .. posting.itemName .. " (was " .. posting.count .. ")")
    ScheduleUIRefresh()
    return true
  else
    -- Partial consumption - split the posting
    -- Keep original as active with reduced count
    posting.count = remaining

    -- Adjust deposit proportionally
    local consumedDeposit = math.floor(posting.deposit * quantity / (quantity + remaining))
    posting.deposit = posting.deposit - consumedDeposit

    -- Create new entry for the consumed portion
    local consumed = {
      itemID = posting.itemID,
      itemLink = posting.itemLink,
      itemName = posting.itemName,
      buyout = posting.buyout,
      bid = posting.bid,
      count = quantity,
      deposit = consumedDeposit,
      duration = posting.duration,
      price = posting.price,
      timestamp = posting.timestamp,
      source = posting.source,
      status = newStatus
    }
    consumed[newStatus .. "At"] = time()

    -- Calculate profit if sold
    if newStatus == "sold" then
      consumed.soldPrice = consumed.price
      consumed.profit = (consumed.price * quantity) - consumed.deposit
    end

    table.insert(DUKONOMICS_DATA.postings, consumed)

    Dukonomics.Logger.debug("Posting partially " .. newStatus .. ": " .. posting.itemName .. " x" .. quantity .. " (remaining: " .. remaining .. ")")
    ScheduleUIRefresh()
    return false
  end
end

-- Mark posting as sold (by synthetic ID or auctionID)
function Dukonomics.Data.MarkPostingAsSold(posting, soldPrice)
  posting.status = "sold"
  posting.soldAt = time()
  posting.soldPrice = soldPrice or posting.price

  -- Calculate profit
  local revenue = posting.soldPrice
  local cost = posting.deposit
  posting.profit = revenue - cost

  Dukonomics.Logger.debug("Marked as sold: " .. (posting.itemName or "?") .. " - Profit: " .. posting.profit .. "g")
  ScheduleUIRefresh()
  return true
end

-- Get postings within time range
function Dukonomics.Data.GetPostings(timeFrom, timeTo, filters)
  local results = {}
  local now = time()

  for _, posting in ipairs(DUKONOMICS_DATA.postings) do
    local timestamp = posting.timestamp or 0

    -- Time range filter
    if timestamp >= (timeFrom or 0) and timestamp <= (timeTo or now) then
      -- Apply additional filters if provided
      local include = true

      if filters then
        if filters.status and posting.status ~= filters.status then
          include = false
        end

        if filters.character and posting.source.character ~= filters.character then
          include = false
        end
      end

      if include then
        table.insert(results, posting)
      end
    end
  end

  return results
end

-- Get all unique characters with realm
function Dukonomics.Data.GetCharacters()
  local chars = {}
  local seen = {}

  -- Add characters from postings
  if DUKONOMICS_DATA.postings then
    for _, posting in ipairs(DUKONOMICS_DATA.postings) do
      if posting.source and posting.source.character and posting.source.realm then
        local key = posting.source.character .. "-" .. posting.source.realm
        if not seen[key] then
          seen[key] = true
          table.insert(chars, {
            character = posting.source.character,
            realm = posting.source.realm,
            key = key
          })
        end
      end
    end
  end

  -- Add characters from purchases
  if DUKONOMICS_DATA.purchases then
    for _, purchase in ipairs(DUKONOMICS_DATA.purchases) do
      if purchase.source and purchase.source.character and purchase.source.realm then
        local key = purchase.source.character .. "-" .. purchase.source.realm
        if not seen[key] then
          seen[key] = true
          table.insert(chars, {
            character = purchase.source.character,
            realm = purchase.source.realm,
            key = key
          })
        end
      end
    end
  end

  -- Sort by character name
  table.sort(chars, function(a, b)
    return a.character < b.character
  end)

  return chars
end

-- Clear old data
function Dukonomics.Data.ClearOldData(daysToKeep)
  if not DUKONOMICS_DATA then
    Dukonomics.Print("No hay datos para limpiar")
    return
  end

  local cutoff = time() - (daysToKeep * 24 * 60 * 60)
  local removedPostings = 0
  local removedPurchases = 0
  local totalPostings = DUKONOMICS_DATA.postings and #DUKONOMICS_DATA.postings or 0
  local totalPurchases = DUKONOMICS_DATA.purchases and #DUKONOMICS_DATA.purchases or 0

  Dukonomics.Logger.debug("Limpiando datos anteriores a " .. date("%Y-%m-%d %H:%M:%S", cutoff))

  -- Clear old postings
  if DUKONOMICS_DATA.postings then
    for i = #DUKONOMICS_DATA.postings, 1, -1 do
      local posting = DUKONOMICS_DATA.postings[i]
      if posting.timestamp and posting.timestamp < cutoff then
        Dukonomics.Logger.debug("Eliminando posting: " .. (posting.itemName or "?") .. " del " .. date("%Y-%m-%d", posting.timestamp))
        table.remove(DUKONOMICS_DATA.postings, i)
        removedPostings = removedPostings + 1
      end
    end
  end

  -- Clear old purchases
  if DUKONOMICS_DATA.purchases then
    for i = #DUKONOMICS_DATA.purchases, 1, -1 do
      local purchase = DUKONOMICS_DATA.purchases[i]
      if purchase.timestamp and purchase.timestamp < cutoff then
        Dukonomics.Logger.debug("Eliminando purchase: " .. (purchase.itemName or "?") .. " del " .. date("%Y-%m-%d", purchase.timestamp))
        table.remove(DUKONOMICS_DATA.purchases, i)
        removedPurchases = removedPurchases + 1
      end
    end
  end

  -- Report results
  if removedPostings > 0 or removedPurchases > 0 then
    local msg = "Eliminados "
    if removedPostings > 0 then
      msg = msg .. removedPostings .. " de " .. totalPostings .. " postings"
    end
    if removedPurchases > 0 then
      if removedPostings > 0 then
        msg = msg .. " y "
      end
      msg = msg .. removedPurchases .. " de " .. totalPurchases .. " compras"
    end
    msg = msg .. " (más antiguos que " .. daysToKeep .. " días)"
    Dukonomics.Print(msg)
  else
    Dukonomics.Print("No se encontraron datos más antiguos que " .. daysToKeep .. " días")
  end

  ScheduleUIRefresh()
end
