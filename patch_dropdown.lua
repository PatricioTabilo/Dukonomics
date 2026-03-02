local oldContent = io.open("UI/components/FilterBar.lua", "r"):read("*a")

local strTarget = [[
    local buttonWidth = math.max(minButtonWidth, math.ceil(maxLabelWidth) + 18)

    local buttons = {}
    local yOffset = -4

    for i, item in ipairs(items) do
      local btn = CreateFrame("Button", nil, menu, "BackdropTemplate")
      btn:SetSize(buttonWidth, 20)
      btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, yOffset)
      btn:SetClipsChildren(true)

      local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      text:SetPoint("LEFT", btn, "LEFT", 8, 0)
      text:SetWidth(buttonWidth - 16)
      text:SetJustifyH("LEFT")
      text:SetTextColor(0.95, 0.95, 0.95, 1)
      text:SetText(item.label)
]]

local strReplacement = [[
    local hasCheckboxes = false
    for _, item in ipairs(items) do
      if item.checked ~= nil then
        hasCheckboxes = true
        break
      end
    end

    local txtOffsetX = 8
    local extraW = 18
    if hasCheckboxes then
      txtOffsetX = 26
      extraW = 34
    end

    local buttonWidth = math.max(minButtonWidth, math.ceil(maxLabelWidth) + extraW)

    local buttons = {}
    local yOffset = -4

    for i, item in ipairs(items) do
      local btn = CreateFrame("Button", nil, menu, "BackdropTemplate")
      btn:SetSize(buttonWidth, 20)
      btn:SetPoint("TOPLEFT", menu, "TOPLEFT", 4, yOffset)
      btn:SetClipsChildren(true)

      if hasCheckboxes then
        -- Clean, modern checkbox design using pure textures (1px borders illusion)
        local boxBorder = btn:CreateTexture(nil, "BACKGROUND")
        boxBorder:SetSize(12, 12)
        boxBorder:SetPoint("LEFT", btn, "LEFT", 8, 0)
        boxBorder:SetColorTexture(0.5, 0.4, 0.25, 0.8) -- Subtle gold/gray border
        
        local boxInner = btn:CreateTexture(nil, "ARTWORK")
        boxInner:SetSize(10, 10)
        boxInner:SetPoint("CENTER", boxBorder, "CENTER", 0, 0)
        
        if item.checked then
          boxInner:SetColorTexture(0.8, 0.7, 0.4, 1) -- Elegant muted gold fill
        else
          boxInner:SetColorTexture(0.1, 0.1, 0.1, 1) -- Empty dark inside
        end
      end

      local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
      text:SetPoint("LEFT", btn, "LEFT", txtOffsetX, 0)
      text:SetWidth(buttonWidth - txtOffsetX - 8)
      text:SetJustifyH("LEFT")
      text:SetTextColor(0.95, 0.95, 0.95, 1)
      text:SetText(item.label)
]]

local newContent = string.gsub(oldContent, strTarget:gsub("%p", "%%%1"), strReplacement:gsub("%%", "%%%%"))

local f = io.open("UI/components/FilterBar.lua", "w")
f:write(newContent)
f:close()
