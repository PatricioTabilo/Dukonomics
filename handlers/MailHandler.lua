-- Mail event handling: processes auction house mail (sales, purchases, cancellations)

Dukonomics.MailHandler = {}

local expiredPattern = AUCTION_EXPIRED_MAIL_SUBJECT and AUCTION_EXPIRED_MAIL_SUBJECT:gsub("%%s", "(.+)") or "Auction Expired: (.+)"
local cancelledPattern = AUCTION_REMOVED_MAIL_SUBJECT and AUCTION_REMOVED_MAIL_SUBJECT:gsub("%%s", "(.+)") or "Auction Cancelled: (.+)"

local function IsAuctionHouseSender(sender)
  if not sender then return false end
  return sender == Dukonomics.Loc("Auction House Sender")
end

local function IsExpiredSubject(subject)
  return subject and subject:match(expiredPattern) ~= nil
end

local function IsCancelledSubject(subject)
  return subject and subject:match(cancelledPattern) ~= nil
end

local function IsMailCacheable(sender, subject, invoiceType)
  if not IsAuctionHouseSender(sender) then return false end
  if invoiceType then return true end
  if IsExpiredSubject(subject) or IsCancelledSubject(subject) then return true end
  return false
end

local function CreateMailData(mailIndex)
  local _, _, sender, subject, money = GetInboxHeaderInfo(mailIndex)
  local invoiceType, itemName, _, bid, _, _, consignment, _, _, _, count = GetInboxInvoiceInfo(mailIndex)
  local itemLink = GetInboxItemLink(mailIndex, 1)

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

local function ExtractItemInfo(subject, pattern)
  local itemInfo = subject:match(pattern)
  if not itemInfo then return nil, 1 end

  local itemName, quantityText = itemInfo:match("(.-)%s*%((%d+)%)$")
  local quantity = tonumber(quantityText) or 1
  if not itemName or itemName == "" then
    itemName = itemInfo
  end

  return itemName:match("^%s*(.-)%s*$"), quantity
end

local function ResolvePetInfo(link)
  if not link then return nil, nil end
  local speciesID = tonumber(link:match("battlepet:(%d+)"))
  if not speciesID or speciesID == 0 then return nil, nil end
  local speciesName = C_PetJournal and C_PetJournal.GetPetInfoBySpeciesID and C_PetJournal.GetPetInfoBySpeciesID(speciesID)
  return speciesID, speciesName
end

local function MatchExpiredPosting(itemName, quantity, itemLink)
  -- Try direct name match first
  local posting = Dukonomics.Data.FindNewestActivePostingWithQuantity(itemName, quantity)
  if posting then return posting end

  -- Fallback: resolve pet species from battlepet link
  if itemLink then
    local speciesID, speciesName = ResolvePetInfo(itemLink)

    -- Try by speciesID
    if speciesID and Dukonomics.Data.FindNewestActivePostingBySpeciesID then
      posting = Dukonomics.Data.FindNewestActivePostingBySpeciesID(speciesID, quantity)
      if posting then return posting end
    end

    -- Try by resolved pet name (different from subject name)
    if speciesName and speciesName ~= itemName then
      posting = Dukonomics.Data.FindNewestActivePostingWithQuantity(speciesName, quantity)
      if posting then return posting end
    end
  end

  return posting
end

-----------------------------------------------------------
-- Mail processors
-----------------------------------------------------------

local function ProcessExpiredMail(mail)
  local itemName, quantity = ExtractItemInfo(mail.subject, expiredPattern)
  if not itemName then return end

  local posting = MatchExpiredPosting(itemName, quantity, mail.itemLink)
  if posting then
    Dukonomics.Data.ReducePostingQuantity(posting, quantity, "expired")
    Dukonomics.Logger.debug("Expired: " .. itemName .. " x" .. quantity)
  else
    Dukonomics.Logger.debug("No posting for expired: " .. itemName .. " x" .. quantity)
  end
end

local function ProcessSaleMail(mail)
  local success = Dukonomics.SalesService.ProcessSale(mail.itemName, mail.grossTotal, mail.count)
  if success then
    Dukonomics.Logger.debug("Sale processed: " .. mail.itemName .. " x" .. mail.count)
  else
    Dukonomics.Logger.debug("Sale failed: " .. mail.itemName .. " x" .. mail.count)
  end
