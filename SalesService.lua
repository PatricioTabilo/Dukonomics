-- Dukonomics Sales Service
-- Handles business logic for auction sales and purchases
-- Separated from Mail processing for better architecture

Dukonomics.SalesService = {}

-- Helper: Find matching posting for seller transaction
local function FindMatchingPostingForSale(itemName, price, quantity)
  return Dukonomics.Data.FindActivePostingWithQuantity(itemName, price, quantity)
end

-- Helper: Find newest posting for quantity-based matching
local function FindNewestPostingForSale(itemName, quantity)
  return Dukonomics.Data.FindNewestActivePostingWithQuantity(itemName, quantity)
end

-- Process a seller transaction - update sold posting(s)
-- @param itemName string: Name of the sold item
-- @param totalPricePaid number: Total price paid by buyer (grossTotal)
-- @param quantitySold number: Number of items sold
function Dukonomics.SalesService.ProcessSale(itemName, totalPricePaid, quantitySold)
  Dukonomics.Logger.debug("Processing sale: " .. itemName .. " x" .. quantitySold .. " for " .. totalPricePaid)

  -- Strategy 1: Exact match by item, total price, and quantity (ideal case)
  local posting = Dukonomics.Data.FindActivePostingWithTotalPrice(itemName, totalPricePaid, quantitySold)

  if posting then
    Dukonomics.Logger.debug("Found exact match posting, reducing quantity by " .. quantitySold)
    Dukonomics.Data.ReducePostingQuantity(posting, quantitySold, "sold")
    return true
  end

  -- Strategy 2: Distribute across multiple identical postings (same price, LIFO)
  Dukonomics.Logger.debug("No exact match, distributing across multiple identical postings")
  local remainingQuantity = quantitySold
  local identicalPostings = Dukonomics.Data.FindActivePostingsWithTotalPrice(itemName, totalPricePaid)

  -- Sort by timestamp descending (newest first - LIFO)
  table.sort(identicalPostings, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)

  for _, posting in ipairs(identicalPostings) do
    if remainingQuantity <= 0 then break end

    local quantityToReduce = math.min(remainingQuantity, posting.count)
    Dukonomics.Logger.debug("Reducing identical posting by " .. quantityToReduce)
    Dukonomics.Data.ReducePostingQuantity(posting, quantityToReduce, "sold")
    remainingQuantity = remainingQuantity - quantityToReduce
  end

  if remainingQuantity <= 0 then
    Dukonomics.Logger.debug("Successfully distributed sale across identical postings")
    return true
  end

  -- Strategy 3: Ultimate fallback - distribute across any postings (any price, LIFO)
  Dukonomics.Logger.debug("Still have " .. remainingQuantity .. " items to distribute, using any postings")
  local allPostings = Dukonomics.Data.FindActivePostingsWithQuantity(itemName, 1)

  -- Sort by timestamp descending (newest first - LIFO)
  table.sort(allPostings, function(a, b) return (a.timestamp or 0) > (b.timestamp or 0) end)

  for _, posting in ipairs(allPostings) do
    if remainingQuantity <= 0 then break end

    local quantityToReduce = math.min(remainingQuantity, posting.count)
    Dukonomics.Logger.debug("Reducing fallback posting by " .. quantityToReduce)
    Dukonomics.Data.ReducePostingQuantity(posting, quantityToReduce, "sold")
    remainingQuantity = remainingQuantity - quantityToReduce
  end

  if remainingQuantity > 0 then
    Dukonomics.Logger.debug("WARNING: Could not fully distribute sale, " .. remainingQuantity .. " items unaccounted for")
    return false
  else
    Dukonomics.Logger.debug("Successfully distributed sale across multiple postings")
    return true
  end
end

-- Process a buyer transaction - record purchase
-- @param itemName string: Name of the purchased item
-- @param itemLink string: Item link (optional)
-- @param itemID number: Item ID (optional)
-- @param unitPrice number: Price per unit paid
-- @param quantity number: Number of items purchased
function Dukonomics.SalesService.ProcessPurchase(itemName, itemLink, itemID, unitPrice, quantity)
  Dukonomics.Logger.debug("Processing purchase: " .. itemName .. " x" .. quantity .. " @ " .. unitPrice .. " each")

  Dukonomics.Data.AddPurchase({
    itemID = itemID,
    itemLink = itemLink,
    itemName = itemName,
    price = unitPrice,
    count = quantity,
    timestamp = time()
  })

  return true
end

-- Initialize the sales service
function Dukonomics.SalesService.Initialize()
  Dukonomics.Logger.debug("SalesService initialized")
end

return Dukonomics.SalesService
