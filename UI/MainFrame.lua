-- Dukonomics: Main UI Frame
-- Frame principal que orquesta los componentes

local COLOR = Dukonomics.UI.Config.COLORS
local SIZES = Dukonomics.UI.Config.SIZES

-----------------------------------------------------------
-- Main Frame
-----------------------------------------------------------

-- Forward declarations
local frame
local filterBar, summaryBar, dataTable

function Dukonomics.UI.Initialize()

frame = CreateFrame("Frame", "DukonomicsMainFrame", UIParent, "BackdropTemplate")
frame:SetSize(SIZES.FRAME_WIDTH, SIZES.FRAME_HEIGHT)
frame:SetPoint("CENTER")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("HIGH")
frame:Hide()

-- Close with ESC key
tinsert(UISpecialFrames, "DukonomicsMainFrame")

-- Also handle ESC directly
frame:SetScript("OnKeyDown", function(self, key)
  if key == "ESCAPE" then
    self:Hide()
  end
end)

-- Main backdrop
frame:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8x8",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  edgeSize = 16,
  insets = {left = 4, right = 4, top = 4, bottom = 4},
})
frame:SetBackdropColor(unpack(COLOR.BG))
frame:SetBackdropBorderColor(unpack(COLOR.BORDER))

-----------------------------------------------------------
-- Title Bar
-----------------------------------------------------------

local titleBar = CreateFrame("Frame", nil, frame, "BackdropTemplate")
titleBar:SetHeight(SIZES.TITLE_HEIGHT)
titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
titleBar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
titleBar:SetBackdropColor(unpack(COLOR.TITLE_BG))

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
titleText:SetPoint("CENTER", titleBar, "CENTER", 0, 0)
titleText:SetText("Dukonomics")
titleText:SetTextColor(unpack(COLOR.GOLD))

-- Close button
local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeBtn:SetSize(32, 32)
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)

-- Options button (Gear icon)
local optionsBtn = CreateFrame("Button", nil, frame)
optionsBtn:SetSize(20, 20)
optionsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
optionsBtn:SetNormalTexture("Interface\\WorldMap\\Gear_64")
optionsBtn:GetNormalTexture():SetTexCoord(0, 0.5, 0, 0.5) -- Use top-left part of the texture
optionsBtn:GetNormalTexture():SetVertexColor(1, 0.82, 0) -- Gold color to match WoW UI
optionsBtn:SetPushedTexture("Interface\\WorldMap\\Gear_64")
optionsBtn:GetPushedTexture():SetTexCoord(0, 0.5, 0, 0.5)
optionsBtn:GetPushedTexture():SetVertexColor(0.8, 0.6, 0) -- Darker gold when pushed
optionsBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
optionsBtn:GetHighlightTexture():SetTexCoord(0.2, 0.8, 0.2, 0.8) -- Adjust highlight size
optionsBtn:SetScript("OnClick", function()
  if Dukonomics.Options and Dukonomics.Options.Open then
    Dukonomics.Options.Open()
  end
end)
optionsBtn:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetText("Options", 1, 1, 1)
  GameTooltip:Show()
end)
optionsBtn:SetScript("OnLeave", function(self)
  GameTooltip:Hide()
end)

-----------------------------------------------------------
-- Components
-----------------------------------------------------------

-- Filter Bar (increased height for filter pills)
local filterBarAnchor = CreateFrame("Frame", nil, frame)
filterBarAnchor:SetHeight(SIZES.FILTER_HEIGHT + 24)
filterBarAnchor:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -4)
filterBarAnchor:SetPoint("TOPRIGHT", titleBar, "BOTTOMRIGHT", 0, -4)

filterBar = Dukonomics.UI.FilterBar.Create(filterBarAnchor, function()
  if frame.UpdateDisplay then
    frame:UpdateDisplay()
  end
end)

-- Summary Bar (at bottom)
summaryBar = Dukonomics.UI.SummaryBar.Create(frame)

-- Data Table (between filters and summary)
local tableAnchor = CreateFrame("Frame", nil, frame)
tableAnchor:SetPoint("TOPLEFT", filterBarAnchor, "BOTTOMLEFT", 0, -4)
tableAnchor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 42)

dataTable = Dukonomics.UI.DataTable.Create(tableAnchor)

-----------------------------------------------------------
-- Data Logic
-----------------------------------------------------------

