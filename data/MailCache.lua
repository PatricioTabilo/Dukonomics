-- Temporary mail cache for processing inbox items

if not Dukonomics then Dukonomics = {} end

local MailCache = {}
MailCache.__index = MailCache

function MailCache.new()
  return setmetatable({ cache = {} }, MailCache)
end

function MailCache:Clear()
  self.cache = {}
  Dukonomics.Logger.debug("Mail cache cleared")
end

function MailCache:Add(mailIndex, data)
  local mailObj
  if getmetatable(data) == Dukonomics.MailData then
    mailObj = data
  else
    local success, result = pcall(Dukonomics.MailData.new, data)
    if not success then
      Dukonomics.Logger.debug("Failed to cache mail " .. mailIndex .. ": " .. result)
      return false
    end
    mailObj = result
  end

  self.cache[mailIndex] = mailObj
  return true
end

function MailCache:Get(mailIndex)
  local mailObj = self.cache[mailIndex]
  return mailObj and mailObj:toTable() or nil
end

function MailCache:Has(mailIndex)
  return self.cache[mailIndex] ~= nil
end

function MailCache:Count()
  local count = 0
  for _ in pairs(self.cache) do count = count + 1 end
  return count
end

Dukonomics.MailCache = MailCache
Dukonomics.MailCacheRepository = MailCache.new()
