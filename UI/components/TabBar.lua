-- Dukonomics: Tab Bar Component
-- Pestañas para filtrar entre All/Sales/Purchases

local COLOR = Dukonomics.UI.Config.COLORS

Dukonomics.UI = Dukonomics.UI or {}
Dukonomics.UI.TabBar = {}

-----------------------------------------------------------
-- Tab Bar Component
-----------------------------------------------------------

function Dukonomics.UI.TabBar.Create(parent, onTabChange)
  local self = {}

  -- Container for tabs
  local container = CreateFrame("Frame", nil, parent)
  container:SetHeight(32)
  container:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  container:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)

  -- Current active tab
  local activeTab = "all"

  -- Tab buttons
  local tabs = {}

  local function CreateTab(key, label, xOffset)
    local tab = CreateFrame("Button", nil, container, "BackdropTemplate")
    tab:SetSize(100, 28)
    tab:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", xOffset, 0)

    tab:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8x8",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 12,
      insets = {left = 2, right = 2, top = 2, bottom = 2},
    })

    local text = tab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText(label)

    -- Update appearance based on active state
    local function UpdateAppearance()
      if activeTab == key then
        tab:SetBackdropColor(0.2, 0.3, 0.4, 1.0)
        tab:SetBackdropBorderColor(unpack(COLOR.GOLD))
        text:SetTextColor(unpack(COLOR.GOLD))
      else
        tab:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
        tab:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
        text:SetTextColor(0.7, 0.7, 0.7, 1.0)
      end
    end

    tab:SetScript("OnClick", function()
      activeTab = key

      -- Update all tabs
      for _, t in pairs(tabs) do
        t.UpdateAppearance()
      end

      -- Trigger callback
      if onTabChange then
        onTabChange(key)
      end
    end)

    tab:SetScript("OnEnter", function()
      if activeTab ~= key then
        tab:SetBackdropColor(0.15, 0.15, 0.15, 1.0)
      end
    end)

    tab:SetScript("OnLeave", function()
      UpdateAppearance()
    end)

    -- Store update function
    tab.UpdateAppearance = UpdateAppearance
    UpdateAppearance()

    return tab
  end

  -- Create tabs
  tabs.all = CreateTab("all", "All", 0)
  tabs.sales = CreateTab("sales", "Sales", 105)
  tabs.purchases = CreateTab("purchases", "Purchases", 210)

  -- Public API
  function self:GetActiveTab()
    return activeTab
  end

  function self:SetActiveTab(key)
    if tabs[key] then
      activeTab = key
      for _, tab in pairs(tabs) do
        tab.UpdateAppearance()
      end

      if onTabChange then
        onTabChange(key)
      end
    end
  end

  return self
end
