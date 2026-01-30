-- Dukonomics Logger
-- Centralized logging utilities

Dukonomics.Logger = {}

function Dukonomics.Logger.print(msg)
  print("|cFF00D4FFDukonomics:|r " .. msg)
end

function Dukonomics.Logger.debug(msg)
  if Dukonomics.DebugMode then
    print("|cFF808080[Dukonomics Debug]|r " .. msg)
  end
end

-- Log a table's contents for debugging
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

-- Log a table's contents in a single line for debugging
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
