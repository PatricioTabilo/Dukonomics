-- Dukonomics: FilterBar Component
-- Search box + Type/Time/Status/Character filters

Dukonomics.UI = Dukonomics.UI or {}
Dukonomics.UI.FilterBar = {}

local COLOR = Dukonomics.UI.Config.COLORS
local SIZES = Dukonomics.UI.Config.SIZES

-----------------------------------------------------------
-- FilterBar Constructor
-----------------------------------------------------------

function Dukonomics.UI.FilterBar.Create(parent, onFilterChange)
  local self = {}

  -- Filter state (load from cache if enabled)
  local filters = {
    type = "all",       -- all, sales, purchases
    timeRange = "all",  -- all, 24h, 7d, 30d
    status = "all",     -- all, active, sold, cancelled, expired, purchased
    character = "all"   -- all, or character name
  }

  -- Load cached filters if option is enabled
  local cacheEnabled = Dukonomics.ConfigRepository.IsCacheFiltersEnabled()
  Dukonomics.Logger.print("[Dukonomics] Filter cache enabled: " .. tostring(cacheEnabled))
  if cacheEnabled then
    local cached = Dukonomics.ConfigRepository.GetCachedFilters()
    Dukonomics.Logger.print("[Dukonomics] Cached filters loaded: type=" .. tostring(cached.type) .. ", timeRange=" .. tostring(cached.timeRange) .. ", status=" .. tostring(cached.status) .. ", character=" .. tostring(cached.character))
    filters.type = cached.type or filters.type
    filters.timeRange = cached.timeRange or filters.timeRange
    filters.status = cached.status or filters.status
    filters.character = cached.character or filters.character
  end

  -- Main container (increased height for filter pills)
  local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  container:SetHeight(SIZES.FILTER_HEIGHT + 24)
  container:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  container:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
  container:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
  container:SetBackdropColor(unpack(COLOR.FILTER_BG))

  -- Active filters container (pills showing what's filtered)
  local activePills = {}
  local pillContainer = CreateFrame("Frame", nil, container)
  pillContainer:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 12, 2)
  pillContainer:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -12, 2)
  pillContainer:SetHeight(18)

  -- Forward declaration
  local UpdateFilterPills

  -- Save filters to cache if enabled
  local function SaveFilters()
    if Dukonomics.ConfigRepository.IsCacheFiltersEnabled() then
      Dukonomics.ConfigRepository.SetCachedFilters({
        type = filters.type,
        timeRange = filters.timeRange,
        status = filters.status,
        character = filters.character
      })
    end
  end

  -----------------------------------------------------------
  -- Search box
  -----------------------------------------------------------

  local searchIcon = container:CreateTexture(nil, "ARTWORK")
  searchIcon:SetSize(18, 18)
  searchIcon:SetPoint("LEFT", container, "LEFT", 12, 8)
  searchIcon:SetTexture("Interface\\Common\\UI-Searchbox-Icon")

  local searchBox = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
  searchBox:SetSize(160, 20)
  searchBox:SetPoint("LEFT", searchIcon, "RIGHT", 8, 0)
  searchBox:SetAutoFocus(false)
  searchBox:SetScript("OnTextChanged", function()
    if onFilterChange then
      onFilterChange()
    end
  end)
  searchBox:SetScript("OnEscapePressed", function(sb) sb:ClearFocus() end)

  -----------------------------------------------------------
  -- Helper: Create dropdown menu
  -----------------------------------------------------------

  local function CreateDropdownMenu(items, onSelect)
    local menu = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
    menu:SetFrameStrata("DIALOG")
    menu:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 12,
      insets = {left = 2, right = 2, top = 2, bottom = 2},
    })
    menu:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
    menu:SetBackdropBorderColor(0.6, 0.5, 0.35, 1)
    menu:Hide()

    local buttons = {}
    local yOffset = -4

    for i, item in ipairs(items) do
      local btn = CreateFrame("Button", nil, menu, "BackdropTemplate")
      btn:SetSize(140, 20)
      btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, yOffset)

      local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      text:SetPoint("LEFT", btn, "LEFT", 8, 0)
      text:SetText(item.label)

      btn:SetScript("OnEnter", function()
        btn:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
        btn:SetBackdropColor(0.25, 0.25, 0.3, 1)
      end)

      btn:SetScript("OnLeave", function()
        btn:SetBackdrop(nil)
      end)

      btn:SetScript("OnClick", function()
        if onSelect then
          onSelect(item.value)
        end
        menu:Hide()
      end)

      table.insert(buttons, btn)
      yOffset = yOffset - 22
    end

    menu:SetSize(148, math.abs(yOffset) + 4)
    return menu
  end

  -----------------------------------------------------------
  -- Type filter dropdown (replaces tabs)
  -----------------------------------------------------------

  local typeFilterBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
  typeFilterBtn:SetSize(110, 22)
  typeFilterBtn:SetPoint("LEFT", searchBox, "RIGHT", 15, 0)
  typeFilterBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  typeFilterBtn:SetBackdropColor(unpack(COLOR.BUTTON_BG))
  typeFilterBtn:SetBackdropBorderColor(unpack(COLOR.BUTTON_BORDER))

  local typeFilterText = typeFilterBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  typeFilterText:SetPoint("LEFT", typeFilterBtn, "LEFT", 8, 0)
  typeFilterText:SetText("All")

  local typeFilterArrow = typeFilterBtn:CreateTexture(nil, "ARTWORK")
  typeFilterArrow:SetSize(12, 12)
  typeFilterArrow:SetPoint("RIGHT", typeFilterBtn, "RIGHT", -5, 0)
  typeFilterArrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
  typeFilterArrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)

  -----------------------------------------------------------
  -- Time filter dropdown
  -----------------------------------------------------------

  local timeFilterBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
  timeFilterBtn:SetSize(120, 22)
  timeFilterBtn:SetPoint("LEFT", typeFilterBtn, "RIGHT", 8, 0)
  timeFilterBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  timeFilterBtn:SetBackdropColor(unpack(COLOR.BUTTON_BG))
  timeFilterBtn:SetBackdropBorderColor(unpack(COLOR.BUTTON_BORDER))

  local timeFilterText = timeFilterBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  timeFilterText:SetPoint("LEFT", timeFilterBtn, "LEFT", 8, 0)
  timeFilterText:SetText("All Time")

  local timeFilterArrow = timeFilterBtn:CreateTexture(nil, "ARTWORK")
  timeFilterArrow:SetSize(12, 12)
  timeFilterArrow:SetPoint("RIGHT", timeFilterBtn, "RIGHT", -5, 0)
  timeFilterArrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
  timeFilterArrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)

  local timeMenu = CreateDropdownMenu({
    {label = "All Time", value = "all"},
    {label = "Last 24 Hours", value = "24h"},
    {label = "Last 7 Days", value = "7d"},
    {label = "Last 30 Days", value = "30d"},
  }, function(value)
    filters.timeRange = value
    local labels = {all = "All Time", ["24h"] = "Last 24h", ["7d"] = "Last 7d", ["30d"] = "Last 30d"}
    timeFilterText:SetText(labels[value])
    SaveFilters()
    UpdateFilterPills()
    if onFilterChange then onFilterChange() end
  end)

  timeFilterBtn:SetScript("OnClick", function(btn)
    if timeMenu:IsShown() then
      timeMenu:Hide()
    else
      timeMenu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
      timeMenu:Show()
    end
  end)

  -----------------------------------------------------------
  -- Status filter dropdown
  -----------------------------------------------------------

  local statusFilterBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
  statusFilterBtn:SetSize(110, 22)
  statusFilterBtn:SetPoint("LEFT", timeFilterBtn, "RIGHT", 8, 0)
  statusFilterBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  statusFilterBtn:SetBackdropColor(unpack(COLOR.BUTTON_BG))
  statusFilterBtn:SetBackdropBorderColor(unpack(COLOR.BUTTON_BORDER))

  local statusFilterText = statusFilterBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  statusFilterText:SetPoint("LEFT", statusFilterBtn, "LEFT", 8, 0)
  statusFilterText:SetText("All Status")

  local statusFilterArrow = statusFilterBtn:CreateTexture(nil, "ARTWORK")
  statusFilterArrow:SetSize(12, 12)
  statusFilterArrow:SetPoint("RIGHT", statusFilterBtn, "RIGHT", -5, 0)
  statusFilterArrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
  statusFilterArrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)

  local statusMenu = nil
  local statusMenuOpen = false

  local function UpdateStatusMenu()
    -- Build menu based on type filter
    local items = {{label = "All Status", value = "all"}}

    if filters.type == "all" or filters.type == "sales" then
      table.insert(items, {label = "Active", value = "active"})
      table.insert(items, {label = "Sold", value = "sold"})
      table.insert(items, {label = "Cancelled", value = "cancelled"})
      table.insert(items, {label = "Expired", value = "expired"})
    end

    if filters.type == "all" or filters.type == "purchases" then
      table.insert(items, {label = "Purchased", value = "purchased"})
    end

    -- Recreate menu
    if statusMenu then
      statusMenu:Hide()
      statusMenu = nil
    end

    statusMenu = CreateDropdownMenu(items, function(value)
      filters.status = value
      local labels = {
        all = "All Status",
        active = "Active",
        sold = "Sold",
        cancelled = "Cancelled",
        expired = "Expired",
        purchased = "Purchased"
      }
      statusFilterText:SetText(labels[value])
      statusMenuOpen = false
      SaveFilters()
      UpdateFilterPills()
      if onFilterChange then onFilterChange() end
    end)
  end

  statusFilterBtn:SetScript("OnClick", function(btn)
    if statusMenuOpen then
      if statusMenu then
        statusMenu:Hide()
      end
      statusMenuOpen = false
    else
      UpdateStatusMenu()
      statusMenu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
      statusMenu:Show()
      statusMenuOpen = true
    end
  end)

  -----------------------------------------------------------
  -- Setup Type Menu (after status filter is created)
  -----------------------------------------------------------

  local typeMenu = CreateDropdownMenu({
    {label = "All", value = "all"},
    {label = "Sales", value = "sales"},
    {label = "Purchases", value = "purchases"},
  }, function(value)
    filters.type = value
    local labels = {all = "All", sales = "Sales", purchases = "Purchases"}
    typeFilterText:SetText(labels[value])

    -- Auto-adjust status filter when selecting purchases
    if value == "purchases" then
      filters.status = "purchased"
      statusFilterText:SetText("Purchased")
      -- Disable status dropdown
      statusFilterBtn:Disable()
      statusFilterBtn:SetAlpha(0.5)
    else
      -- Enable status dropdown
      statusFilterBtn:Enable()
      statusFilterBtn:SetAlpha(1.0)
      if filters.status == "purchased" then
        filters.status = "all"
        statusFilterText:SetText("All Status")
      end
    end

    SaveFilters()
    UpdateFilterPills()
    if onFilterChange then onFilterChange() end
  end)

  typeFilterBtn:SetScript("OnClick", function(btn)
    if typeMenu:IsShown() then
      typeMenu:Hide()
    else
      typeMenu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
      typeMenu:Show()
    end
  end)

  -----------------------------------------------------------
  -- Character filter dropdown
  -----------------------------------------------------------

  local charFilterBtn = CreateFrame("Button", nil, container, "BackdropTemplate")
  charFilterBtn:SetSize(130, 22)
  charFilterBtn:SetPoint("LEFT", statusFilterBtn, "RIGHT", 8, 0)
  charFilterBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
  })
  charFilterBtn:SetBackdropColor(unpack(COLOR.BUTTON_BG))
  charFilterBtn:SetBackdropBorderColor(unpack(COLOR.BUTTON_BORDER))

  local charFilterText = charFilterBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  charFilterText:SetPoint("LEFT", charFilterBtn, "LEFT", 8, 0)
  charFilterText:SetText("All Characters")

  local charFilterArrow = charFilterBtn:CreateTexture(nil, "ARTWORK")
  charFilterArrow:SetSize(12, 12)
  charFilterArrow:SetPoint("RIGHT", charFilterBtn, "RIGHT", -5, 0)
  charFilterArrow:SetTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up")
  charFilterArrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)

  local charMenu = nil
  local charMenuOpen = false

  local function UpdateCharacterMenu()
    -- Get unique characters from data
    local chars = Dukonomics.Data.GetCharacters()
    local items = {{label = "All Characters", value = "all"}}

    for _, char in ipairs(chars) do
      local displayName = char.character .. " - " .. char.realm
      table.insert(items, {label = displayName, value = char.key})
    end

    -- Recreate menu
    if charMenu then
      charMenu:Hide()
      charMenu = nil
    end

    charMenu = CreateDropdownMenu(items, function(value)
      filters.character = value

      -- Update display text
      if value == "all" then
        charFilterText:SetText("All Characters")
      else
        -- Find the character to get display name
        for _, char in ipairs(chars) do
          if char.key == value then
            charFilterText:SetText(char.character .. " - " .. char.realm)
            break
          end
        end
      end

      charMenuOpen = false
      SaveFilters()
      UpdateFilterPills()
      if onFilterChange then onFilterChange() end
    end)
  end

  charFilterBtn:SetScript("OnClick", function(btn)
    if charMenuOpen then
      if charMenu then
        charMenu:Hide()
      end
      charMenuOpen = false
    else
      UpdateCharacterMenu()
      charMenu:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)
      charMenu:Show()
      charMenuOpen = true
    end
  end)

  -----------------------------------------------------------
  -- Active Filter Pills (visual indicators)
  -----------------------------------------------------------

  local function CreateFilterPill(text, onRemove)
    local pill = CreateFrame("Frame", nil, pillContainer, "BackdropTemplate")
    pill:SetHeight(18)
    pill:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 8,
      insets = {left = 1, right = 1, top = 1, bottom = 1},
    })
    pill:SetBackdropColor(0.2, 0.15, 0.1, 0.9)
    pill:SetBackdropBorderColor(0.6, 0.5, 0.35, 1)

    local label = pill:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", pill, "LEFT", 6, 0)
    label:SetText(text)
    label:SetTextColor(0.9, 0.85, 0.7, 1)

    -- Close button
    local closeBtn = CreateFrame("Button", nil, pill)
    closeBtn:SetSize(14, 14)
    closeBtn:SetPoint("LEFT", label, "RIGHT", 4, 0)

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    closeText:SetPoint("CENTER")
    closeText:SetText("|cffff5555×|r")

    closeBtn:SetScript("OnClick", onRemove)
    closeBtn:SetScript("OnEnter", function(btn)
      closeText:SetText("|cffff0000×|r")
    end)
    closeBtn:SetScript("OnLeave", function(btn)
      closeText:SetText("|cffff5555×|r")
    end)

    -- Calculate width based on text
    local textWidth = label:GetStringWidth()
    pill:SetWidth(textWidth + 28)

    return pill
  end

  UpdateFilterPills = function()
    -- Clear existing pills
    for _, pill in ipairs(activePills) do
      pill:Hide()
      pill:SetParent(nil)
    end
    activePills = {}

    local xOffset = 0
    local hasActiveFilters = false

    -- Type filter
    if filters.type ~= "all" then
      hasActiveFilters = true
      local labels = {sales = "Sales", purchases = "Purchases"}
      local pill = CreateFilterPill("Type: " .. labels[filters.type], function()
        filters.type = "all"
        typeFilterText:SetText("All")
        -- Re-enable status if it was disabled
        if not statusFilterBtn:IsEnabled() then
          statusFilterBtn:Enable()
          statusFilterBtn:SetAlpha(1.0)
          filters.status = "all"
          statusFilterText:SetText("All Status")
        end
        SaveFilters()
        UpdateFilterPills()
        if onFilterChange then onFilterChange() end
      end)
      pill:SetPoint("LEFT", pillContainer, "LEFT", xOffset, 0)
      table.insert(activePills, pill)
      xOffset = xOffset + pill:GetWidth() + 4
    end

    -- Time filter
    if filters.timeRange ~= "all" then
      hasActiveFilters = true
      local labels = {["24h"] = "24 Hours", ["7d"] = "7 Days", ["30d"] = "30 Days"}
      local pill = CreateFilterPill("Time: " .. labels[filters.timeRange], function()
        filters.timeRange = "all"
        timeFilterText:SetText("All Time")
        SaveFilters()
        UpdateFilterPills()
        if onFilterChange then onFilterChange() end
      end)
      pill:SetPoint("LEFT", pillContainer, "LEFT", xOffset, 0)
      table.insert(activePills, pill)
      xOffset = xOffset + pill:GetWidth() + 4
    end

    -- Status filter
    if filters.status ~= "all" and filters.type ~= "purchases" then
      hasActiveFilters = true
      local labels = {active = "Active", sold = "Sold", cancelled = "Cancelled", expired = "Expired", purchased = "Purchased"}
      local pill = CreateFilterPill("Status: " .. labels[filters.status], function()
        filters.status = "all"
        statusFilterText:SetText("All Status")
        SaveFilters()
        UpdateFilterPills()
        if onFilterChange then onFilterChange() end
      end)
      pill:SetPoint("LEFT", pillContainer, "LEFT", xOffset, 0)
      table.insert(activePills, pill)
      xOffset = xOffset + pill:GetWidth() + 4
    end

    -- Character filter
    if filters.character ~= "all" then
      hasActiveFilters = true
      -- Get character display name
      local chars = Dukonomics.Data.GetCharacters()
      local displayName = "Character"
      for _, char in ipairs(chars) do
        if char.key == filters.character then
          displayName = char.character
          break
        end
      end

      local pill = CreateFilterPill("Char: " .. displayName, function()
        filters.character = "all"
        charFilterText:SetText("All Characters")
        SaveFilters()
        UpdateFilterPills()
        if onFilterChange then onFilterChange() end
      end)
      pill:SetPoint("LEFT", pillContainer, "LEFT", xOffset, 0)
      table.insert(activePills, pill)
      xOffset = xOffset + pill:GetWidth() + 4
    end

    -- Show/hide pill container based on active filters
    if hasActiveFilters then
      pillContainer:Show()
    else
      pillContainer:Hide()
    end
  end

  -----------------------------------------------------------
  -- Public API
  -----------------------------------------------------------

  function self:GetSearchText()
    return (searchBox:GetText() or ""):lower()
  end

  function self:GetFilters()
    return filters
  end

  function self:UpdatePills()
    UpdateFilterPills()
  end

  -- Initialize pills (hidden by default)
  pillContainer:Hide()

  -- Update UI to reflect loaded filters
  if Dukonomics.ConfigRepository.IsCacheFiltersEnabled() then
    local cached = Dukonomics.ConfigRepository.GetCachedFilters()

    -- Sync internal filters with cache (defensive)
    filters.type = cached.type or filters.type
    filters.timeRange = cached.timeRange or filters.timeRange
    filters.status = cached.status or filters.status
    filters.character = cached.character or filters.character

    -- Update button texts
    if cached.type and cached.type ~= "all" then
      local labels = {sales = "Sales", purchases = "Purchases"}
      typeFilterText:SetText(labels[cached.type] or "All")
    end

    if cached.timeRange and cached.timeRange ~= "all" then
      local labels = {["24h"] = "Last 24h", ["7d"] = "Last 7d", ["30d"] = "Last 30d"}
      timeFilterText:SetText(labels[cached.timeRange] or "All Time")
    end

    if cached.status and cached.status ~= "all" then
      local labels = {active = "Active", sold = "Sold", cancelled = "Cancelled", expired = "Expired", purchased = "Purchased"}
      statusFilterText:SetText(labels[cached.status] or "All Status")
    end

    if cached.character and cached.character ~= "all" then
      local chars = Dukonomics.Data.GetCharacters()
      for _, char in ipairs(chars) do
        if char.key == cached.character then
          charFilterText:SetText(char.character .. " - " .. char.realm)
          break
        end
      end
    end

    -- Keep status dropdown consistent with cached type
    if filters.type == "purchases" then
      filters.status = "purchased"
      statusFilterText:SetText("Purchased")
      statusFilterBtn:Disable()
      statusFilterBtn:SetAlpha(0.5)
    else
      statusFilterBtn:Enable()
      statusFilterBtn:SetAlpha(1.0)
      if filters.status == "purchased" then
        filters.status = "all"
        statusFilterText:SetText("All Status")
      end
    end

    UpdateFilterPills()
    if onFilterChange then
      onFilterChange()
    end
  end

  self.frame = container
  self.searchBox = searchBox
  return self
end
