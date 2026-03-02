-- Dukonomics: Summary Panel Component
-- Financial ledger design: minimalistic, elegant, professional.

local FormatMoney = Dukonomics.UI.Formatting.FormatMoney

Dukonomics.UI = Dukonomics.UI or {}
Dukonomics.UI.SummaryBar = {}

-----------------------------------------------------------
-- Summary Panel
-----------------------------------------------------------

function Dukonomics.UI.SummaryBar.Create(parent)
  local self = {}

  -- Minimalistic container. Now configured as a Sidecar drawer that floats elegantly.
  local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  container:SetAllPoints(parent)
  container:SetFrameLevel(parent:GetFrameLevel() - 1) -- Float slightly under to meld borders
  container:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4},
  })
  container:SetBackdropColor(0.04, 0.04, 0.04, 0.95)
  container:SetBackdropBorderColor(0.6, 0.5, 0.35, 1) -- Match Dukonomics.UI.Config.COLORS.BORDER

  -- Top header area with slightly lighter solid color
  local headerBg = container:CreateTexture(nil, "BACKGROUND", nil, -1)
  headerBg:SetPoint("TOPLEFT", 4, -4)
  headerBg:SetPoint("TOPRIGHT", -4, -4)
  headerBg:SetHeight(40)
  headerBg:SetColorTexture(0.08, 0.08, 0.08, 1)

  -- Title
  local title = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  title:SetPoint("CENTER", headerBg, "CENTER", 0, 0)
  title:SetText("OVERVIEW")
  title:SetTextColor(0.8, 0.7, 0.5, 1) -- elegant muted gold

  -- Header Separator
  local sep = container:CreateTexture(nil, "ARTWORK")
  sep:SetPoint("TOPLEFT", headerBg, "BOTTOMLEFT", 0, 0)
  sep:SetPoint("TOPRIGHT", headerBg, "BOTTOMRIGHT", 0, 0)
  sep:SetHeight(1)
  sep:SetColorTexture(0.2, 0.2, 0.2, 1)

  -- Shared logic for row creation (Ledger format)
  local ROW_HEIGHT = 44
  local ROW_GAP = 0
  local startY = -41 -- below header

  local function CreateMetricRow(index, labelText, defaultColor)
    local yOff = startY - ((index - 1) * (ROW_HEIGHT + ROW_GAP))
    
    local row = CreateFrame("Frame", nil, container)
    row:SetPoint("TOPLEFT", container, "TOPLEFT", 16, yOff)
    row:SetPoint("TOPRIGHT", container, "TOPRIGHT", -16, yOff)
    row:SetHeight(ROW_HEIGHT)

    -- Label (top-left, uppercase, very subtle gray)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -8)
    label:SetText(string.upper(labelText))
    label:SetTextColor(0.5, 0.5, 0.5, 1)

    -- Value (bottom-right, right-aligned)
    local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    value:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 6)
    value:SetJustifyH("RIGHT")
    value:SetText("-")
    if defaultColor then
      value:SetTextColor(unpack(defaultColor))
    end

    -- Bottom line separator
    local line = row:CreateTexture(nil, "ARTWORK")
    line:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    line:SetHeight(1)
    line:SetColorTexture(0.1, 0.1, 0.1, 1)

    return value
  end

  local postedValue    = CreateMetricRow(1, "Posted",     {0.75, 0.75, 0.75})
  local salesValue     = CreateMetricRow(2, "Sales",      {0.3, 0.85, 0.3})
  local purchasesValue = CreateMetricRow(3, "Purchases",  {0.85, 0.3, 0.3})
  
  -- Net Profit logic below standard rows, with a small vertical gap
  local totalYOff = startY - (3 * (ROW_HEIGHT + ROW_GAP)) - 10
  
  local profitRow = CreateFrame("Frame", nil, container)
  profitRow:SetPoint("TOPLEFT", container, "TOPLEFT", 16, totalYOff)
  profitRow:SetPoint("TOPRIGHT", container, "TOPRIGHT", -16, totalYOff)
  profitRow:SetHeight(70)
  
  -- Net Profit Top Separator (indicating a mathematical total)
  local totalDefLine = profitRow:CreateTexture(nil, "ARTWORK")
  totalDefLine:SetPoint("TOPLEFT", profitRow, "TOPLEFT", 0, 0)
  totalDefLine:SetPoint("TOPRIGHT", profitRow, "TOPRIGHT", 0, 0)
  totalDefLine:SetHeight(1)
  totalDefLine:SetColorTexture(0.3, 0.3, 0.3, 1)

  -- Net Profit Label
  local profitLabel = profitRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  profitLabel:SetPoint("TOPLEFT", profitRow, "TOPLEFT", 0, -16)
  profitLabel:SetText("NET PROFIT")
  profitLabel:SetTextColor(0.8, 0.7, 0.5, 1)

  -- Net Profit Value (Large)
  local profitValue = profitRow:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  profitValue:SetPoint("BOTTOMRIGHT", profitRow, "BOTTOMRIGHT", 0, 16)
  profitValue:SetJustifyH("RIGHT")
  profitValue:SetText("-")

  -----------------------------------------------------------
  -- Public API
  -----------------------------------------------------------

  function self:Update(data)
    local totalPosted = 0
    local totalSales = 0
    local totalPurchases = 0

    for _, item in ipairs(data) do
      if item._type == "sale" then
        if item.status == "active" then
          totalPosted = totalPosted + ((item.price or 0) * (item.count or 1))
        elseif item.status == "sold" then
          totalSales = totalSales + ((item.soldPrice or item.price or 0) * (item.count or 1))
        end
      elseif item._type == "purchase" then
        totalPurchases = totalPurchases + ((item.price or 0) * (item.count or 1))
      end
    end

    local netProfit = totalSales - totalPurchases

    postedValue:SetText(FormatMoney(totalPosted))
    salesValue:SetText(FormatMoney(totalSales))
    purchasesValue:SetText(FormatMoney(totalPurchases))
    profitValue:SetText(FormatMoney(netProfit))

    if netProfit > 0 then
      profitValue:SetTextColor(0.3, 0.85, 0.3, 1)  -- soft green
    elseif netProfit < 0 then
      profitValue:SetTextColor(0.85, 0.3, 0.3, 1)  -- soft red
    else
      profitValue:SetTextColor(0.5, 0.5, 0.5, 1)   -- neutral gray
    end
  end

  self.frame = container
  return self
end
