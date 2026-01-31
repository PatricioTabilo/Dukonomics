-- Dukonomics: Minimap Button
-- Handles the minimap icon creation, positioning and interaction

Dukonomics.UI = Dukonomics.UI or {}
Dukonomics.UI.MinimapButton = {}

local ICON_PATH = "Interface\\AddOns\\Dukonomics\\Assets\\minimap"
-- Fallback if needed: "Interface\\Icons\\INV_Misc_Coin_01"

function Dukonomics.UI.MinimapButton.Initialize()
    -- Check for libraries
    local LDB = LibStub and LibStub("LibDataBroker-1.1", true)
    local icon = LibStub and LibStub("LibDBIcon-1.0", true)

    if not LDB then
        Dukonomics.Logger.error("Bibliotecas LibDataBroker no encontradas. Boton del minimapa desactivado.")
        return
    end

    -- Create Data Object
    local dukonomicsLDB = LDB:NewDataObject("Dukonomics", {
        type = "launcher",
        text = "Dukonomics",
        icon = ICON_PATH,

        OnClick = function(self, button)
            if button == "RightButton" then
                -- Open Options
                 if Dukonomics.Options and Dukonomics.Options.Open then
                    Dukonomics.Options.Open()
                 end
            else
                -- Toggle Main Window
                Dukonomics.UI.Toggle()
            end
        end,

        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Dukonomics")
            tooltip:AddLine(" ")
            tooltip:AddLine("|cffFFFFFF" .. Dukonomics.Loc("Left Click") .. ":|r " .. Dukonomics.Loc("Open Main Window"))
            tooltip:AddLine("|cffFFFFFF" .. Dukonomics.Loc("Right Click") .. ":|r " .. Dukonomics.Loc("Options"))
        end,
    })

    -- Register Icon with LibDBIcon
    if icon then
        local config = Dukonomics.ConfigRepository.GetMinimapConfig()

        if not config then
             -- Initialize defaults if missing (should be handled by repository but safety check)
             config = { minimapPos = 45, hide = false }
        end

        icon:Register("Dukonomics", dukonomicsLDB, config)
        Dukonomics.Logger.debug("Boton del minimapa registrado via LibDBIcon")
    end
end
