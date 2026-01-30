-- Dukonomics Localization
-- Handles localized strings for different WoW client languages

Dukonomics.L = {}

-- Auction House sender names by locale
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

-- Helper function to get localized string
function Dukonomics.Loc(key)
    local locale = GetLocale and GetLocale() or "enUS"  -- Fallback for testing
    local strings = Dukonomics.L[key]
    if strings and strings[locale] then
        return strings[locale]
    elseif strings and strings["enUS"] then
        return strings["enUS"]  -- Fallback to English
    else
        return key  -- Fallback to key itself
    end
end
