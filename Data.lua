-- Dukonomics: Data persistence and storage

Dukonomics.Data = {}

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
    Dukonomics.Debug("Created new DUKONOMICS_DATA")
  else
    Dukonomics.Debug("Loaded existing DUKONOMICS_DATA with " .. #DUKONOMICS_DATA.postings .. " postings")
  end
end

-- Add posting to logs
function Dukonomics.Data.AddPosting(posting)
  posting.source = GetPlayerSource()
  table.insert(DUKONOMICS_DATA.postings, posting)
  Dukonomics.Debug("Posting saved: " .. (posting.itemName or "?") .. " x" .. posting.count)
end

-- Add purchase to logs
function Dukonomics.Data.AddPurchase(purchase)
  purchase.source = GetPlayerSource()
  table.insert(DUKONOMICS_DATA.purchases, purchase)
  Dukonomics.Debug("Purchase saved: " .. (purchase.itemName or "?") .. " x" .. purchase.count)
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

-- Mark posting as sold (by synthetic ID or auctionID)
function Dukonomics.Data.MarkPostingAsSold(posting, soldPrice)
  posting.status = "sold"
  posting.soldAt = time()
  posting.soldPrice = soldPrice or posting.price

  -- Calculate profit
  local revenue = posting.soldPrice
  local cost = posting.deposit
  posting.profit = revenue - cost

  Dukonomics.Debug("Marked as sold: " .. (posting.itemName or "?") .. " - Profit: " .. posting.profit .. "g")
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

-- Get all unique characters
function Dukonomics.Data.GetCharacters()
  local chars = {}
  local seen = {}

  for _, posting in ipairs(DUKONOMICS_DATA.postings) do
    local charName = posting.source.character
    if charName and not seen[charName] then
      seen[charName] = true
      table.insert(chars, charName)
    end
  end

  table.sort(chars)
  return chars
end

-- Clear old data (optional, for maintenance)
function Dukonomics.Data.ClearOldData(daysToKeep)
  local cutoff = time() - (daysToKeep * 24 * 60 * 60)
  local removed = 0

  for i = #DUKONOMICS_DATA.postings, 1, -1 do
    if DUKONOMICS_DATA.postings[i].timestamp < cutoff then
      table.remove(DUKONOMICS_DATA.postings, i)
      removed = removed + 1
    end
  end

  if removed > 0 then
    Dukonomics.Print("Removed " .. removed .. " old postings (older than " .. daysToKeep .. " days)")
  end
end
