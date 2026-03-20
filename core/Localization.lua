Dukonomics.L = {}

Dukonomics.L["Auction House Sender"] = {
  ["enUS"] = "Auction House",
  ["enGB"] = "Auction House",
  ["esES"] = "Casa de subastas",
  ["esMX"] = "Casa de subastas",
  ["frFR"] = "Hôtel des Ventes",
  ["deDE"] = "Auktionshaus",
  ["ptBR"] = "Casa de Leilões",
  ["itIT"] = "Casa d'Aste",
  ["ruRU"] = "Аукционный дом",
  ["koKR"] = "경매장",
  ["zhCN"] = "拍卖行",
  ["zhTW"] = "拍賣場",
}

Dukonomics.L["Left Click"] = {
  ["enUS"] = "Left Click",
  ["esES"] = "Clic Izquierdo",
  ["esMX"] = "Clic Izquierdo",
  ["ruRU"] = "ЛКМ",
}

Dukonomics.L["Right Click"] = {
  ["enUS"] = "Right Click",
  ["esES"] = "Clic Derecho",
  ["esMX"] = "Clic Derecho",
  ["ruRU"] = "ПКМ",  
}

Dukonomics.L["Open Main Window"] = {
  ["enUS"] = "Open Main Window",
  ["esES"] = "Abrir Ventana Principal",
  ["esMX"] = "Abrir Ventana Principal",
  ["ruRU"] = "Открыть главное окно",  
}

Dukonomics.L["Options"] = {
  ["enUS"] = "Options",
  ["esES"] = "Opciones",
  ["esMX"] = "Opciones",
  ["ruRU"] = "Настройки",  
}

function Dukonomics.Loc(key)
  local locale = GetLocale and GetLocale() or "enUS"
  local strings = Dukonomics.L[key]
  if strings and strings[locale] then
    return strings[locale]
  elseif strings and strings["enUS"] then
    return strings["enUS"]
  else
    return key
  end
end
