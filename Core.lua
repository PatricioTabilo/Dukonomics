-- Dukonomics: Auction House accounting and tracking

Dukonomics = {}

function Dukonomics.Initialize()
  Dukonomics.Data.Initialize()
  -- Load debug mode from global config
  Dukonomics.DebugMode = DUKONOMICS_CONFIG and DUKONOMICS_CONFIG.debugMode or false

  -- Get version from TOC file (C_AddOns.GetAddOnMetadata for modern WoW, fallback to old API)
  local version = (C_AddOns and C_AddOns.GetAddOnMetadata("Dukonomics", "Version")) or GetAddOnMetadata and GetAddOnMetadata("Dukonomics", "Version") or "0.4.0"
  Dukonomics.Logger.print("v" .. version .. " loaded")

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
