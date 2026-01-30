-- Dukonomics: Slash Commands
-- Manejo de comandos /dukonomics y /duk

function Dukonomics.ToggleDebug()
  Dukonomics.DebugMode = not Dukonomics.DebugMode
  DUKONOMICS_DATA.debugMode = Dukonomics.DebugMode
  Dukonomics.Logger.print("Debug mode: " .. (Dukonomics.DebugMode and "ON" or "OFF"))
end

-- Generate test data
function Dukonomics.GenerateTestData()
  local now = time()
  local items = {
    {name = "Poción de maná superior", id = 13444, price = 5000},
    {name = "Aceite de amonita de fuego", id = 212663, price = 200},
    {name = "Aceite para curtido ámbar", id = 212664, price = 150},
    {name = "Agua burbujeante", id = 159, price = 50},
    {name = "Bolsa de tejido crepuscular", id = 194019, price = 298000},
    {name = "Esencia de tierra", id = 7076, price = 1500},
    {name = "Esencia de fuego", id = 7077, price = 2000},
    {name = "Mineral de hierro", id = 2772, price = 800},
  }

  local statuses = {"active", "sold", "cancelled", "expired"}
  local source = {
    character = UnitName("player"),
    realm = GetRealmName(),
    faction = UnitFactionGroup("player")
  }

  -- Generate 50 random postings (using new stack-based system)
  for i = 1, 50 do
    local item = items[math.random(#items)]
    local status = statuses[math.random(#statuses)]
    local quantity = math.random(1, 20)  -- Stack size
    local ageHours = math.random(1, 168) -- 1 hour to 7 days
    local timestamp = now - (ageHours * 3600)

    table.insert(DUKONOMICS_DATA.postings, {
      itemID = item.id,
      itemLink = "|cffffffff|Hitem:" .. item.id .. "::::::::70:::::|h[" .. item.name .. "]|h|r",
      itemName = item.name,
      buyout = item.price,
      bid = math.floor(item.price * 0.8),
      count = quantity,  -- Full stack quantity
      deposit = math.floor(item.price * 0.05 * quantity),  -- Total deposit
      duration = math.random(1, 3),
      price = item.price,
      timestamp = timestamp,
      status = status,
      source = source
    })
  end

  -- Generate 20 random purchases
  for i = 1, 20 do
    local item = items[math.random(#items)]
    local quantity = math.random(1, 5)
    local ageHours = math.random(1, 168)
    local timestamp = now - (ageHours * 3600)

    table.insert(DUKONOMICS_DATA.purchases, {
      itemID = item.id,
      itemLink = "|cffffffff|Hitem:" .. item.id .. "::::::::70:::::|h[" .. item.name .. "]|h|r",
      itemName = item.name,
      price = item.price,
      count = quantity,
      timestamp = timestamp,
      source = source
    })
  end
end

-- Slash command registration
SLASH_DUKONOMICS1 = "/dukonomics"
SLASH_DUKONOMICS2 = "/duk"

SlashCmdList["DUKONOMICS"] = function(msg)
  local command, arg = msg:match("^(%S*)%s*(.-)$")

  if command == "clear" then
    -- Clear old data
    local days = tonumber(arg) or 30
    Dukonomics.Data.ClearOldData(days)

  elseif command == "testdata" then
    -- Generate test data
    Dukonomics.GenerateTestData()
    Dukonomics.Logger.print("Datos de prueba generados")

  elseif command == "debug" then
    -- Toggle debug mode
    Dukonomics.ToggleDebug()

  elseif command == "help" then
    -- Show help
    Dukonomics.Logger.print("Comandos disponibles:")
    Dukonomics.Logger.print("/duk - Abrir ventana principal")
    Dukonomics.Logger.print("/duk clear [días] - Limpiar postings antiguos (default: 30 días)")
    Dukonomics.Logger.print("/duk testdata - Generar datos de prueba")
    Dukonomics.Logger.print("/duk debug - Toggle debug mode")
    Dukonomics.Logger.print("/duk help - Mostrar esta ayuda")

  else
    -- Open main UI (default action)
    Dukonomics.UI.Toggle()
  end
end
