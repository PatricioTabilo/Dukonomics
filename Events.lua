-- Dukonomics: Event handling for AH tracking

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


-- Event: Mail inbox updated (cache attachments before they're removed)
local mailCache = {}

-- Pattern matching for auction mail subjects (using WoW constants)
local expiredPattern = AUCTION_EXPIRED_MAIL_SUBJECT:gsub("%%s", "(.+)")
local cancelledPattern = AUCTION_REMOVED_MAIL_SUBJECT:gsub("%%s", "(.+)")

local function OnMailInboxUpdate()
  Dukonomics.Debug("MAIL_INBOX_UPDATE: " .. GetInboxNumItems() .. " mails")
  mailCache = {}

  for mailIndex = 1, GetInboxNumItems() do
    local _, _, _, subject, money = GetInboxHeaderInfo(mailIndex)
    local invoiceType, itemName, playerName, bid, _, deposit, consignment, _, _, _, count = GetInboxInvoiceInfo(mailIndex)

    -- Cache this mail's data for later processing
    mailCache[mailIndex] = {
      subject = subject,
      money = money,
      invoiceType = invoiceType,
      itemName = itemName,
      bid = bid,
      count = count
    }

    Dukonomics.Debug("Cached mail #" .. mailIndex .. ": subject='" .. tostring(subject) .. "', type=" .. tostring(invoiceType) .. ", item=" .. tostring(itemName))
  end
end

local function OnCloseInboxItem(mailIndex)
  local mail = mailCache[mailIndex]
  if not mail then return end

  Dukonomics.Debug("CLOSE_INBOX_ITEM: #" .. mailIndex .. " subject='" .. tostring(mail.subject) .. "'")

  -- Process invoice (sale or purchase)
  if mail.invoiceType and mail.itemName then
    local cleanItemName = mail.itemName:match("^(.-)%s*%(%d+%)$") or mail.itemName

    if mail.invoiceType == "seller" then
      -- Sale
      local posting = Dukonomics.Data.FindActivePosting(cleanItemName, mail.bid, mail.count)
      if posting then
        Dukonomics.Data.MarkPostingAsSold(posting, mail.bid)
        Dukonomics.Debug("Sale: " .. cleanItemName .. " x" .. mail.count .. " for " .. mail.bid .. "c")
      else
        Dukonomics.Debug("Sale no match: " .. cleanItemName .. " x" .. mail.count .. " @ " .. mail.bid .. "c")
      end

    elseif mail.invoiceType == "buyer" then
      -- Purchase
      Dukonomics.Data.AddPurchase({
        itemName = cleanItemName,
        price = mail.bid,
        count = mail.count,
        timestamp = time()
      })
      Dukonomics.Debug("Purchase: " .. cleanItemName .. " x" .. mail.count .. " for " .. mail.bid .. "c")
    end

  -- Process cancellation/expiration (no invoice, item in attachment)
  elseif mail.subject then
    local itemInfo = mail.subject:match(expiredPattern)
    local failedType = "expired"

    if not itemInfo then
      itemInfo = mail.subject:match(cancelledPattern)
      failedType = "cancelled"
    end

    if itemInfo then
      -- Extract item name and quantity from subject (e.g. "Item Name (5)" or "Item Name")
      local itemName, quantityText = itemInfo:match("(.*)%s*%((%d+)%)")
      local quantity = tonumber(quantityText) or 1
      if not itemName then
        itemName = itemInfo
      end

      Dukonomics.Debug("Failed auction: " .. failedType .. " - " .. itemName .. " x" .. quantity)

      local posting = Dukonomics.Data.FindActivePostingByItem(itemName, quantity)
      if posting then
        posting.status = failedType
        posting[failedType .. "At"] = time()
        Dukonomics.Debug("Matched posting: " .. itemName .. " - " .. failedType)
      else
        Dukonomics.Debug("No match: " .. itemName .. " x" .. quantity)
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
  eventFrame:RegisterEvent("MAIL_INBOX_UPDATE")
  eventFrame:RegisterEvent("CLOSE_INBOX_ITEM")

  eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MAIL_INBOX_UPDATE" then
      OnMailInboxUpdate()
    elseif event == "CLOSE_INBOX_ITEM" then
      local mailIndex = ...
      OnCloseInboxItem(mailIndex)
    end
  end)

  Dukonomics.Debug("Event handlers registered")
end
