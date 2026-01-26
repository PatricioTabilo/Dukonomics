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
  else
    -- TODO: Open main UI
    Dukonomics.Print("UI coming soon! Use /duk debug to toggle debug mode")
  end
end
