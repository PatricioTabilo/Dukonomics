Dukonomics.SalesService = {}

local function IsPostingStillInAuctionHouse(posting)
  if not (Dukonomics.AuctionHandler and Dukonomics.AuctionHandler.IsPostingStillInAH) then
    return false
  end

  local stillInAH = Dukonomics.AuctionHandler.IsPostingStillInAH(posting)

  if stillInAH == nil then
    Dukonomics.Logger.debug("  ⚠️ Cannot verify AH status (no auctionID): " .. tostring(posting.itemName))
    return false
  end

  if stillInAH then
    Dukonomics.Logger.debug("  🛑 SKIPPING: Posting still active in AH: " .. tostring(posting.itemName) .. " x" .. tostring(posting.count))
    return true
  end

  return false
end

local function FilterOutActiveAuctions(postings)
  local filtered = {}
  for _, posting in ipairs(postings) do
    if not IsPostingStillInAuctionHouse(posting) then
      table.insert(filtered, posting)
    end
  end
  return filtered
end

local function NormalizeName(name)
  return name and name:match("^%s*(.-)%s*$"):lower() or ""
end

local function FindPostingsByUnitPrice(itemName, unitPrice)
  local data = Dukonomics.Data.GetDataStore()
  local searchName = NormalizeName(itemName)
  local results = {}

  for _, posting in ipairs(data.postings) do
    if posting.status == "active" and
       NormalizeName(posting.itemName) == searchName and
       posting.price == unitPrice then
      table.insert(results, posting)
    end
  end

  return FilterOutActiveAuctions(results)
end

local function FindPostingsByItemName(itemName)
  local data = Dukonomics.Data.GetDataStore()
  local searchName = NormalizeName(itemName)
  local results = {}

  for _, posting in ipairs(data.postings) do
    if posting.status == "active" and
       NormalizeName(posting.itemName) == searchName and
       (posting.count or 0) > 0 then
      table.insert(results, posting)
    end
  end

  return FilterOutActiveAuctions(results)
end

local function SortByTimestampLIFO(postings)
  table.sort(postings, function(a, b)
    return (a.timestamp or 0) > (b.timestamp or 0)
  end)
end

local function DistributeQuantity(postings, quantity, changes)
  local remaining = quantity

  for _, posting in ipairs(postings) do
    if remaining <= 0 then break end

    local qty = math.min(remaining, posting.count)
    table.insert(changes, {
      type = "reducePosting",
      posting = posting,
      quantity = qty,
      status = "sold"
    })
    remaining = remaining - qty
  end

  return remaining
end

function Dukonomics.SalesService.ProcessSale(itemName, grossTotal, quantitySold)
  if not itemName or itemName == "" then
    Dukonomics.Logger.debug("ERROR: ProcessSale - invalid itemName")
    return false
  end

  if not grossTotal or grossTotal < 0 then
    Dukonomics.Logger.debug("ERROR: ProcessSale - invalid grossTotal: " .. tostring(grossTotal))
    return false
  end

  if not quantitySold or quantitySold <= 0 then
    Dukonomics.Logger.debug("ERROR: ProcessSale - invalid quantitySold: " .. tostring(quantitySold))
    return false
  end

  local unitPrice = math.floor(grossTotal / quantitySold)
  Dukonomics.Logger.debug("Processing sale: '" .. itemName .. "' x" .. quantitySold .. " @ " .. unitPrice .. "c/unit")

  local changes = {}
  local remainingQuantity = quantitySold
  local strategyUsed = "none"

  -- Strategy 1: Exact Match
  if remainingQuantity > 0 then
    local exactMatch = Dukonomics.Data.FindActivePostingWithTotalPrice(itemName, grossTotal, quantitySold)
    if exactMatch and not IsPostingStillInAuctionHouse(exactMatch) then
      table.insert(changes, {
        type = "reducePosting",
        posting = exactMatch,
        quantity = quantitySold,
        status = "sold"
      })
      remainingQuantity = 0
      strategyUsed = "exact_match"
      Dukonomics.Logger.debug("  Strategy 1: Found exact match")
    end
  end

  -- Strategy 2: Unit Price Match (LIFO)
  if remainingQuantity > 0 then
    local priceMatches = FindPostingsByUnitPrice(itemName, unitPrice)
    if #priceMatches > 0 then
      SortByTimestampLIFO(priceMatches)
      local before = remainingQuantity
      remainingQuantity = DistributeQuantity(priceMatches, remainingQuantity, changes)

      if remainingQuantity < before then
        strategyUsed = strategyUsed == "none" and "unit_price_match" or strategyUsed .. "+unit_price_match"
        Dukonomics.Logger.debug("  Strategy 2: Distributed " .. (before - remainingQuantity) .. " units")
      end
    end
  end

  -- Strategy 3: Fallback by Item Name (LIFO)
  if remainingQuantity > 0 then
    Dukonomics.Logger.debug("  ⚠️ Using fallback strategy for " .. remainingQuantity .. " units")

    local anyMatches = FindPostingsByItemName(itemName)
    if #anyMatches > 0 then
      SortByTimestampLIFO(anyMatches)
      local before = remainingQuantity
      remainingQuantity = DistributeQuantity(anyMatches, remainingQuantity, changes)

      if remainingQuantity < before then
        strategyUsed = strategyUsed == "none" and "fallback" or strategyUsed .. "+fallback"
        Dukonomics.Logger.debug("  Strategy 3: Distributed " .. (before - remainingQuantity) .. " units")
      end
    end
  end

  if remainingQuantity > 0 then
    Dukonomics.Logger.debug("❌ FAILED: " .. remainingQuantity .. " units unassigned for '" .. itemName .. "'")
    return false
  end

  local success, errorMsg = Dukonomics.Data.ApplyTransaction(changes)
  if not success then
    Dukonomics.Logger.debug("❌ FAILED: " .. tostring(errorMsg))
    return false
  end

  Dukonomics.Logger.debug("✅ Sale completed: " .. strategyUsed)
  return true
end

function Dukonomics.SalesService.ProcessPurchase(itemName, itemLink, itemID, unitPrice, quantity)
  if not itemName or itemName == "" then
    Dukonomics.Logger.debug("ERROR: ProcessPurchase - invalid itemName")
    return false
  end

  if not unitPrice or unitPrice < 0 then
    Dukonomics.Logger.debug("ERROR: ProcessPurchase - invalid unitPrice")
    return false
  end

  if not quantity or quantity <= 0 then
    Dukonomics.Logger.debug("ERROR: ProcessPurchase - invalid quantity")
    return false
  end

  Dukonomics.Logger.debug("Processing purchase: '" .. itemName .. "' x" .. quantity .. " @ " .. unitPrice .. "c/unit")

  Dukonomics.Data.AddPurchase({
    itemID = itemID,
    itemLink = itemLink,
    itemName = itemName,
    price = unitPrice,
    count = quantity,
    timestamp = time()
  })

  Dukonomics.Logger.debug("✅ Purchase recorded")
  return true
end

function Dukonomics.SalesService.Initialize()
  Dukonomics.Logger.debug("SalesService initialized")
end
