-- Dukonomics: DataTable Component
-- Header + ScrollFrame + Row Pool

Dukonomics.UI = Dukonomics.UI or {}
Dukonomics.UI.DataTable = {}

local COLOR = Dukonomics.UI.Config.COLORS
local SIZES = Dukonomics.UI.Config.SIZES
local COLUMNS = Dukonomics.UI.Config.COLUMNS

-----------------------------------------------------------
-- Row Pool
-----------------------------------------------------------

local function CreateRow(scrollChild)
  local row = CreateFrame("Button", nil, scrollChild, "BackdropTemplate")
  row:SetHeight(SIZES.ROW_HEIGHT)
  row:SetPoint("LEFT", scrollChild, "LEFT", 0, 0)
  row:SetPoint("RIGHT", scrollChild, "RIGHT", 0, 0)
  row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})

  row.cells = {}
  local xPos = 8

  for _, col in ipairs(COLUMNS) do
    if col.key == "icon" then
      row.cells.icon = row:CreateTexture(nil, "ARTWORK")
      row.cells.icon:SetSize(22, 22)
      row.cells.icon:SetPoint("LEFT", row, "LEFT", xPos + 3, 0)
    else
      row.cells[col.key] = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      row.cells[col.key]:SetPoint("LEFT", row, "LEFT", xPos, 0)
      row.cells[col.key]:SetWidth(col.width - 5)
      row.cells[col.key]:SetJustifyH(col.align or "LEFT")
    end
    xPos = xPos + col.width
  end

  -- Hover effect
  row:SetScript("OnEnter", function(self)
    self:SetBackdropColor(unpack(COLOR.ROW_HOVER))
    if self.data and self.data.itemLink then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetHyperlink(self.data.itemLink)
      GameTooltip:Show()
    end
  end)

  row:SetScript("OnLeave", function(self)
    local idx = self.rowIndex or 1
    if idx % 2 == 0 then
      self:SetBackdropColor(unpack(COLOR.ROW_EVEN))
    else
      self:SetBackdropColor(unpack(COLOR.ROW_ODD))
    end
    GameTooltip:Hide()
  end)

  return row
end

-----------------------------------------------------------
-- DataTable Constructor
-----------------------------------------------------------

function Dukonomics.UI.DataTable.Create(parent)
  local self = {}

  -- Header Row
  local headerRow = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  headerRow:SetHeight(SIZES.HEADER_HEIGHT)
  headerRow:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
  headerRow:SetPoint("TOPRIGHT", parent, "TOPRIGHT", 0, 0)
  headerRow:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8x8"})
  headerRow:SetBackdropColor(unpack(COLOR.HEADER_BG))

  local xOffset = 8
  for _, col in ipairs(COLUMNS) do
    if col.name then
      local header = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      header:SetPoint("LEFT", headerRow, "LEFT", xOffset, 0)
      header:SetWidth(col.width)
      header:SetJustifyH(col.align or "LEFT")
      header:SetText(col.name)
      header:SetTextColor(unpack(COLOR.HEADER_TEXT))
    end
    xOffset = xOffset + col.width
  end

  -- Scroll Frame
  local scrollFrame = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
  scrollFrame:SetPoint("TOPLEFT", headerRow, "BOTTOMLEFT", 0, -2)
  scrollFrame:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -28, 0)

  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(scrollFrame:GetWidth())
  scrollChild:SetHeight(1)
  scrollFrame:SetScrollChild(scrollChild)

  -- Row pool
  local rowPool = {}

  local function GetRow(index)
    if not rowPool[index] then
      rowPool[index] = CreateRow(scrollChild)
    end
    return rowPool[index]
  end

  local function HideAllRows()
    for _, row in pairs(rowPool) do
      row:Hide()
    end
  end

  -- Render function
  function self:Render(data)
    HideAllRows()

    local yOffset = 0

    for i, posting in ipairs(data) do
      local row = GetRow(i)
      row:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
      row.data = posting
      row.rowIndex = i

      -- Alternating colors
      if i % 2 == 0 then
        row:SetBackdropColor(unpack(COLOR.ROW_EVEN))
      else
        row:SetBackdropColor(unpack(COLOR.ROW_ODD))
      end

      -- Icon
      if posting.itemLink then
        row.cells.icon:SetTexture(GetItemIcon(posting.itemLink))
      else
        row.cells.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
      end

      -- Item name with quality color
      local itemName = posting.itemName or "?"
      if posting.itemLink then
        local _, _, quality = GetItemInfo(posting.itemLink)
        if quality then
          local r, g, b = GetItemQualityColor(quality)
          row.cells.item:SetText(itemName)
          row.cells.item:SetTextColor(r, g, b)
        else
          row.cells.item:SetText(itemName)
          row.cells.item:SetTextColor(1, 1, 1)
        end
      else
        row.cells.item:SetText(itemName)
        row.cells.item:SetTextColor(1, 1, 1)
      end

      -- Qty
      row.cells.qty:SetText(posting.count or 1)
      row.cells.qty:SetTextColor(1, 1, 1)

      -- Total with coin icons
      local total = (posting.price or 0) * (posting.count or 1)
      row.cells.total:SetText(Dukonomics.UI.Formatting.FormatMoney(total))

      -- Status
      local status = posting.status or "?"
      local displayStatus = status
      if posting.pendingRemovalType == "cancelled" then
        displayStatus = "cancelled"
      end

      if displayStatus == "active" then
        row.cells.status:SetText("Active")
        row.cells.status:SetTextColor(unpack(COLOR.STATUS.active))
      elseif displayStatus == "sold" then
        row.cells.status:SetText("Sold")
        row.cells.status:SetTextColor(unpack(COLOR.STATUS.sold))
      elseif displayStatus == "cancelled" then
        row.cells.status:SetText("Cancelled")
        row.cells.status:SetTextColor(unpack(COLOR.STATUS.cancelled))
      elseif displayStatus == "expired" then
        row.cells.status:SetText("Expired")
        row.cells.status:SetTextColor(unpack(COLOR.STATUS.expired))
      elseif displayStatus == "purchased" then
        row.cells.status:SetText("Purchase")
        row.cells.status:SetTextColor(unpack(COLOR.STATUS.purchased))
      else
        row.cells.status:SetText(displayStatus)
        row.cells.status:SetTextColor(0.7, 0.7, 0.7)
      end

      -- Character
      local charName = (posting.source and posting.source.character) or "-"
      row.cells.char:SetText(charName)
      row.cells.char:SetTextColor(0.9, 0.9, 0.9)

      -- Realm
      local realmName = (posting.source and posting.source.realm) or "-"
      row.cells.realm:SetText(realmName)
      row.cells.realm:SetTextColor(0.8, 0.8, 0.8)

      -- Posted time
      row.cells.posted:SetText(Dukonomics.UI.Formatting.FormatPostedTime(posting.timestamp))
      row.cells.posted:SetTextColor(0.7, 0.7, 0.7)

      -- Expiration (only for active items)
      if displayStatus == "active" then
        row.cells.expiration:SetText(Dukonomics.UI.Formatting.FormatExpiration(posting.timestamp, posting.duration))
        row.cells.expiration:SetTextColor(0.9, 0.7, 0.3)
      else
        row.cells.expiration:SetText("-")
        row.cells.expiration:SetTextColor(0.5, 0.5, 0.5)
      end

      row:Show()
      yOffset = yOffset + SIZES.ROW_HEIGHT
    end

    scrollChild:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
  end

  self.frame = headerRow
  self.scrollFrame = scrollFrame
  return self
end