local function GetFilteredData()
  local data = {}
  local dataStore = Dukonomics.Data.GetDataStore()
  if not dataStore then
    return data
  end

  local searchText = filterBar:GetSearchText()
  local filters = filterBar:GetFilters()
  local filtered = {}

  -- Calculate time cutoff
  local now = time()
  local timeCutoff = 0
  if filters.timeRange == "24h" then
    timeCutoff = now - (24 * 3600)
  elseif filters.timeRange == "7d" then
    timeCutoff = now - (7 * 24 * 3600)
  elseif filters.timeRange == "30d" then
    timeCutoff = now - (30 * 24 * 3600)
  end

  -- First pass: filter by search, type, time, status, character
  -- Add postings (sales)
  if (filters.type == "all" or filters.type == "sales") then
    local dataStore = Dukonomics.Data.GetDataStore()
    if dataStore.postings then
      for _, posting in ipairs(dataStore.postings) do
        local match = true

        -- Search filter
        if searchText ~= "" then
          local itemName = (posting.itemName or ""):lower()
          if not itemName:find(searchText, 1, true) then
            match = false
          end
        end

        -- Time filter
        if match and filters.timeRange ~= "all" then
          if (posting.timestamp or 0) < timeCutoff then
            match = false
          end
        end

        -- Status filter
        if match and filters.status ~= "all" then
          local isPendingCancel = posting.pendingRemovalType == "cancelled"
          if filters.status == "cancelled" then
            if posting.status ~= "cancelled" and not isPendingCancel then
              match = false
            end
          elseif filters.status == "active" then
            if posting.status ~= "active" or isPendingCancel then
              match = false
            end
          else
            if posting.status ~= filters.status then
              match = false
            end
          end
        end

        -- Character filter (format: "Character-Realm")
        if match then
          -- Check if list is not empty (empty means ALL allowed)
          if filters.characters and #filters.characters > 0 then
             if not posting.source then
               match = false
             else
               local charKey = posting.source.character .. "-" .. posting.source.realm
               local found = false
               for _, allowedKey in ipairs(filters.characters) do
                 if charKey == allowedKey then
                   found = true
                   break
                 end
               end
               if not found then match = false end
             end
          end
        end

        if match then
          -- Add type marker
          local item = {}
          for k, v in pairs(posting) do
            item[k] = v
          end
          item._type = "sale"
          table.insert(filtered, item)
        end
      end
    end
  end

  -- Add purchases
  if (filters.type == "all" or filters.type == "purchases") then
    local dataStore = Dukonomics.Data.GetDataStore()
    if dataStore.purchases then
      for _, purchase in ipairs(dataStore.purchases) do
        local match = true

        -- Search filter
        if searchText ~= "" then
          local itemName = (purchase.itemName or ""):lower()
          if not itemName:find(searchText, 1, true) then
            match = false
          end
        end

        -- Time filter
        if match and filters.timeRange ~= "all" then
          if (purchase.timestamp or 0) < timeCutoff then
            match = false
          end
        end

        -- Status filter (purchases always have status "purchased")
        if match and filters.status ~= "all" then
          if filters.status ~= "purchased" then
            match = false
          end
        end

        -- Character filter (format: "Character-Realm")
        if match then
          -- Check if list is not empty (empty means ALL allowed)
          if filters.characters and #filters.characters > 0 then
             if not purchase.source then
               match = false
             else
               local charKey = purchase.source.character .. "-" .. purchase.source.realm
               local found = false
               for _, allowedKey in ipairs(filters.characters) do
                 if charKey == allowedKey then
                   found = true
                   break
                 end
               end
               if not found then match = false end
             end
          end
        end

        if match then
          -- Add type marker and normalize structure
          local item = {}
          for k, v in pairs(purchase) do
            item[k] = v
          end
          item._type = "purchase"
          item.status = "purchased"  -- Add status for purchases
          table.insert(filtered, item)
        end
      end
    end
  end

  -- Sort by timestamp descending (newest first)
  table.sort(filtered, function(a, b)
    return (a.timestamp or 0) > (b.timestamp or 0)
  end)

  -- No need to group anymore - postings already have correct counts
  data = filtered

  return data
end

function frame:UpdateDisplay()
  local data = GetFilteredData()
  dataTable:Render(data)
  summaryBar:Update(data)
end

frame:SetScript("OnShow", function(self)
  self:UpdateDisplay()
end)

Dukonomics.MainFrame = frame
Dukonomics.Logger.debug("UI Initialized")
end

local function LogFilterCacheState()
  local cacheEnabled = Dukonomics.ConfigRepository.IsCacheFiltersEnabled()
  local cached = Dukonomics.ConfigRepository.GetCachedFilters()
  local current = filterBar:GetFilters()

  Dukonomics.Logger.debug("Filter cache enabled: " .. tostring(cacheEnabled))
  Dukonomics.Logger.debug("Cached filters: type=" .. tostring(cached.type) .. ", timeRange=" .. tostring(cached.timeRange) .. ", status=" .. tostring(cached.status))
  Dukonomics.Logger.debug("Active filters: type=" .. tostring(current.type) .. ", timeRange=" .. tostring(current.timeRange) .. ", status=" .. tostring(current.status))
end

-----------------------------------------------------------
-- Public API
-----------------------------------------------------------

Dukonomics.UI = Dukonomics.UI or {}

function Dukonomics.UI.Show()
  LogFilterCacheState()
  frame:Show()
end

function Dukonomics.UI.Hide()
  frame:Hide()
end

function Dukonomics.UI.Toggle()
  if not frame then return end
  if frame:IsShown() then
    frame:Hide()
  else
    LogFilterCacheState()
    frame:Show()
  end
end

function Dukonomics.UI.Refresh()
  if frame and frame:IsShown() then
    frame:UpdateDisplay()
  end
end
