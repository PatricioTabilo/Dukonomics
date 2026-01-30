-- Dukonomics: Auction House accounting and tracking
-- Core initialization

-- Create addon namespace
Dukonomics = {}
Dukonomics.Version = "0.1.0"

-- Initialize addon
function Dukonomics.Initialize()
  -- Initialize data storage first
  Dukonomics.Data.Initialize()

  -- Now DUKONOMICS_DATA is available, set debug mode
  Dukonomics.DebugMode = DUKONOMICS_DATA.debugMode or false

  Dukonomics.Logger.print("v" .. Dukonomics.Version .. " loaded")

  -- Register event handlers
  Dukonomics.Events.Initialize()
  Dukonomics.Mail.Initialize()

  Dukonomics.Logger.print("Initialization complete")
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
