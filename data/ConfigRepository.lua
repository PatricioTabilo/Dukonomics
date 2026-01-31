-- Dukonomics: Configuration Repository
-- Manages addon settings and preferences

Dukonomics.ConfigRepository = {}

-- Default configuration values
local DEFAULT_CONFIG = {
  debugMode = false,
  showWelcome = true,
  cacheFilters = false,
  cachedFilters = {
    type = "all",
    timeRange = "all",
    status = "all",
    character = "all"
  }
}

-- Initialize configuration data store
function Dukonomics.ConfigRepository.Initialize()
  -- Ensure config exists
  if not DUKONOMICS_CONFIG then
    DUKONOMICS_CONFIG = {}
    Dukonomics.Logger.debug("|cffff0000[Config] Created NEW config (first time)|r")
  else
    Dukonomics.Logger.debug("|cff00ff00[Config] Loaded EXISTING config|r")
  end

  -- Apply defaults safely
  for key, defaultValue in pairs(DEFAULT_CONFIG) do
    if DUKONOMICS_CONFIG[key] == nil then
      if type(defaultValue) == "table" then
        DUKONOMICS_CONFIG[key] = {}
        for subKey, subValue in pairs(defaultValue) do
          DUKONOMICS_CONFIG[key][subKey] = subValue
        end
      else
        DUKONOMICS_CONFIG[key] = defaultValue
      end
    end
  end
end

-- Get a configuration value
function Dukonomics.ConfigRepository.Get(key, defaultValue)
  if not DUKONOMICS_CONFIG then
    Dukonomics.ConfigRepository.Initialize()
  end

  local value = DUKONOMICS_CONFIG[key]
  if value ~= nil then
    return value
  end

  return defaultValue or DEFAULT_CONFIG[key]
end

-- Set a configuration value
function Dukonomics.ConfigRepository.Set(key, value)
  if not DUKONOMICS_CONFIG then
    Dukonomics.ConfigRepository.Initialize()
  end

  DUKONOMICS_CONFIG[key] = value
  Dukonomics.Logger.debug("Config updated: " .. key .. " = " .. tostring(value))
end

-- Get all cached filters
function Dukonomics.ConfigRepository.GetCachedFilters()
  return Dukonomics.ConfigRepository.Get("cachedFilters", DEFAULT_CONFIG.cachedFilters)
end

-- Set cached filters
function Dukonomics.ConfigRepository.SetCachedFilters(filters)
  if not DUKONOMICS_CONFIG then
    Dukonomics.ConfigRepository.Initialize()
  end

  if not DUKONOMICS_CONFIG.cachedFilters then
    DUKONOMICS_CONFIG.cachedFilters = {}
  end

  DUKONOMICS_CONFIG.cachedFilters.type = filters.type or DUKONOMICS_CONFIG.cachedFilters.type or "all"
  DUKONOMICS_CONFIG.cachedFilters.timeRange = filters.timeRange or DUKONOMICS_CONFIG.cachedFilters.timeRange or "all"
  DUKONOMICS_CONFIG.cachedFilters.status = filters.status or DUKONOMICS_CONFIG.cachedFilters.status or "all"
  DUKONOMICS_CONFIG.cachedFilters.character = filters.character or DUKONOMICS_CONFIG.cachedFilters.character or "all"

  Dukonomics.Logger.debug("Config updated: cachedFilters")
end

-- Check if feature is enabled
function Dukonomics.ConfigRepository.IsDebugModeEnabled()
  return Dukonomics.ConfigRepository.Get("debugMode", false)
end

function Dukonomics.ConfigRepository.IsWelcomeMessageEnabled()
  return Dukonomics.ConfigRepository.Get("showWelcome", true)
end

function Dukonomics.ConfigRepository.IsCacheFiltersEnabled()
  return Dukonomics.ConfigRepository.Get("cacheFilters", false)
end

-- Set feature flags
function Dukonomics.ConfigRepository.SetDebugMode(enabled)
  Dukonomics.ConfigRepository.Set("debugMode", enabled)
end

function Dukonomics.ConfigRepository.SetWelcomeMessage(enabled)
  Dukonomics.ConfigRepository.Set("showWelcome", enabled)
end

function Dukonomics.ConfigRepository.SetCacheFilters(enabled)
  Dukonomics.ConfigRepository.Set("cacheFilters", enabled)
  Dukonomics.Logger.debug("|cff00ffff[Config] Cache filters SET to: " .. tostring(enabled) .. "|r")
end
