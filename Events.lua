-- Dukonomics: Event handling for auction house posting

Dukonomics.Events = {}

-- Get item info from location (after posting, item is gone from bag)
local function GetItemInfoFromLocation(location)
  if not location then
    Dukonomics.Debug("GetItemInfoFromLocation: location es nil")
    return nil
  end

  -- Try to get itemID from the location object itself
  local itemID = C_Item.GetItemID(location)
  if not itemID then
    Dukonomics.Debug("GetItemInfoFromLocation: C_Item.GetItemID retornó nil")
    return nil
  end

  -- Get basic item info
  local itemName, itemLink = C_Item.GetItemInfo(itemID)

  Dukonomics.Debug("GetItemInfoFromLocation: itemID=" .. tostring(itemID) .. ", link=" .. tostring(itemLink))

  return itemID, itemLink, itemName
end

-- Hook into PostItem (for regular items)
local function OnPostItem(location, duration, quantity, bid, buyout)
  local itemID, itemLink, itemName = GetItemInfoFromLocation(location)
  if not itemID then return end

  local deposit = C_AuctionHouse.CalculateItemDeposit(location, duration, quantity)

  Dukonomics.Data.AddPosting({
    itemID = itemID,
    itemLink = itemLink,
    itemName = itemName,
    buyout = buyout,
    bid = bid,
    count = quantity,
    deposit = deposit,
    duration = duration,
    price = buyout or bid or 0,
    timestamp = time(),
    status = "active"
  })
end

-- Hook into PostCommodity (for stackable commodities)
local function OnPostCommodity(location, duration, quantity, unitPrice)
  local itemID, itemLink, itemName = GetItemInfoFromLocation(location)
  if not itemID then return end

  local deposit = C_AuctionHouse.CalculateCommodityDeposit(itemID, duration, quantity)

  Dukonomics.Data.AddPosting({
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
    status = "active"
  })
end

function Dukonomics.Events.Initialize()
  Dukonomics.Debug("Initializing posting event handlers")

  -- Register hooks for posting
  hooksecurefunc(C_AuctionHouse, "PostItem", OnPostItem)
  hooksecurefunc(C_AuctionHouse, "PostCommodity", OnPostCommodity)

  Dukonomics.Debug("Posting event handlers registered")
end