end

local function ProcessPurchaseMail(mail)
  local itemID, speciesID
  if mail.itemLink then
    -- Handle both regular items and battle pets
    itemID = tonumber(mail.itemLink:match("item:(%d+)"))
    if not itemID then
      speciesID = tonumber(mail.itemLink:match("battlepet:(%d+)"))
      if speciesID then itemID = 82800 end -- Pet Cage base item ID
    end
  end

  Dukonomics.Data.AddPurchase({
    itemID = itemID,
    itemLink = mail.itemLink,
    itemName = mail.itemName,
    speciesID = speciesID,
    price = mail.unitPrice,
    count = mail.count,
    timestamp = time()
  })

  Dukonomics.Logger.debug("Purchase: " .. mail.itemName .. " x" .. mail.count .. " @ " .. mail.unitPrice .. "c/u")
end

local function ProcessCancelledMail(mail)
  Dukonomics.Logger.debug("Cancellation ignored (handled by events)")
end

-----------------------------------------------------------
-- Event handlers
-----------------------------------------------------------

local function OnMailInboxUpdate()
  Dukonomics.Logger.debug("MAIL_INBOX_UPDATE: " .. GetInboxNumItems() .. " mails")
  Dukonomics.MailCacheRepository:Clear()

  for mailIndex = 1, GetInboxNumItems() do
    local _, _, sender, subject = GetInboxHeaderInfo(mailIndex)
    local invoiceType = GetInboxInvoiceInfo(mailIndex)

    if IsMailCacheable(sender, subject, invoiceType) then
      local mailData = CreateMailData(mailIndex)
      Dukonomics.Logger.debugTable(mailData, "Mail #" .. mailIndex)
      Dukonomics.MailCacheRepository:Add(mailIndex, mailData)

      -- Process expired mails proactively on inbox scan (no need to take the mail)
      if not invoiceType and IsExpiredSubject(subject) then
        local itemName, quantity = ExtractItemInfo(subject, expiredPattern)
        if itemName then
          local itemLink = GetInboxItemLink(mailIndex, 1)
          local posting = MatchExpiredPosting(itemName, quantity, itemLink)
          if posting then
            Dukonomics.Data.ReducePostingQuantity(posting, quantity, "expired")
            Dukonomics.Logger.debug("Inbox scan - Expired: " .. itemName .. " x" .. quantity)
          end
        end
      end
    end
  end
end

local function OnCloseInboxItem(mailIndex)
  local mail = Dukonomics.MailCacheRepository:Get(mailIndex)
  if not mail then return end

  Dukonomics.Logger.debug("CLOSE_INBOX_ITEM: #" .. mailIndex .. " '" .. tostring(mail.subject) .. "'")

  if mail.invoiceType and mail.itemName then
    if mail.invoiceType == "seller" then
      ProcessSaleMail(mail)
    elseif mail.invoiceType == "buyer" then
      ProcessPurchaseMail(mail)
    end
  elseif mail.subject then
    if IsExpiredSubject(mail.subject) then
      ProcessExpiredMail(mail)
    elseif IsCancelledSubject(mail.subject) then
      ProcessCancelledMail(mail)
    end
  end
end

-----------------------------------------------------------
-- Initialization
-----------------------------------------------------------

function Dukonomics.MailHandler.Initialize()
  Dukonomics.Logger.debug("Initializing MailHandler")

  local mailFrame = CreateFrame("Frame")
  mailFrame:RegisterEvent("MAIL_INBOX_UPDATE")
  mailFrame:RegisterEvent("CLOSE_INBOX_ITEM")

  mailFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MAIL_INBOX_UPDATE" then
      OnMailInboxUpdate()
    elseif event == "CLOSE_INBOX_ITEM" then
      OnCloseInboxItem(...)
    end
  end)

  Dukonomics.Logger.debug("MailHandler initialized")
end

-- Backward compatibility alias
Dukonomics.Mail = { Initialize = Dukonomics.MailHandler.Initialize }
