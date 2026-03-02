local oldContent = io.open("UI/MainFrame.lua", "r"):read("*a")

local strTarget = [[
-- Options button (Gear icon)
local optionsBtn = CreateFrame("Button", nil, frame)
optionsBtn:SetSize(20, 20)
]]

local strReplacement = [[
-- Toggle Summary Panel button
local toggleSummaryBtn = CreateFrame("Button", nil, frame)
toggleSummaryBtn:SetSize(20, 20)
toggleSummaryBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
toggleSummaryBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Up")
toggleSummaryBtn:GetNormalTexture():SetTexCoord(0, 1, 0, 1)
-- toggleSummaryBtn:GetNormalTexture():SetVertexColor(1, 0.82, 0)
toggleSummaryBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-BiggerButton-Down")
toggleSummaryBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
toggleSummaryBtn:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_TOP")
  GameTooltip:SetText("Toggle Ledger", 1, 1, 1)
  GameTooltip:Show()
end)
toggleSummaryBtn:SetScript("OnLeave", function(self)
  GameTooltip:Hide()
end)

-- Options button (Gear icon)
local optionsBtn = CreateFrame("Button", nil, frame)
optionsBtn:SetSize(20, 20)
]]

local newContent = string.gsub(oldContent, strTarget:gsub("%p", "%%%1"), strReplacement:gsub("%%", "%%%%"))

-- the second block to replace:
local strTarget2 = [[
optionsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -2, 0)
]]

local strReplacement2 = [[
optionsBtn:SetPoint("RIGHT", toggleSummaryBtn, "LEFT", -4, 0)
]]
newContent = string.gsub(newContent, strTarget2:gsub("%p", "%%%1"), strReplacement2:gsub("%%", "%%%%"))

-- third block:
local strTarget3 = [[
-- Summary Panel (right side)
local summaryAnchor = CreateFrame("Frame", nil, frame)
summaryAnchor:SetWidth(250)
summaryAnchor:SetPoint("TOPRIGHT", filterBarAnchor, "BOTTOMRIGHT", 0, -4)
summaryAnchor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 6)

summaryBar = Dukonomics.UI.SummaryBar.Create(summaryAnchor)

-- Data Table (between filters and summary, clipped so headers don't bleed)
local tableAnchor = CreateFrame("Frame", nil, frame)
tableAnchor:SetPoint("TOPLEFT", filterBarAnchor, "BOTTOMLEFT", 0, -4)
tableAnchor:SetPoint("BOTTOMRIGHT", summaryAnchor, "BOTTOMLEFT", -4, 0)
tableAnchor:SetClipsChildren(true)

dataTable = Dukonomics.UI.DataTable.Create(tableAnchor)
]]

local strReplacement3 = [[
-- Data Table spans full width of the main frame
local tableAnchor = CreateFrame("Frame", nil, frame)
tableAnchor:SetPoint("TOPLEFT", filterBarAnchor, "BOTTOMLEFT", 0, -4)
tableAnchor:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -6, 10)
tableAnchor:SetClipsChildren(true)

-- Summary Panel (Sidecar/Drawer attached OUTSIDE the frame to the right)
local summaryAnchor = CreateFrame("Frame", nil, frame)
summaryAnchor:SetWidth(260)
summaryAnchor:SetPoint("TOPLEFT", frame, "TOPRIGHT", -2, -12)
summaryAnchor:SetPoint("BOTTOMLEFT", frame, "BOTTOMRIGHT", -2, 6)
summaryAnchor:Hide() -- hidden by default or we can leave it shown based on savedvars. Let's make it shown by default:
summaryAnchor:Show()

local isSummaryOpen = true
toggleSummaryBtn:SetScript("OnClick", function()
  isSummaryOpen = not isSummaryOpen
  if isSummaryOpen then
    summaryAnchor:Show()
  else
    summaryAnchor:Hide()
  end
end)

summaryBar = Dukonomics.UI.SummaryBar.Create(summaryAnchor)
dataTable = Dukonomics.UI.DataTable.Create(tableAnchor)
]]
newContent = string.gsub(newContent, strTarget3:gsub("%p", "%%%1"), strReplacement3:gsub("%%", "%%%%"))


local f = io.open("UI/MainFrame.lua", "w")
f:write(newContent)
f:close()
