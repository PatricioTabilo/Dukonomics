-- Mail data model with validation and computed fields

if not Dukonomics then Dukonomics = {} end

local MailData = {}
MailData.__index = MailData

MailData.schema = {
  subject = {type = "string", required = true, default = ""},
  money = {type = "number", default = 0},
  invoiceType = {type = "string", enum = {"seller", "buyer"}},
  itemName = {type = "string"},
  itemLink = {type = "string"},
  bid = {type = "number", default = 0},
  count = {type = "number", default = 1, min = 1},
  consignment = {type = "number", default = 0},
  grossTotal = {type = "number", default = 0},
  unitPrice = {type = "number", default = 0}
}

function MailData.new(data)
  local self = setmetatable({}, MailData)
  self:initialize(data or {})
  return self
end

function MailData:initialize(data)
  for field, config in pairs(MailData.schema) do
    self[field] = data[field] ~= nil and data[field] or config.default
  end

  local valid, errorMsg = self:validate()
  if not valid then
    error("Invalid mail data: " .. errorMsg)
  end

  self:normalize()
end

function MailData:validate()
  for field, config in pairs(MailData.schema) do
    local value = self[field]

    if config.required and (value == nil or value == "") then
      return false, "Missing required field: " .. field
    end

    if value ~= nil and config.type and type(value) ~= config.type then
      return false, "Field " .. field .. " must be " .. config.type
    end

    if config.enum and value and not tContains(config.enum, value) then
      return false, "Invalid value for " .. field
    end

    if config.min and type(value) == "number" and value < config.min then
      return false, "Field " .. field .. " must be >= " .. config.min
    end
  end

  return true
end

function MailData:normalize()
  if self.itemName then
    self.itemName = self.itemName:match("^(.-)%s*%(%d+%)$") or self.itemName
  end

  self.money = math.max(0, self.money or 0)
  self.bid = math.max(0, self.bid or 0)
  self.count = math.max(1, self.count or 1)
  self.consignment = math.max(0, self.consignment or 0)

  self.grossTotal = self.bid + self.consignment
  self.unitPrice = self.count > 0 and math.floor(self.grossTotal / self.count) or self.grossTotal
end

function MailData:toTable()
  local result = {}
  for field in pairs(MailData.schema) do
    result[field] = self[field]
  end
  return result
end

function MailData:isSale()
  return self.invoiceType == "seller"
end

function MailData:isPurchase()
  return self.invoiceType == "buyer"
end

Dukonomics.MailData = MailData
