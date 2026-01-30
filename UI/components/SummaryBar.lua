-- Dukonomics: Summary Bar Component
-- Barra de resumen con totales In/Out/Revenue/Profit

local COLOR = Dukonomics.UI.Config.COLORS

Dukonomics.UI = Dukonomics.UI or {}
Dukonomics.UI.SummaryBar = {}

-----------------------------------------------------------
-- Summary Bar Component
-----------------------------------------------------------

function Dukonomics.UI.SummaryBar.Create(parent)
  local self = {}

  -- Main container
  local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  container:SetHeight(32)
  container:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 6, 6)
  container:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -6, 6)
  container:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 12,
    insets = {left = 2, right = 2, top = 2, bottom = 2},
  })
  container:SetBackdropColor(0.15, 0.12, 0.08, 1)
  container:SetBackdropBorderColor(unpack(COLOR.BORDER))

  -- Money icons
  local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
  local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:2:0|t"
  local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:2:0|t"

  -- Format money helper
  local function FormatMoney(copper)
    if not copper or copper == 0 then return "0" .. COPPER_ICON end

    local gold = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop = copper % 100

    local parts = {}
    if gold > 0 then
      local goldStr = tostring(gold)
      if gold >= 1000 then
        goldStr = string.format("%s,%03d", math.floor(gold / 1000), gold % 1000)
      end
      table.insert(parts, goldStr .. GOLD_ICON)
    end
    if silver > 0 or gold > 0 then
      table.insert(parts, silver .. SILVER_ICON)
    end
    if cop > 0 or (gold == 0 and silver == 0) then
      table.insert(parts, cop .. COPPER_ICON)
    end

    return table.concat(parts, " ")
  end

  -- Create summary labels with better spacing distribution
  local labels = {}

  -- Purchases (In)
  local inLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  inLabel:SetPoint("LEFT", container, "LEFT", 12, 0)
  inLabel:SetText("In: ")
  inLabel:SetTextColor(0.7, 0.7, 0.7, 1)

  local inValue = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  inValue:SetPoint("LEFT", inLabel, "RIGHT", 2, 0)
  inValue:SetText("0" .. COPPER_ICON)
  inValue:SetTextColor(1, 0.5, 0.5, 1) -- Red for spending

  -- Expenses (Out)
  local outLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  outLabel:SetPoint("LEFT", container, "LEFT", 230, 0)
  outLabel:SetText("Out: ")
  outLabel:SetTextColor(0.7, 0.7, 0.7, 1)

  local outValue = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  outValue:SetPoint("LEFT", outLabel, "RIGHT", 2, 0)
  outValue:SetText("0" .. COPPER_ICON)
  outValue:SetTextColor(1, 0.7, 0.3, 1) -- Orange for expenses

  -- Revenue
  local revenueLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  revenueLabel:SetPoint("LEFT", container, "LEFT", 450, 0)
  revenueLabel:SetText("Revenue: ")
  revenueLabel:SetTextColor(0.7, 0.7, 0.7, 1)

  local revenueValue = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  revenueValue:SetPoint("LEFT", revenueLabel, "RIGHT", 2, 0)
  revenueValue:SetText("0" .. COPPER_ICON)
  revenueValue:SetTextColor(0.4, 0.9, 0.4, 1) -- Green for income

  -- Profit (fixed position from right)
  local profitLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  profitLabel:SetPoint("RIGHT", container, "RIGHT", -200, 0)
  profitLabel:SetText("Profit: ")
  profitLabel:SetTextColor(0.7, 0.7, 0.7, 1)

  local profitValue = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  profitValue:SetPoint("LEFT", profitLabel, "RIGHT", 2, 0)
  profitValue:SetText("0" .. COPPER_ICON)
  profitValue:SetTextColor(unpack(COLOR.GOLD))

  -----------------------------------------------------------
  -- Public API
  -----------------------------------------------------------

  function self:Update(data)
    local totalIn = 0        -- Total spent on purchases
    local totalOut = 0       -- Total expenses (deposits)
    local totalRevenue = 0   -- Total from sales

    for _, item in ipairs(data) do
      -- Count purchases (money spent buying)
      if item._type == "purchase" then
        totalIn = totalIn + ((item.price or 0) * (item.count or 1))

      -- Count sales and expenses
      elseif item._type == "sale" then
        -- Add deposits to expenses
        totalOut = totalOut + ((item.deposit or 0) * (item.count or 1))

        -- Add revenue from sold items
        if item.status == "sold" then
          totalRevenue = totalRevenue + ((item.soldPrice or item.price or 0) * (item.count or 1))
        end
      end
    end

    -- Calculate profit (Revenue - Expenses - Purchases)
    local profit = totalRevenue - totalOut - totalIn

    -- Update display
    inValue:SetText(FormatMoney(totalIn))
    outValue:SetText(FormatMoney(totalOut))
    revenueValue:SetText(FormatMoney(totalRevenue))
    profitValue:SetText(FormatMoney(profit))

    -- Color profit based on positive/negative
    if profit > 0 then
      profitValue:SetTextColor(0.4, 0.9, 0.4, 1) -- Green
    elseif profit < 0 then
      profitValue:SetTextColor(1, 0.5, 0.5, 1) -- Red
    else
      profitValue:SetTextColor(0.7, 0.7, 0.7, 1) -- Gray
    end
  end

  self.frame = container
  return self
end
