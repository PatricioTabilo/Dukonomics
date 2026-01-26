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
  -- Add metadata
  posting.source = GetPlayerSource()
  posting.timestamp = time()

  -- Generate temporary ID until we get the real auctionID
  posting.tempID = posting.timestamp .. "_" .. posting.source.character

  table.insert(DUKONOMICS_DATA.postings, posting)

  Dukonomics.Debug("Added posting: " .. (posting.itemName or "unknown") .. " x" .. (posting.count or 0))
end

-- Update posting by auctionID
function Dukonomics.Data.UpdatePostingByAuctionID(auctionID, updates)
  for _, posting in ipairs(DUKONOMICS_DATA.postings) do
    if posting.auctionID == auctionID then
      for key, value in pairs(updates) do
        posting[key] = value
      end
      Dukonomics.Debug("Updated posting auctionID " .. auctionID .. ": status=" .. (updates.status or "?"))
      return true
    end
  end
  return false
end

-- Update posting by tempID (for when we don't have auctionID yet)
function Dukonomics.Data.UpdatePostingByTempID(tempID, updates)
  for _, posting in ipairs(DUKONOMICS_DATA.postings) do
    if posting.tempID == tempID then
      for key, value in pairs(updates) do
        posting[key] = value
      end
      Dukonomics.Debug("Updated posting tempID " .. tempID)
      return true
    end
  end
  return false
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
