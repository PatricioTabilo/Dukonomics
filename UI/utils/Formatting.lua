-- Dukonomics: Formatting utilities
-- Funciones para formatear monedas, tiempo, etc

Dukonomics.UI = Dukonomics.UI or {}
Dukonomics.UI.Formatting = {}

-- Money icons
local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:2:0|t"
local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:2:0|t"

-- Format money with coin icons
function Dukonomics.UI.Formatting.FormatMoney(copper)
  if not copper or copper == 0 then return "-" end

  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper % 10000) / 100)
  local cop = copper % 100

  local parts = {}
  if gold > 0 then
    -- Format gold with commas if > 1000
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

-- Format posted time (relative)
function Dukonomics.UI.Formatting.FormatPostedTime(timestamp)
  if not timestamp then return "-" end
  local diff = time() - timestamp

  if diff < 60 then
    return diff .. " sec ago"
  elseif diff < 3600 then
    return math.floor(diff / 60) .. " min ago"
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return hours .. " h ago"
  else
    local days = math.floor(diff / 86400)
    return days .. " day" .. (days > 1 and "s" or "") .. " ago"
  end
end

-- Format expiration time
function Dukonomics.UI.Formatting.FormatExpiration(timestamp, duration)
  if not timestamp then return "-" end

  -- Map WoW duration values to seconds
  -- duration: 1 = 12h, 2 = 24h, 3 = 48h
  local durationSeconds
  if duration == 1 then
    durationSeconds = 12 * 3600
  elseif duration == 2 then
    durationSeconds = 24 * 3600
  elseif duration == 3 then
    durationSeconds = 48 * 3600
  else
    -- If duration is already in seconds or unknown, use it directly or default to 48h
    durationSeconds = (duration and duration > 10) and duration or (48 * 3600)
  end

  local expirationTime = timestamp + durationSeconds
  local timeLeft = expirationTime - time()

  if timeLeft <= 0 then
    return "Expired"
  elseif timeLeft < 3600 then
    return math.floor(timeLeft / 60) .. " min"
  elseif timeLeft < 86400 then
    local hours = math.floor(timeLeft / 3600)
    return hours .. " h"
  else
    local days = math.floor(timeLeft / 86400)
    local hours = math.floor((timeLeft % 86400) / 3600)
    return days .. "d " .. hours .. "h"
  end
end
