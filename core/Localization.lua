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
