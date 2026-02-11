-- Dukonomics: Auction House accounting and tracking

-- Dukonomics is the main addon table
Dukonomics = {}

function Dukonomics.Initialize()
  Dukonomics.Data.Initialize()
  Dukonomics.ConfigRepository.Initialize()

  -- Initialize options
  Dukonomics.Options.Initialize()

  -- Initialize Main UI (Deferred until config is ready)
  if Dukonomics.UI and Dukonomics.UI.Initialize then
    Dukonomics.UI.Initialize()
  end

  -- Initialize Minimap Button
  if Dukonomics.UI.MinimapButton and Dukonomics.UI.MinimapButton.Initialize then
     Dukonomics.UI.MinimapButton.Initialize()
  end

  -- Load debug mode from config repository
  Dukonomics.DebugMode = Dukonomics.ConfigRepository.IsDebugModeEnabled()

  -- Show welcome message if enabled
  if Dukonomics.ConfigRepository.IsWelcomeMessageEnabled() then
    -- Get version from TOC file (C_AddOns.GetAddOnMetadata for modern WoW, fallback to old API)
    local version = (C_AddOns and C_AddOns.GetAddOnMetadata("Dukonomics", "Version")) or GetAddOnMetadata and GetAddOnMetadata("Dukonomics", "Version") or "0.9.0"
    Dukonomics.Logger.print("made with <3 thanks for using it! (v" .. version .. ")")
  end

  Dukonomics.AuctionHandler.Initialize()
  Dukonomics.MailHandler.Initialize()

  -- Dukonomics.Logger.debug("Initialization complete") -- Removed debug log
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addonName)
  if addonName == "Dukonomics" then
    Dukonomics.Initialize()
    frame:UnregisterEvent("ADDON_LOADED")
  end
end)
