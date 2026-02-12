-- Formatting utilities for money, time, etc.

Dukonomics.UI = Dukonomics.UI or {}
Dukonomics.UI.Formatting = {}

local GOLD_ICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:14:14:2:0|t"
local SILVER_ICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:14:14:2:0|t"
local COPPER_ICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:14:14:2:0|t"

function Dukonomics.UI.Formatting.FormatMoney(copper)
  if not copper or copper == 0 then return "-" end

  local gold = math.floor(copper / 10000)
  local silver = math.floor((copper % 10000) / 100)
  local cop = copper % 100

  local parts = {}
  if gold > 0 then
    local goldStr = string.format("%d", gold):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
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

function Dukonomics.UI.Formatting.FormatPostedTime(timestamp)
  if not timestamp then return "-" end
  local diff = time() - timestamp

  if diff < 60 then return diff .. " sec ago"
  elseif diff < 3600 then return math.floor(diff / 60) .. " min ago"
  elseif diff < 86400 then return math.floor(diff / 3600) .. " h ago"
  else
    local days = math.floor(diff / 86400)
    return days .. " day" .. (days > 1 and "s" or "") .. " ago"
  end
end

function Dukonomics.UI.Formatting.FormatExpiration(timestamp, duration)
  if not timestamp then return "-" end

  local durationSeconds
  if duration == 1 then durationSeconds = 12 * 3600
  elseif duration == 2 then durationSeconds = 24 * 3600
  elseif duration == 3 then durationSeconds = 48 * 3600
  else durationSeconds = (duration and duration > 10) and duration or (48 * 3600)
  end

  local timeLeft = (timestamp + durationSeconds) - time()

  if timeLeft <= 0 then return "Expired"
  elseif timeLeft < 3600 then return math.floor(timeLeft / 60) .. " min"
  elseif timeLeft < 86400 then return math.floor(timeLeft / 3600) .. " h"
  else return math.floor(timeLeft / 86400) .. "d " .. math.floor((timeLeft % 86400) / 3600) .. "h"
  end
end
