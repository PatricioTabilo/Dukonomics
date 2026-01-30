-- Dukonomics Mail Model
-- Domain entity representing a mail item with validation and business logic
-- Part of the Domain-Driven Design architecture

-- Ensure Dukonomics global exists (for standalone testing)
if not Dukonomics then
  Dukonomics = {}
end

local MailData = {}
MailData.__index = MailData

-- Schema definition for validation and documentation
MailData.schema = {
  subject = {type = "string", required = true, default = ""},
  money = {type = "number", required = false, default = 0},
  invoiceType = {type = "string", required = false, default = nil, enum = {"seller", "buyer"}},
  itemName = {type = "string", required = false, default = nil},
  itemLink = {type = "string", required = false, default = nil},
  bid = {type = "number", required = false, default = 0},
  count = {type = "number", required = false, default = 1, min = 1},
  consignment = {type = "number", required = false, default = 0},
  -- Calculated fields (auto-populated)
  grossTotal = {type = "number", required = false, default = 0},
  unitPrice = {type = "number", required = false, default = 0}
}

-- Create a new MailData instance
function MailData.new(data)
  local self = setmetatable({}, MailData)
  self:initialize(data or {})
  return self
end

-- Initialize with data, validate and normalize
function MailData:initialize(data)
  -- Apply defaults and set values
  for field, config in pairs(MailData.schema) do
    self[field] = data[field] ~= nil and data[field] or config.default
  end

  -- Validate
  local valid, errorMsg = self:validate()
  if not valid then
    Dukonomics.Logger.debug("MailData creation failed: " .. errorMsg)
    error("Invalid mail data: " .. errorMsg)
  end

  -- Normalize and calculate derived fields
  self:normalize()
end

-- Validate against schema
function MailData:validate()
  for field, config in pairs(MailData.schema) do
    local value = self[field]

    -- Required fields
    if config.required and (value == nil or value == "") then
      return false, "Missing required field: " .. field
    end

    -- Type checking
    if value ~= nil and type(value) ~= config.type then
      return false, "Field " .. field .. " must be " .. config.type .. ", got " .. type(value)
    end

    -- Enum validation
    if config.enum and value and not tContains(config.enum, value) then
      return false, "Field " .. field .. " must be one of: " .. table.concat(config.enum, ", ")
    end

    -- Min value for numbers
    if config.min and type(value) == "number" and value < config.min then
      return false, "Field " .. field .. " must be >= " .. config.min
    end
  end

  return true
end

-- Normalize data and calculate derived fields
function MailData:normalize()
  -- Clean item name (remove quantity suffix like "Item (5)")
  if self.itemName then
    self.itemName = self.itemName:match("^(.-)%s*%(%d+%)$") or self.itemName
  end

  -- Ensure numeric fields have valid values
  self.money = math.max(0, self.money or 0)
  self.bid = math.max(0, self.bid or 0)
  self.count = math.max(1, self.count or 1)
  self.consignment = math.max(0, self.consignment or 0)

  -- Calculate derived fields
  self.grossTotal = self.bid + self.consignment
  self.unitPrice = self.count > 0 and math.floor(self.grossTotal / self.count) or self.grossTotal
end

-- Get data as plain table (for external use)
function MailData:toTable()
  local result = {}
  for field in pairs(MailData.schema) do
    result[field] = self[field]
  end
  return result
end

-- Export the model
Dukonomics.Mail = MailData
