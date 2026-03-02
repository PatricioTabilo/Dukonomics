-- Dukonomics: Options Panel for Blizzard Interface Options

Dukonomics.Options = {}

StaticPopupDialogs["DUKONOMICS_WIPE_DATA"] = {
    text = "Are you sure you want to wipe ALL Dukonomics data?\n\nThis will delete all postings, purchases, and sales history.\nThis action cannot be undone.",
    button1 = "Wipe All Data",
    button2 = "Cancel",
    OnAccept = function()
        DUKONOMICS_DATA = { postings = {}, purchases = {}, config = { debug = false } }
        DUKONOMICS_DEBUG_DATA = { postings = {}, purchases = {}, config = { debug = true } }
        if Dukonomics.UI and Dukonomics.UI.Refresh then
            Dukonomics.UI.Refresh()
        end
        Dukonomics.Logger.print("|cffff6600All data has been wiped.|r")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    showAlert = true,
    preferredIndex = 3,
}

local function CreateOptionsPanel()
    -- Create main panel
    local panel = CreateFrame("Frame", "DukonomicsOptionsPanel", InterfaceOptionsFramePanelContainer)
    panel.name = "Dukonomics"

    -- Title
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Dukonomics Options")

    -- Subtitle
    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    subtitle:SetText("Configure your auction house tracking experience")

    -- Welcome Message Option
    local welcomeCheck = CreateFrame("CheckButton", "DukonomicsWelcomeCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    welcomeCheck:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -20)
    welcomeCheck.Text:SetText("Show welcome message on addon load")
    welcomeCheck.tooltipText = "Display a greeting message when Dukonomics loads"

    -- Cache Filters Option
    local cacheCheck = CreateFrame("CheckButton", "DukonomicsCacheCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    cacheCheck:SetPoint("TOPLEFT", welcomeCheck, "BOTTOMLEFT", 0, -10)
    cacheCheck.Text:SetText("Remember filter settings")
    cacheCheck.tooltipText = "Save your filter preferences between sessions"

    -- Info text for cache filters
    local cacheInfo = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    cacheInfo:SetPoint("TOPLEFT", cacheCheck.Text, "BOTTOMLEFT", 0, -5)
    cacheInfo:SetText("|cff888888Filter settings will persist across characters and game sessions|r")
    cacheInfo:SetWidth(400)
    cacheInfo:SetJustifyH("LEFT")

    -- Wipe Data Section
    local dangerTitle = panel:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    dangerTitle:SetPoint("TOPLEFT", cacheInfo, "BOTTOMLEFT", 0, -30)
    dangerTitle:SetText("|cffff3333Danger Zone|r")

    local wipeBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    wipeBtn:SetSize(160, 26)
    wipeBtn:SetPoint("TOPLEFT", dangerTitle, "BOTTOMLEFT", 0, -10)
    wipeBtn:SetText("Wipe All Data")
    wipeBtn:SetScript("OnClick", function()
        StaticPopup_Show("DUKONOMICS_WIPE_DATA")
    end)

    local wipeInfo = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
    wipeInfo:SetPoint("LEFT", wipeBtn, "RIGHT", 10, 0)
    wipeInfo:SetText("|cff888888Permanently deletes all postings, purchases, and sales data|r")

    -- Initialize checkbox states
    local function InitializeOptions()
        welcomeCheck:SetChecked(Dukonomics.ConfigRepository.IsWelcomeMessageEnabled())
        cacheCheck:SetChecked(Dukonomics.ConfigRepository.IsCacheFiltersEnabled())
    end

    -- Apply defaults
    local function ApplyDefaults()
        Dukonomics.ConfigRepository.SetWelcomeMessage(true)
        Dukonomics.ConfigRepository.SetCacheFilters(false)
        InitializeOptions()
    end

    -- Save function
    local function SaveOptions()
        local welcomeEnabled = welcomeCheck:GetChecked() and true or false
        local cacheEnabled = cacheCheck:GetChecked() and true or false

        Dukonomics.ConfigRepository.SetWelcomeMessage(welcomeEnabled)
        Dukonomics.ConfigRepository.SetCacheFilters(cacheEnabled)

        Dukonomics.Logger.debug("Options saved - showWelcome: " .. tostring(welcomeEnabled) .. ", cacheFilters: " .. tostring(cacheEnabled))
    end

    -- Event handlers
    welcomeCheck:SetScript("OnClick", SaveOptions)
    cacheCheck:SetScript("OnClick", SaveOptions)

    -- Panel events
    panel.refresh = InitializeOptions
    panel.okay = SaveOptions
    panel.cancel = InitializeOptions
    panel.default = ApplyDefaults
    panel.OnCommit = SaveOptions
    panel.OnRefresh = InitializeOptions
    panel.OnDefault = ApplyDefaults

    panel:SetScript("OnShow", InitializeOptions)
    InitializeOptions()

    return panel
end

function Dukonomics.Options.Initialize()
    local panel = CreateOptionsPanel()

    -- Register with Blizzard Options (try both old and new API)
    if InterfaceOptions_AddCategory then
        -- Classic/older versions
        InterfaceOptions_AddCategory(panel)
        Dukonomics.Options.Open = function()
            InterfaceOptionsFrame_OpenToCategory(panel)
        end
    elseif Settings and Settings.RegisterCanvasLayoutCategory then
        -- Modern versions (Dragonflight+)
        local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
        Settings.RegisterAddOnCategory(category)
        Dukonomics.Options.Open = function()
            Settings.OpenToCategory(category:GetID())
        end
    end
end
