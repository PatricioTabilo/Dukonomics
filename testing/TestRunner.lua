-- Test scenarios and data generation for Dukonomics

Dukonomics.Testing = Dukonomics.Testing or {}

local TEST_MAILS = {
  {
    type = "expired",
    mailData = {
      subject = "Subasta terminada: Piedra porosa (100)",
      money = 0, bid = 0, consignment = 0,
      itemLink = "|cffffffff|Hitem:168185::::::::70:::::|h[Piedra porosa]|h|r"
    },
    description = "Expiración: Piedra porosa x100"
  },
  {
    type = "sale",
    mailData = {
      invoiceType = "seller",
      subject = "Subasta conseguida: Piedra porosa (50)",
      count = 50,
      money = 95000,
      bid = 100000,
      consignment = 5000,
      itemName = "Piedra porosa"
    },
    description = "Venta: Piedra porosa x50 @ 20s/u"
  },
  {
    type = "cancelled",
    mailData = {
      subject = "Subasta cancelada: Piedra porosa (50)",
      money = 0, bid = 0, consignment = 0,
      itemLink = "|cffffffff|Hitem:168185::::::::70:::::|h[Piedra porosa]|h|r"
    },
    description = "Cancelación: Piedra porosa x50"
  },
  {
    type = "cancelled",
    mailData = {
      subject = "Subasta cancelada: Bolsa de tejido del crepúsculo",
      money = 0, bid = 0, consignment = 0,
      itemLink = "|cffffffff|Hitem:194019::::::::70:::::|h[Bolsa de tejido del crepúsculo]|h|r"
    },
    description = "Cancelación: Bolsa crepúsculo x1"
  },
  {
    type = "sale",
    mailData = {
      invoiceType = "seller",
      subject = "Subasta conseguida: Bismuto (300)",
      count = 300,
      money = 103614000,
      bid = 109020000,
      consignment = 5451000,
      itemName = "Bismuto"
    },
    description = "Venta: Bismuto x300 @ 36.34g/u"
  },
  {
    type = "purchase",
    mailData = {
      invoiceType = "buyer",
      subject = "Subasta ganada: Bolsa de urditela",
      count = 1,
      money = 0,
      bid = 6500000,
      consignment = 0,
      itemLink = "|cffffffff|Hitem:222022::::::::70:::::|h[Bolsa de urditela]|h|r",
      itemName = "Bolsa de urditela"
    },
    description = "Compra: Bolsa urditela x1 @ 650g"
  }
}

