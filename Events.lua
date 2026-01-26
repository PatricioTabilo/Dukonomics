-- Dukonomics: Event handling for AH tracking

Dukonomics.Events = {}

-- Store the last posted item info temporarily
local lastPostedItem = nil

-- Get item link from bag location
local function GetContainerItemLink(location)
  if not location then return nil end
  local bagAndSlot = location:GetBagAndSlot()
  if not bagAndSlot then return nil end
  local info = C_Container.GetContainerItemInfo(bagAndSlot.bagID, bagAndSlot.slotIndex)
  return info and info.hyperlink
end

-- Hook into PostItem (for regular items)
local function OnPostItem(location, duration, quantity, bid, buyout)
  local link = GetContainerItemLink(location)
  if not link then
    Dukonomics.Debug("PostItem: couldn't get item link")
    return
  end

  local deposit = C_AuctionHouse.CalculateItemDeposit(location, duration, quantity)
  local timestamp = time()
  local price = buyout or bid or 0

  -- Store for later when we get the auctionID
  lastPostedItem = {
    itemLink = link,
    itemName = C_Item.GetItemNameByID(link),
    buyout = buyout,
    bid = bid,
    count = quantity,
    deposit = deposit,
    duration = duration,
    price = price,
    timestamp = timestamp,
    status = "pending"
  }

  Dukonomics.Debug("PostItem hook: " .. (lastPostedItem.itemName or "?") .. " x" .. quantity)
end

-- Hook into PostCommodity (for stackable commodities)
local function OnPostCommodity(location, duration, quantity, unitPrice)
  local link = GetContainerItemLink(location)
  if not link then
    Dukonomics.Debug("PostCommodity: couldn't get item link")
    return
  end

  local itemID = C_Item.GetItemInfoInstant(link)
  local deposit = C_AuctionHouse.CalculateCommodityDeposit(itemID, duration, quantity)
  local timestamp = time()

  -- Store for later when we get the auctionID
  lastPostedItem = {
    itemLink = link,
    itemName = C_Item.GetItemNameByID(link),
    buyout = unitPrice,
    bid = nil,
    count = quantity,
    deposit = deposit,
    duration = duration,
    price = unitPrice,
    timestamp = timestamp,
    status = "pending"
  }

  Dukonomics.Debug("PostCommodity hook: " .. (lastPostedItem.itemName or "?") .. " x" .. quantity)
end

-- Event: When auction is created (get the real auctionID)
local function OnAuctionCreated(auctionID)
  if not lastPostedItem then
    Dukonomics.Debug("AUCTION_HOUSE_AUCTION_CREATED but no lastPostedItem stored")
    return
  end

  -- Add the real auctionID
  lastPostedItem.auctionID = auctionID
  lastPostedItem.status = "active"

  -- Calculate expiration time
  -- duration: 1=12h, 2=24h, 3=48h
  local hours = lastPostedItem.duration * 12
  lastPostedItem.expiresAt = lastPostedItem.timestamp + (hours * 3600)

  -- Save to data
  Dukonomics.Data.AddPosting(lastPostedItem)

  Dukonomics.Debug("AUCTION_HOUSE_AUCTION_CREATED: auctionID=" .. auctionID .. " for " .. (lastPostedItem.itemName or "?"))

  -- Clear temporary storage
  lastPostedItem = nil
end

-- Event: When auction is sold
local function OnAuctionSold(auctionID)
  Dukonomics.Debug("AUCTION_HOUSE_PURCHASE_COMPLETED: auctionID=" .. auctionID)

  Dukonomics.Data.UpdatePostingByAuctionID(auctionID, {
    status = "sold",
    soldAt = time()
  })
end

-- Event: When auction is canceled
local function OnAuctionCanceled(auctionID)
  Dukonomics.Debug("AUCTION_CANCELED: auctionID=" .. auctionID)

  Dukonomics.Data.UpdatePostingByAuctionID(auctionID, {
    status = "cancelled",
    cancelledAt = time()
  })
end

-- Event: When owned auctions list updates
local function OnOwnedAuctionsUpdated()
  Dukonomics.Debug("OWNED_AUCTIONS_UPDATED")

  -- Get current active auctions from the game
  local activeAuctions = {}
  for i = 1, C_AuctionHouse.GetNumOwnedAuctions() do
    local info = C_AuctionHouse.GetOwnedAuctionInfo(i)
    if info and info.auctionID then
      activeAuctions[info.auctionID] = {
        status = info.status, -- 0=active, 1=sold
        timeLeftSeconds = info.timeLeftSeconds
      }
    end
  end

  -- Update our postings with current info
  for _, posting in ipairs(DUKONOMICS_DATA.postings) do
    if posting.auctionID and activeAuctions[posting.auctionID] then
      local auctionInfo = activeAuctions[posting.auctionID]

      -- Update time left
      posting.timeLeftSeconds = auctionInfo.timeLeftSeconds

      -- Update status if changed
      if auctionInfo.status == 1 and posting.status ~= "sold" then
        posting.status = "sold"
        posting.soldAt = time()
        Dukonomics.Debug("Auction " .. posting.auctionID .. " status changed to sold")
      end
    end
  end
end

-- Main event frame
local eventFrame = CreateFrame("Frame")

function Dukonomics.Events.Initialize()
  Dukonomics.Debug("Initializing event handlers")

  -- Register hooks for posting
  hooksecurefunc(C_AuctionHouse, "PostItem", OnPostItem)
  hooksecurefunc(C_AuctionHouse, "PostCommodity", OnPostCommodity)

  -- Register events
  eventFrame:RegisterEvent("AUCTION_HOUSE_AUCTION_CREATED")
  eventFrame:RegisterEvent("AUCTION_HOUSE_PURCHASE_COMPLETED")
  eventFrame:RegisterEvent("AUCTION_CANCELED")
  eventFrame:RegisterEvent("OWNED_AUCTIONS_UPDATED")
  eventFrame:RegisterEvent("AUCTION_HOUSE_SHOW")

  eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "AUCTION_HOUSE_AUCTION_CREATED" then
      local auctionID = ...
      OnAuctionCreated(auctionID)

    elseif event == "AUCTION_HOUSE_PURCHASE_COMPLETED" then
      local auctionID = ...
      OnAuctionSold(auctionID)

    elseif event == "AUCTION_CANCELED" then
      local auctionID = ...
      OnAuctionCanceled(auctionID)

    elseif event == "OWNED_AUCTIONS_UPDATED" then
      OnOwnedAuctionsUpdated()

    elseif event == "AUCTION_HOUSE_SHOW" then
      Dukonomics.Debug("Auction House opened")
      -- Could trigger a sync here if needed
    end
  end)

  Dukonomics.Debug("Event handlers registered")
end
