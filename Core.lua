-- Dukonomics: Auction House accounting and tracking

Dukonomics = {}
Dukonomics.Version = "0.1.0"

function Dukonomics.Initialize()
  Dukonomics.Data.Initialize()
  -- Load debug mode from global config
  Dukonomics.DebugMode = DUKONOMICS_CONFIG and DUKONOMICS_CONFIG.debugMode or false

  Dukonomics.Logger.print("v" .. Dukonomics.Version .. " loaded")

  Dukonomics.AuctionHandler.Initialize()
  Dukonomics.MailHandler.Initialize()

  Dukonomics.Logger.print("Initialization complete")
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
  if addonName == "Dukonomics" then
    Dukonomics.Initialize()
    frame:UnregisterEvent("ADDON_LOADED")
  end
end)