function Dukonomics.Testing.SimulateScenarios()
  local now = time()
  local source = {
    character = UnitName("player"),
    realm = GetRealmName(),
    faction = UnitFactionGroup("player")
  }

  local data = Dukonomics.Data.GetDataStore()
  data.postings = {}
  Dukonomics.Logger.print("|cffff0000[TEST]|r Postings cleared")

  -- Piedra porosa: expiración, venta, cancelación
  table.insert(data.postings, {
    itemID = 168185,
    itemLink = "|cffffffff|Hitem:168185::::::::70:::::|h[Piedra porosa]|h|r",
    itemName = "Piedra porosa",
    buyout = 200000, totalPrice = 200000, bid = 160000,
    count = 100, deposit = 10000, duration = 2, price = 2000,
    timestamp = now - 86400, status = "active", source = source
  })

  table.insert(data.postings, {
    itemID = 168185,
    itemLink = "|cffffffff|Hitem:168185::::::::70:::::|h[Piedra porosa]|h|r",
    itemName = "Piedra porosa",
    buyout = 100000, totalPrice = 100000, bid = 80000,
    count = 50, deposit = 5000, duration = 2, price = 2000,
    timestamp = now - 7200, status = "active", source = source
  })

  table.insert(data.postings, {
    itemID = 168185,
    itemLink = "|cffffffff|Hitem:168185::::::::70:::::|h[Piedra porosa]|h|r",
    itemName = "Piedra porosa",
    buyout = 150000, totalPrice = 150000, bid = 120000,
    count = 50, deposit = 7500, duration = 2, price = 3000,
    timestamp = now - 3600, status = "active", source = source
  })

  -- Bismuto: múltiples stacks para LIFO + AH protection
  local activeAuctionID = 999001
  table.insert(data.postings, {
    itemID = 210930,
    itemLink = "|cffffffff|Hitem:210930::::::::70:::::|h[Bismuto]|h|r",
    itemName = "Bismuto",
    buyout = 29072000, totalPrice = 29072000, bid = 24000000,
    count = 80, deposit = 1440000, duration = 2, price = 363400,
    timestamp = now - 1800, status = "active", source = source,
    auctionID = activeAuctionID
  })

  Dukonomics._testActiveAuctions = Dukonomics._testActiveAuctions or {}
  Dukonomics._testActiveAuctions[activeAuctionID] = {
    itemID = 210930, itemName = "Bismuto", quantity = 80, unitPrice = 363400
  }

  table.insert(data.postings, {
    itemID = 210930,
    itemLink = "|cffffffff|Hitem:210930::::::::70:::::|h[Bismuto]|h|r",
    itemName = "Bismuto",
    buyout = 18175000, totalPrice = 18175000, bid = 15000000,
    count = 50, deposit = 900000, duration = 2, price = 363400,
    timestamp = now - 21600, status = "active", source = source
  })

  table.insert(data.postings, {
    itemID = 210930,
    itemLink = "|cffffffff|Hitem:210930::::::::70:::::|h[Bismuto]|h|r",
    itemName = "Bismuto",
    buyout = 36340000, totalPrice = 36340000, bid = 30000000,
    count = 100, deposit = 1800000, duration = 2, price = 363400,
    timestamp = now - 14400, status = "active", source = source
  })

  table.insert(data.postings, {
    itemID = 210930,
    itemLink = "|cffffffff|Hitem:210930::::::::70:::::|h[Bismuto]|h|r",
    itemName = "Bismuto",
    buyout = 25000000, totalPrice = 25000000, bid = 20000000,
    count = 75, deposit = 1250000, duration = 2, price = 333333,
    timestamp = now - 10800, status = "active", source = source
  })

  table.insert(data.postings, {
    itemID = 210930,
    itemLink = "|cffffffff|Hitem:210930::::::::70:::::|h[Bismuto]|h|r",
    itemName = "Bismuto",
    buyout = 36340000, totalPrice = 36340000, bid = 30000000,
    count = 100, deposit = 1800000, duration = 2, price = 363400,
    timestamp = now - 7200, status = "active", source = source
  })

  table.insert(data.postings, {
    itemID = 210930,
    itemLink = "|cffffffff|Hitem:210930::::::::70:::::|h[Bismuto]|h|r",
    itemName = "Bismuto",
    buyout = 29072000, totalPrice = 29072000, bid = 24000000,
    count = 80, deposit = 1440000, duration = 2, price = 363400,
    timestamp = now - 3600, status = "active", source = source
  })

  -- Bolsa crepúsculo
  table.insert(data.postings, {
    itemID = 194019,
    itemLink = "|cffffffff|Hitem:194019::::::::70:::::|h[Bolsa de tejido del crepúsculo]|h|r",
    itemName = "Bolsa de tejido del crepúsculo",
    buyout = 5000000, totalPrice = 5000000, bid = 4000000,
    count = 1, deposit = 250000, duration = 2, price = 5000000,
    timestamp = now - 10800, status = "active", source = source
  })

  Dukonomics.Logger.print("|cff00ff00[READY]|r Run: /duk test todo")
end

