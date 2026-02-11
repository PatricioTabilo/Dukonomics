-- Slash command handling

function Dukonomics.ToggleDebug()
  Dukonomics.DebugMode = not Dukonomics.DebugMode
  Dukonomics.ConfigRepository.SetDebugMode(Dukonomics.DebugMode)

  local dataType = Dukonomics.DebugMode and "DEBUG" or "PRODUCTION"
  Dukonomics.Logger.print("Debug mode: " .. (Dukonomics.DebugMode and "ON" or "OFF") .. " (using " .. dataType .. " data)")
end

function Dukonomics.SetDebugMode(enabled)
  if Dukonomics.DebugMode ~= enabled then
    Dukonomics.DebugMode = enabled
    Dukonomics.ConfigRepository.SetDebugMode(Dukonomics.DebugMode)
  end

  local dataType = Dukonomics.DebugMode and "DEBUG" or "PRODUCTION"
  Dukonomics.Logger.print("Debug mode: " .. (Dukonomics.DebugMode and "ON" or "OFF") .. " (using " .. dataType .. " data)")
end

function Dukonomics.ShowDebugStatus()
  local data = Dukonomics.Data.GetDataStore()
  local dataType = Dukonomics.DebugMode and "DEBUG" or "PRODUCTION"
  local postingCount = data.postings and #data.postings or 0
  local purchaseCount = data.purchases and #data.purchases or 0

  Dukonomics.Logger.print("Debug mode: " .. (Dukonomics.DebugMode and "|cff00ff00ON|r" or "|cffff0000OFF|r") .. " (using " .. dataType .. " data)")
  Dukonomics.Logger.print("Current data: " .. postingCount .. " postings, " .. purchaseCount .. " purchases")
end

function Dukonomics.RequireDebugMode()
  if not Dukonomics.DebugMode then
    Dukonomics.Logger.print("Testing commands are only available in debug mode.")
    return false
  end
  return true
end

SLASH_DUKONOMICS1 = "/dukonomics"
SLASH_DUKONOMICS2 = "/duk"

SlashCmdList["DUKONOMICS"] = function(message)
  local cmd, arg = message:match("^(%S*)%s*(.-)$")

  if cmd == "clear" then
    Dukonomics.Data.ClearOldData(tonumber(arg) or 30)

  elseif cmd == "testdata" then
    if not Dukonomics.RequireDebugMode() then return end
    Dukonomics.Testing.GenerateRandomData()

  elseif cmd == "simular" or cmd == "sim" then
    if not Dukonomics.RequireDebugMode() then return end
    Dukonomics.Testing.SimulateScenarios()

  elseif cmd == "status" or cmd == "st" then
    if not Dukonomics.RequireDebugMode() then return end
    Dukonomics.Testing.ShowStatus()

  elseif cmd == "test" then
    if not Dukonomics.RequireDebugMode() then return end
    Dukonomics.Testing.RunTests(arg ~= "" and arg or nil)

  elseif cmd == "expected" or cmd == "expect" then
    if not Dukonomics.RequireDebugMode() then return end
    Dukonomics.Testing.ShowExpected()

  elseif cmd == "debug" then
    if arg == "" then
      Dukonomics.ToggleDebug()
    elseif arg == "on" then
      Dukonomics.SetDebugMode(true)
    elseif arg == "off" then
      Dukonomics.SetDebugMode(false)
    elseif arg == "status" then
      Dukonomics.ShowDebugStatus()
    else
      Dukonomics.Logger.print("Usage: /duk debug [on|off|status]")
      Dukonomics.Logger.print("  /duk debug - Toggle debug mode")
      Dukonomics.Logger.print("  /duk debug on - Enable debug mode")
      Dukonomics.Logger.print("  /duk debug off - Disable debug mode")
      Dukonomics.Logger.print("  /duk debug status - Show debug status")
    end

  elseif cmd == "help" then
    Dukonomics.Logger.print("Commands:")
    Dukonomics.Logger.print("/duk - Open main window")
    Dukonomics.Logger.print("/duk clear [days] - Clear old data (default: 30)")
    Dukonomics.Logger.print("/duk debug [on|off|status] - Debug mode (uses separate data store)")
    Dukonomics.Logger.print("")
    Dukonomics.Logger.print("|cffff00ff--- Testing ---|r (requires debug mode)")
    Dukonomics.Logger.print("/duk sim - Create test postings")
    Dukonomics.Logger.print("/duk test [type] - Run tests (sale/purchase/cancel/expired/todo)")
    Dukonomics.Logger.print("/duk status - Show posting status")
    Dukonomics.Logger.print("/duk expected - Show expected results")

  else
    Dukonomics.UI.Toggle()
  end
end
