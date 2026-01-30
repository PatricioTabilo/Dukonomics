-- Dukonomics: Mail processing for auction house tracking

Dukonomics.Mail = {}

-- Pattern matching for auction mail subjects (using WoW constants)
local expiredPattern = AUCTION_EXPIRED_MAIL_SUBJECT and AUCTION_EXPIRED_MAIL_SUBJECT:gsub("%%s", "(.+)") or "Auction Expired: (.+)"
local cancelledPattern = AUCTION_REMOVED_MAIL_SUBJECT and AUCTION_REMOVED_MAIL_SUBJECT:gsub("%%s", "(.+)") or "Auction Cancelled: (.+)"

-- Check if sender is the Auction House
local function IsAuctionHouseSender(sender)
  if not sender then return false end

  local auctionHouseName = Dukonomics.Loc("Auction House Sender")
  return sender == auctionHouseName
end

-- Check if mail is cacheable (auction-related and has necessary data)
local function IsMailCacheable(sender, subject, invoiceType)
  if not IsAuctionHouseSender(sender) then
    return false
  end

  if invoiceType then
    return true
  end

  if subject and (subject:match(expiredPattern) or subject:match(cancelledPattern)) then
    return true
  end

  return false
end

-- Extract and structure mail data from WoW APIs
local function CreateMailData(mailIndex)
  local _, _, sender, subject, money = GetInboxHeaderInfo(mailIndex)
  local invoiceType, itemName, playerName, bid, _, deposit, consignment, _, _, _, count = GetInboxInvoiceInfo(mailIndex)

  local itemLink = nil
  local attachmentCount = select(1, GetInboxNumItems())
  if attachmentCount and mailIndex <= attachmentCount then
    itemLink = GetInboxItemLink(mailIndex, 1)
  end

  return {
    subject = subject,
    money = money,
    invoiceType = invoiceType,
    itemName = itemName,
    itemLink = itemLink,
    bid = bid,
    count = count,
    consignment = consignment
  }
end

