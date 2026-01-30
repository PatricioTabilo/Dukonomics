-- Dukonomics Mail Cache Repository
-- Repository pattern implementation for mail data access
-- Abstracts caching operations from business logic

-- Ensure Dukonomics global exists (for standalone testing)
if not Dukonomics then
  Dukonomics = {}
end

-- Require the Mail model
-- Note: In WoW addons, files are loaded via .toc, so this dependency must be declared there
if not Dukonomics.Mail then
  error("Mail model must be loaded before MailCacheRepository")
end

local MailData = Dukonomics.Mail

-- ============================================================================
-- MailCacheRepository Class: Repository pattern implementation
-- Abstracts data access for mail caching operations
-- ============================================================================

local MailCacheRepository = {}
MailCacheRepository.__index = MailCacheRepository

-- Constructor
function MailCacheRepository.new()
  return setmetatable({
    cache = {},  -- Internal storage: mailIndex -> MailData instance
    _observers = {}  -- For potential observer pattern extension
  }, MailCacheRepository)
end

-- Clear all cached mail data
function MailCacheRepository:Clear()
  self.cache = {}
  Dukonomics.Logger.debug("Mail cache cleared")
  self:_notifyObservers("cleared")
end

-- Add a mail to the cache
-- @param mailIndex: number - The mail's position in inbox
-- @param data: table|MailData - Raw mail data or MailData instance
-- @return boolean - Success status
function MailCacheRepository:Add(mailIndex, data)
  assert(type(mailIndex) == "number", "mailIndex must be a number")

  -- Accept raw data table or MailData instance
  local mailObj
  if getmetatable(data) == MailData then
    mailObj = data
  else
    -- Try to create MailData (will validate and normalize)
    local success, result = pcall(MailData.new, data)
    if not success then
      Dukonomics.Logger.debug("Failed to add mail " .. mailIndex .. ": " .. result)
      return false
    end
    mailObj = result
  end

  self.cache[mailIndex] = mailObj
  Dukonomics.Logger.debug("Mail " .. mailIndex .. " added to cache")
  self:_notifyObservers("added", mailIndex, mailObj)
  return true
end

-- Retrieve mail data by index
-- @param mailIndex: number
-- @return table|nil - Plain table representation or nil if not found
function MailCacheRepository:Get(mailIndex)
  local mailObj = self.cache[mailIndex]
  return mailObj and mailObj:toTable() or nil
end

-- Retrieve raw MailData object (for internal use)
-- @param mailIndex: number
-- @return MailData|nil
function MailCacheRepository:GetRaw(mailIndex)
  return self.cache[mailIndex]
end

-- Check if mail exists in cache
-- @param mailIndex: number
-- @return boolean
function MailCacheRepository:Has(mailIndex)
  return self.cache[mailIndex] ~= nil
end

-- Get all cached mail data
-- @return table - mailIndex -> mailData table
function MailCacheRepository:GetAll()
  local result = {}
  for k, v in pairs(self.cache) do
    result[k] = v:toTable()
  end
  return result
end

-- Get cache size
-- @return number
function MailCacheRepository:Count()
  local count = 0
  for _ in pairs(self.cache) do count = count + 1 end
  return count
end

-- Remove a specific mail from cache
-- @param mailIndex: number
function MailCacheRepository:Remove(mailIndex)
  if self.cache[mailIndex] then
    self.cache[mailIndex] = nil
    Dukonomics.Logger.debug("Mail " .. mailIndex .. " removed from cache")
    self:_notifyObservers("removed", mailIndex)
  end
end

-- Debug dump of cache contents
function MailCacheRepository:DebugDump()
  Dukonomics.Logger.debug("MailCache contents (" .. self:Count() .. " items):")
  for k, mailObj in pairs(self.cache) do
    Dukonomics.Logger.debug(string.format("  [%d] = %s (%s)",
      k, mailObj.subject, mailObj.invoiceType or "no invoice"))
  end
end

-- Observer pattern methods (for future extensibility)
function MailCacheRepository:AddObserver(observer)
  table.insert(self._observers, observer)
end

function MailCacheRepository:RemoveObserver(observer)
  for i, obs in ipairs(self._observers) do
    if obs == observer then
      table.remove(self._observers, i)
      break
    end
  end
end

function MailCacheRepository:_notifyObservers(event, ...)
  for _, observer in ipairs(self._observers) do
    if observer[event] then
      observer[event](observer, ...)
    end
  end
end

-- Create singleton instance
local repositoryInstance = MailCacheRepository.new()

-- Export repository instance
Dukonomics.MailCacheRepository = repositoryInstance
