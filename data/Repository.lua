Dukonomics.Data = {}

local refreshPending = false

local function ScheduleUIRefresh()
  if not (Dukonomics.UI and Dukonomics.UI.Refresh) then return end
  if refreshPending then return end

  refreshPending = true
  C_Timer.After(0.1, function()
    refreshPending = false
    Dukonomics.UI.Refresh()
  end)
end

local function GetPlayerSource()
  return {
    character = UnitName("player"),
    realm = GetRealmName(),
    faction = UnitFactionGroup("player")
  }
end

local function GetDataStore()
  if Dukonomics.DebugMode then
    return DUKONOMICS_DEBUG_DATA
  else
    return DUKONOMICS_DATA
  end
end

-- Public function for other modules to access the current data store
function Dukonomics.Data.GetDataStore()
  return GetDataStore()
end

function Dukonomics.Data.Initialize()
  -- Initialize global config
  if not DUKONOMICS_CONFIG then
    DUKONOMICS_CONFIG = {
      debugMode = false
    }
  end

  -- Initialize production data
  if not DUKONOMICS_DATA then
    DUKONOMICS_DATA = {
      postings = {},
      purchases = {},
      config = { debug = false }
    }
    Dukonomics.Logger.debug("Created new DUKONOMICS_DATA")
  else
    Dukonomics.Logger.debug("Loaded existing DUKONOMICS_DATA with " .. #DUKONOMICS_DATA.postings .. " postings")
  end

  -- Initialize debug data
  if not DUKONOMICS_DEBUG_DATA then
    DUKONOMICS_DEBUG_DATA = {
      postings = {},
      purchases = {},
      config = { debug = true }
    }
    Dukonomics.Logger.debug("Created new DUKONOMICS_DEBUG_DATA")
  else
    Dukonomics.Logger.debug("Loaded existing DUKONOMICS_DEBUG_DATA with " .. #DUKONOMICS_DEBUG_DATA.postings .. " postings")
  end
end

-- =============================================================================
-- POSTING OPERATIONS
-- =============================================================================

function Dukonomics.Data.AddPosting(posting)
  posting.source = GetPlayerSource()
  local data = GetDataStore()
  table.insert(data.postings, posting)
  Dukonomics.Logger.debug("Posting saved: " .. (posting.itemName or "?") .. " x" .. posting.count)
  ScheduleUIRefresh()
end

function Dukonomics.Data.FindActivePosting(itemName, price, count)
  local data = GetDataStore()
  for _, posting in ipairs(data.postings) do
    if posting.status == "active" and
       posting.itemName == itemName and
       posting.price == price and
       posting.count == count then
      return posting
    end
  end
  return nil
end

function Dukonomics.Data.FindActivePostingByItem(itemName, count)
  local data = GetDataStore()
  for _, posting in ipairs(data.postings) do
    if posting.status == "active" and
       posting.itemName == itemName and
       posting.count == count then
      return posting
    end
  end
  return nil
end

function Dukonomics.Data.FindPostingByAuctionID(auctionID)
  local data = GetDataStore()
  if not auctionID or not data.postings then return nil end

  for _, posting in ipairs(data.postings) do
    if posting.auctionID == auctionID and posting.status == "active" then
      Dukonomics.Logger.debug("FindPostingByAuctionID: FOUND for " .. auctionID)
      return posting
    end
  end

  Dukonomics.Logger.debug("FindPostingByAuctionID: NOT FOUND for " .. auctionID)
  return nil
end

local function NormalizeName(name)
  return name and name:match("^%s*(.-)%s*$"):lower() or ""
end

function Dukonomics.Data.FindActivePostingWithQuantity(itemName, price, minCount)
  local data = GetDataStore()
  local searchName = NormalizeName(itemName)
  Dukonomics.Logger.debug("FindActivePosting: '" .. searchName .. "' minCount=" .. tostring(minCount) .. " price=" .. tostring(price))

  for i, posting in ipairs(data.postings) do
    local postingName = NormalizeName(posting.itemName)
    if posting.status == "active" and
       postingName == searchName and
       (posting.count or 0) >= (minCount or 1) and
       (price == nil or posting.price == price) then
      Dukonomics.Logger.debug("  FOUND at [" .. i .. "]: count=" .. posting.count)
      return posting
    end
  end

  return nil
end

function Dukonomics.Data.FindActivePostingWithTotalPrice(itemName, totalPrice, minCount)
  local data = GetDataStore()
  local searchName = NormalizeName(itemName)
  Dukonomics.Logger.debug("FindActivePostingWithTotalPrice: '" .. searchName .. "' minCount=" .. tostring(minCount) .. " totalPrice=" .. tostring(totalPrice))

  for i, posting in ipairs(data.postings) do
    local postingName = NormalizeName(posting.itemName)
    if posting.status == "active" and
       postingName == searchName and
       (posting.count or 0) >= (minCount or 1) and
       (totalPrice == nil or posting.totalPrice == totalPrice) then
      Dukonomics.Logger.debug("  FOUND at [" .. i .. "]: count=" .. posting.count .. " totalPrice=" .. tostring(posting.totalPrice))
      return posting
    end
  end

  return nil
end

function Dukonomics.Data.FindNewestActivePostingWithQuantity(itemName, minCount)
  local data = GetDataStore()
  local searchName = NormalizeName(itemName)
  local newestPosting = nil
  local newestTimestamp = 0

  for _, posting in ipairs(data.postings) do
    local postingName = NormalizeName(posting.itemName)
    local timestamp = posting.timestamp or 0

    if posting.status == "active" and
       postingName == searchName and
       (posting.count or 0) >= (minCount or 1) and
       timestamp > newestTimestamp then
      newestPosting = posting
      newestTimestamp = timestamp
    end
  end

  return newestPosting
end

function Dukonomics.Data.FindActivePostingsWithTotalPrice(itemName, totalPrice)
  local data = GetDataStore()
  local searchName = NormalizeName(itemName)
  local results = {}

  for _, posting in ipairs(data.postings) do
    local postingName = NormalizeName(posting.itemName)
    if posting.status == "active" and
       postingName == searchName and
       (totalPrice == nil or posting.totalPrice == totalPrice) then
      table.insert(results, posting)
    end
  end

  return results
end

function Dukonomics.Data.FindActivePostingsWithQuantity(itemName, minCount)
  local data = GetDataStore()
  local searchName = NormalizeName(itemName)
  local results = {}

  for _, posting in ipairs(data.postings) do
    local postingName = NormalizeName(posting.itemName)
    if posting.status == "active" and
       postingName == searchName and
       (posting.count or 0) >= (minCount or 1) then
      table.insert(results, posting)
    end
  end

  return results
end

function Dukonomics.Data.ReducePostingQuantity(posting, quantity, newStatus)
  if not posting or quantity <= 0 then return false end

  local remaining = posting.count - quantity

  if remaining <= 0 then
    posting.status = newStatus
    posting[newStatus .. "At"] = time()
    posting.pendingRemoval = nil
    posting.pendingRemovalType = nil
    posting.pendingRemovalQuantity = nil
    posting.cancelledByEvent = nil

    if newStatus == "sold" then
      posting.soldPrice = posting.price
      posting.profit = (posting.price * quantity) - posting.deposit
    end

    Dukonomics.Logger.debug("Posting fully " .. newStatus .. ": " .. posting.itemName .. " (was " .. posting.count .. ")")
    ScheduleUIRefresh()
    return true
  else
    posting.count = remaining

    local consumedDeposit = math.floor(posting.deposit * quantity / (quantity + remaining))
    posting.deposit = posting.deposit - consumedDeposit

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

    if newStatus == "sold" then
      consumed.soldPrice = consumed.price
      consumed.profit = (consumed.price * quantity) - consumed.deposit
    end

    table.insert(data.postings, consumed)

    Dukonomics.Logger.debug("Posting partially " .. newStatus .. ": " .. posting.itemName .. " x" .. quantity .. " (remaining: " .. remaining .. ")")
    ScheduleUIRefresh()
    return false
  end
end

function Dukonomics.Data.MarkPostingAsSold(posting, soldPrice)
  posting.status = "sold"
  posting.soldAt = time()
  posting.soldPrice = soldPrice or posting.price
  posting.profit = posting.soldPrice - posting.deposit

  Dukonomics.Logger.debug("Marked as sold: " .. (posting.itemName or "?") .. " - Profit: " .. posting.profit .. "g")
  ScheduleUIRefresh()
  return true
end

-- =============================================================================
-- PURCHASE OPERATIONS
-- =============================================================================

function Dukonomics.Data.AddPurchase(purchase)
  purchase.source = GetPlayerSource()
  local data = GetDataStore()
  table.insert(data.purchases, purchase)
  Dukonomics.Logger.debug("Purchase saved: " .. (purchase.itemName or "?") .. " x" .. purchase.count)
  ScheduleUIRefresh()
end

-- =============================================================================
-- QUERIES
-- =============================================================================

function Dukonomics.Data.GetPostings(timeFrom, timeTo, filters)
  local data = GetDataStore()
  local results = {}
  local now = time()

  for _, posting in ipairs(data.postings) do
    local timestamp = posting.timestamp or 0

    if timestamp >= (timeFrom or 0) and timestamp <= (timeTo or now) then
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

function Dukonomics.Data.GetCharacters()
  local data = GetDataStore()
  local chars = {}
  local seen = {}

  local function addFromList(list)
    if not list then return end
    for _, item in ipairs(list) do
      if item.source and item.source.character and item.source.realm then
        local key = item.source.character .. "-" .. item.source.realm
        if not seen[key] then
          seen[key] = true
          table.insert(chars, {
            character = item.source.character,
            realm = item.source.realm,
            key = key
          })
        end
      end
    end
  end

  addFromList(data.postings)
  addFromList(data.purchases)

  table.sort(chars, function(a, b) return a.character < b.character end)
  return chars
end

-- =============================================================================
-- TRANSACTIONS
-- =============================================================================

function Dukonomics.Data.ApplyTransaction(changes)
  if not changes or #changes == 0 then return true end

  Dukonomics.Logger.debug("Starting transaction with " .. #changes .. " changes")

  for i, change in ipairs(changes) do
    if change.type ~= "reducePosting" then
      return false, "Unsupported change type: " .. tostring(change.type)
    end
    if not change.posting or not change.quantity or change.quantity <= 0 then
      return false, "Invalid change at index " .. i
    end
    if change.posting.count < change.quantity then
      return false, "Insufficient quantity at index " .. i
    end
  end

  for _, change in ipairs(changes) do
    Dukonomics.Data.ReducePostingQuantity(change.posting, change.quantity, change.status)
  end

  Dukonomics.Logger.debug("Transaction completed")
  return true
end

-- =============================================================================
-- MAINTENANCE
-- =============================================================================

function Dukonomics.Data.ClearOldData(daysToKeep)
  local data = GetDataStore()
  if not data then
    Dukonomics.Logger.print("No hay datos para limpiar")
    return
  end

  local cutoff = time() - (daysToKeep * 24 * 60 * 60)
  local removedPostings = 0
  local removedPurchases = 0
  local totalPostings = #data.postings
  local totalPurchases = #data.purchases

  if data.postings then
    for i = #data.postings, 1, -1 do
      if (data.postings[i].timestamp or 0) < cutoff then
        table.remove(data.postings, i)
        removedPostings = removedPostings + 1
      end
    end
  end

  if data.purchases then
    for i = #data.purchases, 1, -1 do
      if (data.purchases[i].timestamp or 0) < cutoff then
        table.remove(data.purchases, i)
        removedPurchases = removedPurchases + 1
      end
    end
  end

  if removedPostings > 0 or removedPurchases > 0 then
    local msg = "Eliminados "
    if removedPostings > 0 then
      msg = msg .. removedPostings .. " de " .. totalPostings .. " postings"
    end
    if removedPurchases > 0 then
      if removedPostings > 0 then msg = msg .. " y " end
      msg = msg .. removedPurchases .. " de " .. totalPurchases .. " compras"
    end
    msg = msg .. " (más antiguos que " .. daysToKeep .. " días)"
    Dukonomics.Logger.print(msg)
  else
    Dukonomics.Logger.print("No se encontraron datos más antiguos que " .. daysToKeep .. " días")
  end

  ScheduleUIRefresh()
end