-- Event: Mail inbox updated (cache attachments before they're removed)
local function OnMailInboxUpdate()
  Dukonomics.Logger.debug("MAIL_INBOX_UPDATE: " .. GetInboxNumItems() .. " mails")
  Dukonomics.MailCacheRepository:Clear()

  for mailIndex = 1, GetInboxNumItems() do
    local _, _, sender, subject, money = GetInboxHeaderInfo(mailIndex)
    local invoiceType, itemName, playerName, bid, _, deposit, consignment, _, _, _, count = GetInboxInvoiceInfo(mailIndex)

    -- Skip non-cacheable mails (personal emails, irrelevant system mails)
    if IsMailCacheable(sender, subject, invoiceType) then
      local mailData = CreateMailData(mailIndex)

      Dukonomics.Logger.debugTable(mailData, "Mail #" .. mailIndex .. " cached")

      Dukonomics.MailCacheRepository:Add(mailIndex, mailData)
    end
  end
end

-- Event: Mail item closed (process the data after taking items/gold)
local function OnCloseInboxItem(mailIndex)
  local mail = Dukonomics.MailCacheRepository:Get(mailIndex)
  if not mail then return end

  Dukonomics.Logger.debug("CLOSE_INBOX_ITEM: #" .. mailIndex .. " subject='" .. tostring(mail.subject) .. "'")

  -- Process invoice (sale or purchase)
  if mail.invoiceType and mail.itemName then
    local itemName = mail.itemName
    local mailBid = mail.bid
    local mailCount = mail.count

    if mail.invoiceType == "seller" then
      -- Use SalesService to handle the sale processing
      local success = Dukonomics.SalesService.ProcessSale(itemName, mail.grossTotal, mailCount)
      if success then
        Dukonomics.Logger.debug("Sale processed successfully: " .. itemName .. " x" .. mailCount .. " for " .. mail.grossTotal .. "c")
      else
        Dukonomics.Logger.debug("Sale processing failed: " .. itemName .. " x" .. mailCount)
      end

    elseif mail.invoiceType == "buyer" then
      -- Extract itemID from itemLink
      local itemID = nil
      if mail.itemLink then
        itemID = tonumber(mail.itemLink:match("item:(%d+)"))
      end

      Dukonomics.Data.AddPurchase({
        itemID = itemID,
        itemLink = mail.itemLink,
        itemName = itemName,
        price = mail.unitPrice,
        count = mailCount,
        timestamp = time()
      })
      Dukonomics.Logger.debug("Purchase: " .. itemName .. " x" .. mailCount .. " for " .. mailBid .. "c total (" .. mail.unitPrice .. "c each)")
    end

  -- Process cancellation/expiration (no invoice, item in attachment)
  elseif mail.subject then
    Dukonomics.Logger.debug("Processing subject for cancellation/expiry: '" .. tostring(mail.subject) .. "'")

    local itemInfo = mail.subject:match(expiredPattern)
    local failedType = "expired"

    if not itemInfo then
      itemInfo = mail.subject:match(cancelledPattern)
      failedType = "cancelled"
    end

    Dukonomics.Logger.debug("Pattern match result: itemInfo='" .. tostring(itemInfo) .. "', type=" .. failedType)

    if itemInfo then
      itemInfo = itemInfo:match("^%s*(.-)%s*$")

      local itemName, quantityText = itemInfo:match("(.-)%s*%((%d+)%)$")
      local quantity = tonumber(quantityText) or 1
      if not itemName or itemName == "" then
        itemName = itemInfo
      end

      itemName = itemName:match("^%s*(.-)%s*$")

      Dukonomics.Logger.debug("Failed auction: " .. failedType .. " - '" .. tostring(itemName) .. "' x" .. quantity)

      if failedType == "cancelled" then
        Dukonomics.Logger.debug("  ⏭️  Cancelación ignorada por correo; se procesa solo por eventos")
        return
      end

      -- Si ya se marcó como cancelado por evento, no reprocesar
      if DUKONOMICS_DATA and DUKONOMICS_DATA.postings then
        local searchName = itemName:match("^%s*(.-)%s*$"):lower()
        for _, posting in ipairs(DUKONOMICS_DATA.postings) do
          local postingName = posting.itemName and posting.itemName:match("^%s*(.-)%s*$"):lower() or ""
          if posting.cancelledByEvent and posting.status == "cancelled" and
             postingName == searchName and posting.count == quantity then
            posting.cancelledByEvent = nil
            Dukonomics.Logger.debug("  ✅ Ya estaba cancelado por evento; se omite reprocesar")
            return
          end
        end
      end

      -- PRIORITY 1: Try to find a posting marked as "pendingRemoval" (most accurate)
      -- This is set by Events.lua when CancelAuction hook fires
      local posting = nil
      if Dukonomics.Events and Dukonomics.Events.FindPendingRemovalPosting then
        posting = Dukonomics.Events.FindPendingRemovalPosting(itemName, quantity)
        if posting then
          Dukonomics.Logger.debug("  ✅ Found via pendingRemoval flag (exact match by auctionID " .. tostring(posting.cancelledAuctionID) .. ")")
        end
      end

      -- PRIORITY 2: Try to find by auctionID from recently removed auctions
      if not posting and Dukonomics.Events and Dukonomics.Events.GetRemovedAuctionByItem then
        local auctionID, auctionInfo = Dukonomics.Events.GetRemovedAuctionByItem(itemName, quantity)
        if auctionID then
          posting = Dukonomics.Data.FindPostingByAuctionID(auctionID)
          if posting then
            Dukonomics.Logger.debug("  ✅ Found via GetRemovedAuctionByItem -> auctionID " .. auctionID)
          end
        end
      end

      -- PRIORITY 3: Fallback to FIFO matching (may be wrong if multiple postings exist)
      if not posting then
        Dukonomics.Logger.debug("  ⚠️  WARNING: Using FIFO fallback (may pick wrong posting if multiple exist)")
        posting = Dukonomics.Data.FindActivePostingWithQuantity(itemName, nil, quantity)
        if posting then
          Dukonomics.Logger.debug("  ⚠️  FIFO selected: price=" .. tostring(posting.price) .. "c, posted at " .. tostring(posting.timestamp))
        end
      end

      if posting then
        -- Clear the pendingRemoval flag
        posting.pendingRemoval = nil
        posting.cancelledAuctionID = nil
        Dukonomics.Data.ReducePostingQuantity(posting, quantity, failedType)
        Dukonomics.Logger.debug("✅ Successfully marked " .. quantity .. " of '" .. itemName .. "' as " .. failedType)
      else
        Dukonomics.Logger.debug("❌ WARNING: Could not find active posting for " .. itemName .. " x" .. quantity)
      end
    end
  end
end

-- Initialize mail event handlers
function Dukonomics.Mail.Initialize()
  Dukonomics.Logger.debug("Initializing mail handlers")

  local mailFrame = CreateFrame("Frame")
  mailFrame:RegisterEvent("MAIL_INBOX_UPDATE")
  mailFrame:RegisterEvent("CLOSE_INBOX_ITEM")

  mailFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MAIL_INBOX_UPDATE" then
      OnMailInboxUpdate()
    elseif event == "CLOSE_INBOX_ITEM" then
      local mailIndex = ...
      OnCloseInboxItem(mailIndex)
    end
  end)

  Dukonomics.Logger.debug("Mail handlers registered")
end
