-- Dukonomics: Auction House accounting and tracking
-- Core initialization

-- Create addon namespace
Dukonomics = {}
Dukonomics.Version = "0.1.0"

-- Print debug messages (must be disabled in production)
local DEBUG = true

function Dukonomics.Print(msg)
  print("|cFF00D4FFDukonomics:|r " .. msg)
end

function Dukonomics.Debug(msg)
  if DEBUG then
    print("|cFF808080[Dukonomics Debug]|r " .. msg)
  end
end

-- Convert copper to readable gold format
function Dukonomics.FormatMoney(copper)
  if not copper or copper == 0 then
    return "0c"
  end

  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper % 10000) / 100)
  local c = copper % 100

  local result = ""
  if gold > 0 then
    result = gold .. "g"
    if silver > 0 then
      result = result .. " " .. silver .. "s"
    end
    if c > 0 then
      result = result .. " " .. c .. "c"
    end
  elseif silver > 0 then
    result = silver .. "s"
    if c > 0 then
      result = result .. " " .. c .. "c"
    end
  else
    result = c .. "c"
  end

  return result
end

-- Initialize addon
function Dukonomics.Initialize()
  Dukonomics.Print("v" .. Dukonomics.Version .. " loaded")

  -- Initialize data storage
  Dukonomics.Data.Initialize()

  -- Register events
  Dukonomics.Events.Initialize()

  Dukonomics.Debug("Initialization complete")
end

-- Create main frame for event handling
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
  if addonName == "Dukonomics" then
    Dukonomics.Initialize()
    frame:UnregisterEvent("ADDON_LOADED")
  end
end)

-- Slash commands
SLASH_DUKONOMICS1 = "/dukonomics"
SLASH_DUKONOMICS2 = "/duk"
SlashCmdList["DUKONOMICS"] = function(msg)
  if msg == "debug" then
    DEBUG = not DEBUG
    Dukonomics.Print("Debug mode: " .. (DEBUG and "ON" or "OFF"))

  elseif msg == "list" then
    -- Show recent postings
    Dukonomics.Print("Recent postings:")
    for i = math.max(1, #DUKONOMICS_DATA.postings - 9), #DUKONOMICS_DATA.postings do
      local p = DUKONOMICS_DATA.postings[i]
      if p then
        Dukonomics.Print(i .. ". [SELL] " .. (p.itemName or "?") .. " x" .. (p.count or 0) .. " @ " .. Dukonomics.FormatMoney(p.price or 0) .. " - " .. (p.status or "?"))
      end
    end

    -- Show recent purchases
    if #DUKONOMICS_DATA.purchases > 0 then
      Dukonomics.Print("\nRecent purchases:")
      for i = math.max(1, #DUKONOMICS_DATA.purchases - 9), #DUKONOMICS_DATA.purchases do
        local p = DUKONOMICS_DATA.purchases[i]
        if p then
          Dukonomics.Print(i .. ". [BUY] " .. (p.itemName or "?") .. " x" .. (p.count or 0) .. " @ " .. Dukonomics.FormatMoney(p.price or 0))
        end
      end
    end

  else
    -- TODO: Open main UI
    Dukonomics.Print("UI coming soon! Use /duk debug to toggle debug mode, /duk list to show postings")
  end
end