local function ProcessSimulatedMail(mail, index)
  Dukonomics.Logger.print("  |cff888888[" .. index .. "]|r " .. mail.description)

  local data = mail.mailData
  if data.bid and data.count and data.count > 0 then
    data.grossTotal = data.bid
    data.unitPrice = math.floor(data.bid / data.count)
  end

  if mail.type == "sale" then
    local ok = Dukonomics.SalesService.ProcessSale(data.itemName, data.grossTotal, data.count)
    Dukonomics.Logger.print("    " .. (ok and "|cff00ff00✅ OK|r" or "|cffff0000❌ FAIL|r"))

  elseif mail.type == "purchase" then
    local itemID = data.itemLink and tonumber(data.itemLink:match("item:(%d+)"))
    Dukonomics.Data.AddPurchase({
      itemID = itemID,
      itemLink = data.itemLink,
      itemName = data.itemName,
      price = data.unitPrice,
      count = data.count,
      timestamp = time()
    })
    Dukonomics.Logger.print("    |cff9966ff✅ Purchase|r")

  elseif mail.type == "expired" then
    local itemInfo = data.subject:match("Subasta terminada: (.+)")
    if itemInfo then
      local itemName, qtyText = itemInfo:match("(.-)%s*%((%d+)%)$")
      local qty = tonumber(qtyText) or 1
      itemName = itemName or itemInfo

      local posting = Dukonomics.Data.FindNewestActivePostingWithQuantity(itemName, qty)
      if posting then
        Dukonomics.Data.ReducePostingQuantity(posting, qty, "expired")
        Dukonomics.Logger.print("    |cffff9900✅ Expired|r")
      else
        Dukonomics.Logger.print("    |cffff0000❌ No posting|r")
      end
    end

  elseif mail.type == "cancelled" then
    local itemInfo = data.subject:match("Subasta cancelada: (.+)")
    if itemInfo then
      local itemName, qtyText = itemInfo:match("(.-)%s*%((%d+)%)$")
      local qty = tonumber(qtyText) or 1
      itemName = itemName or itemInfo

      local posting = Dukonomics.Data.FindNewestActivePostingWithQuantity(itemName, qty)
      if posting then
        Dukonomics.Data.ReducePostingQuantity(posting, qty, "cancelled")
        Dukonomics.Logger.print("    |cffff0000✅ Cancelled|r")
      else
        Dukonomics.Logger.print("    |cffff0000❌ No posting|r")
      end
    end
  end
end

function Dukonomics.Testing.RunTests(testType)
  Dukonomics.Logger.print("|cffff00ff=== RUNNING TESTS ===|r")

  local testsToRun = {}
  for i, mail in ipairs(TEST_MAILS) do
    local run = not testType or testType == "todo" or testType == "all"
    if testType == "venta" or testType == "sale" then run = mail.type == "sale" end
    if testType == "compra" or testType == "purchase" then run = mail.type == "purchase" end
    if testType == "cancel" then run = mail.type == "cancelled" end
    if testType == "expired" then run = mail.type == "expired" end

    if run then table.insert(testsToRun, {index = i, mail = mail}) end
  end

  if #testsToRun == 0 then
    Dukonomics.Logger.print("|cffff0000No tests for: " .. tostring(testType) .. "|r")
    return
  end

  for _, test in ipairs(testsToRun) do
    ProcessSimulatedMail(test.mail, test.index)
  end

  Dukonomics.Logger.print("|cff00ff00=== TESTS COMPLETE ===|r")
  Dukonomics.Logger.print("Use |cff00ffff/duk status|r to check results")
end

function Dukonomics.Testing.ShowStatus()
  local data = Dukonomics.Data.GetDataStore()
  if not data or not data.postings then
    Dukonomics.Logger.print("No posting data")
    return
  end

  local counts = { active = 0, sold = 0, cancelled = 0, expired = 0 }

  Dukonomics.Logger.print("|cff00ffff=== POSTING STATUS ===|r")

  for i, posting in ipairs(data.postings) do
    local status = posting.status or "unknown"
    counts[status] = (counts[status] or 0) + 1

    local colors = {
      active = "|cff00ff00", sold = "|cffffff00",
      cancelled = "|cffff0000", expired = "|cffff9900"
    }
    local color = colors[status] or "|cffffffff"
    local price = posting.price and string.format("%.2fg/u", posting.price / 10000) or "?"

    Dukonomics.Logger.print(string.format("  %s[%d]|r %s x%d @ %s (%s)",
      color, i, posting.itemName or "?", posting.count or 0, price, status))
  end

  Dukonomics.Logger.print(string.format(
    "|cff00ffff[TOTALS]|r Active: %d | Sold: %d | Cancelled: %d | Expired: %d",
    counts.active, counts.sold, counts.cancelled, counts.expired))

  if data.purchases and #data.purchases > 0 then
    Dukonomics.Logger.print("|cff00ffff=== PURCHASES ===|r")
    for i, p in ipairs(data.purchases) do
      local price = p.price and string.format("%.2fg/u", p.price / 10000) or "?"
      Dukonomics.Logger.print(string.format("  |cff9966ff[%d]|r %s x%d @ %s",
        i, p.itemName or "?", p.count or 0, price))
    end
  end
