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

  -- Posted (potential income from active auctions)
  local postedLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  postedLabel:SetPoint("LEFT", container, "LEFT", 12, 0)
  postedLabel:SetText("Posted: ")
  postedLabel:SetTextColor(0.7, 0.7, 0.7, 1)

  local postedValue = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  postedValue:SetPoint("LEFT", postedLabel, "RIGHT", 2, 0)
  postedValue:SetText("0" .. COPPER_ICON)
  postedValue:SetTextColor(0.6, 0.8, 1, 1) -- Light blue for pending/potential

  -- Sales (completed)
  local salesLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  salesLabel:SetPoint("LEFT", container, "LEFT", 220, 0)
  salesLabel:SetText("Sales: ")
  salesLabel:SetTextColor(0.7, 0.7, 0.7, 1)

  local salesValue = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  salesValue:SetPoint("LEFT", salesLabel, "RIGHT", 2, 0)
  salesValue:SetText("0" .. COPPER_ICON)
  salesValue:SetTextColor(0.4, 0.9, 0.4, 1) -- Green for income

  -- Purchases (money spent buying)
  local depositsLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  depositsLabel:SetPoint("LEFT", container, "LEFT", 430, 0)
  depositsLabel:SetText("Purchases: ")
  depositsLabel:SetTextColor(0.7, 0.7, 0.7, 1)

  local depositsValue = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  depositsValue:SetPoint("LEFT", depositsLabel, "RIGHT", 2, 0)
  depositsValue:SetText("0" .. COPPER_ICON)
  depositsValue:SetTextColor(1, 0.5, 0.5, 1) -- Red for spending

  -- Net Profit (fixed position from right)
  local profitLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  profitLabel:SetPoint("RIGHT", container, "RIGHT", -200, 0)
  profitLabel:SetText("Net Profit: ")
  profitLabel:SetTextColor(0.7, 0.7, 0.7, 1)

  local profitValue = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  profitValue:SetPoint("LEFT", profitLabel, "RIGHT", 2, 0)
  profitValue:SetText("0" .. COPPER_ICON)
  profitValue:SetTextColor(unpack(COLOR.GOLD))

  -----------------------------------------------------------
  -- Public API
  -----------------------------------------------------------

  function self:Update(data)
    local totalPosted = 0      -- Value of active auctions (potential income)
    local totalSales = 0       -- Total earned from completed sales
    local totalPurchases = 0   -- Total spent buying items

    for _, item in ipairs(data) do
      if item._type == "sale" then
        -- Active auctions = potential income (Posted)
        if item.status == "active" then
          totalPosted = totalPosted + ((item.price or 0) * (item.count or 1))

        -- Sold = actual income
        elseif item.status == "sold" then
          totalSales = totalSales + ((item.soldPrice or item.price or 0) * (item.count or 1))
        end

      -- Purchases = money spent buying
      elseif item._type == "purchase" then
        totalPurchases = totalPurchases + ((item.price or 0) * (item.count or 1))
      end
    end

    -- Net Profit = Sales - Purchases
    local netProfit = totalSales - totalPurchases

    -- Update display
    postedValue:SetText(FormatMoney(totalPosted))
    salesValue:SetText(FormatMoney(totalSales))
    depositsValue:SetText(FormatMoney(totalPurchases))
    profitValue:SetText(FormatMoney(math.abs(netProfit)))

    -- Color profit based on positive/negative
    if netProfit > 0 then
      profitValue:SetTextColor(0.4, 0.9, 0.4, 1) -- Green
    elseif netProfit < 0 then
      profitValue:SetText("-" .. FormatMoney(math.abs(netProfit)))
      profitValue:SetTextColor(1, 0.5, 0.5, 1) -- Red
    else
      profitValue:SetTextColor(0.7, 0.7, 0.7, 1) -- Gray
    end
  end

  self.frame = container
  return self
end
