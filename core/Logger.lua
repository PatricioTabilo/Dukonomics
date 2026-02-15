Dukonomics.Logger = {}

local PREFIX = "|cFF00D4FFDukonomics:|r "
local DEBUG_PREFIX = "|cFF808080[Dukonomics]|r "
local WARN_PREFIX = "|cFFFFA500[Dukonomics Warning]|r "

-- Prints messages with the addon prefix
function Dukonomics.Logger.print(msg)
  print(PREFIX .. msg)
end

function Dukonomics.Logger.debug(msg)
  if Dukonomics.DebugMode then
    print(DEBUG_PREFIX .. msg)
  end
end

function Dukonomics.Logger.warn(msg)
  print(WARN_PREFIX .. msg)
end

function Dukonomics.Logger.table(tbl, name)
  if not Dukonomics.DebugMode then return end
  if not tbl then
    Dukonomics.Logger.debug(name .. ": nil")
    return
  end
  Dukonomics.Logger.debug(name .. ": {")
  for k, v in pairs(tbl) do
    Dukonomics.Logger.debug("  [" .. tostring(k) .. "] = " .. tostring(v))
  end
  Dukonomics.Logger.debug("}")
end

function Dukonomics.Logger.debugTable(tbl, name)
  if not Dukonomics.DebugMode then return end
  if not tbl then
    Dukonomics.Logger.debug(name .. ": nil")
    return
  end

  local parts = {}
  for k, v in pairs(tbl) do
    table.insert(parts, tostring(k) .. "=" .. tostring(v))
  end
  Dukonomics.Logger.debug(name .. ": {" .. table.concat(parts, ", ") .. "}")
end