end

function Dukonomics.Testing.ShowExpected()
  Dukonomics.Logger.print("|cff00ffff=== EXPECTED RESULTS ===|r")
  Dukonomics.Logger.print("")
  Dukonomics.Logger.print("|cffffff00After /duk sim + /duk test todo:|r")
  Dukonomics.Logger.print("")
  Dukonomics.Logger.print("|cff00ff00Piedra porosa:|r")
  Dukonomics.Logger.print("  - x100: |cffff9900EXPIRED|r")
  Dukonomics.Logger.print("  - x50 @ 20s: |cffffff00SOLD|r")
  Dukonomics.Logger.print("  - x50 @ 30s: |cffff0000CANCELLED|r")
  Dukonomics.Logger.print("")
  Dukonomics.Logger.print("|cff00ff00Bismuto (sale 300 @ 36.34g):|r")
  Dukonomics.Logger.print("  - |cffff0000x80 (in AH): ACTIVE|r (protected)")
  Dukonomics.Logger.print("  - x80, x100, x100: |cffffff00SOLD|r")
  Dukonomics.Logger.print("  - x75 @ 33.33g: |cff00ff00ACTIVE|r (different price)")
  Dukonomics.Logger.print("  - x50 (oldest): 30 |cff00ff00ACTIVE|r + 20 |cffffff00SOLD|r")
  Dukonomics.Logger.print("")
  Dukonomics.Logger.print("Expected: Active=3, Sold=5, Cancelled=2, Expired=1, Purchases=1")
end

function Dukonomics.Testing.GenerateRandomData()
  local now = time()
  local items = {
    {name = "Poción de maná superior", id = 13444, price = 5000},
    {name = "Aceite de amonita de fuego", id = 212663, price = 200},
    {name = "Esencia de tierra", id = 7076, price = 1500},
    {name = "Mineral de hierro", id = 2772, price = 800},
  }
  local statuses = {"active", "sold", "cancelled", "expired"}
  local source = {
    character = UnitName("player"),
    realm = GetRealmName(),
    faction = UnitFactionGroup("player")
  }

  local data = Dukonomics.Data.GetDataStore()

  for _ = 1, 50 do
    local item = items[math.random(#items)]
    table.insert(data.postings, {
      itemID = item.id,
      itemLink = "|cffffffff|Hitem:" .. item.id .. "::::::::70:::::|h[" .. item.name .. "]|h|r",
      itemName = item.name,
      buyout = item.price, bid = math.floor(item.price * 0.8),
      count = math.random(1, 20),
      deposit = math.floor(item.price * 0.05),
      duration = math.random(1, 3),
      price = item.price,
      timestamp = now - (math.random(1, 168) * 3600),
      status = statuses[math.random(#statuses)],
      source = source
    })
  end

  for _ = 1, 20 do
    local item = items[math.random(#items)]
    table.insert(data.purchases, {
      itemID = item.id,
      itemLink = "|cffffffff|Hitem:" .. item.id .. "::::::::70:::::|h[" .. item.name .. "]|h|r",
      itemName = item.name,
      price = item.price,
      count = math.random(1, 5),
      timestamp = now - (math.random(1, 168) * 3600),
      source = source
    })
  end

  Dukonomics.Logger.print("Random test data generated")
end
