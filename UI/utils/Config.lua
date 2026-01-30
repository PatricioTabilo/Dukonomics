-- Dukonomics: UI Configuration
-- Constantes de colores, tamaños y columnas

Dukonomics.UI = Dukonomics.UI or {}
Dukonomics.UI.Config = {}

-- Colors (estilo WoW)
Dukonomics.UI.Config.COLORS = {
  BG = {0.1, 0.1, 0.1, 0.95},
  TITLE_BG = {0.15, 0.12, 0.08, 1},
  HEADER_BG = {0.18, 0.18, 0.18, 1},
  ROW_ODD = {0.14, 0.14, 0.14, 0.95},
  ROW_EVEN = {0.12, 0.12, 0.12, 0.95},
  ROW_HOVER = {0.25, 0.25, 0.3, 1},
  BORDER = {0.6, 0.5, 0.35, 1},
  GOLD = {1, 0.82, 0},
  FILTER_BG = {0.12, 0.12, 0.12, 1},
  BUTTON_BG = {0.15, 0.15, 0.15, 1},
  BUTTON_BORDER = {0.4, 0.4, 0.4, 1},
  HEADER_TEXT = {0.9, 0.85, 0.7},

  STATUS = {
    active = {0.5, 0.8, 1.0},
    sold = {0.4, 0.9, 0.4},
    cancelled = {1.0, 0.5, 0.5},
    expired = {1.0, 0.7, 0.3},
    purchased = {0.8, 0.6, 1.0},
  }
}

-- Layout dimensions
Dukonomics.UI.Config.SIZES = {
  FRAME_WIDTH = 1100,
  FRAME_HEIGHT = 550,
  ROW_HEIGHT = 28,
  HEADER_HEIGHT = 28,
  TITLE_HEIGHT = 28,
  FILTER_HEIGHT = 32,
}

-- Column configuration
Dukonomics.UI.Config.COLUMNS = {
  {key = "icon", width = 32},
  {key = "item", name = "Item", width = 250},
  {key = "qty", name = "Quantity", width = 80, align = "CENTER"},
  {key = "total", name = "Total", width = 140, align = "RIGHT"},
  {key = "status", name = "Status", width = 90, align = "CENTER"},
  {key = "char", name = "Character", width = 140},
  {key = "realm", name = "Realm", width = 130},
  {key = "posted", name = "Posted", width = 120},
  {key = "expiration", name = "Expiration", width = 120},
}
