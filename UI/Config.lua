-- UI Configuration: colors, dimensions, columns

Dukonomics.UI = Dukonomics.UI or {}
Dukonomics.UI.Config = {}

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

Dukonomics.UI.Config.SIZES = {
  FRAME_WIDTH = 1180,
  FRAME_HEIGHT = 600,
  ROW_HEIGHT = 28,
  HEADER_HEIGHT = 30,
  TITLE_HEIGHT = 28,
  FILTER_HEIGHT = 32,
}

Dukonomics.UI.Config.COLUMNS = {
  {key = "icon", width = 28},
  {key = "item", name = "Item", width = 250},
  {key = "qty", name = "Qty", width = 55, align = "CENTER"},
  {key = "unitPrice", name = "Unit Price", width = 125, align = "RIGHT"},
  {key = "total", name = "Total", width = 135, align = "RIGHT"},
  {key = "status", name = "Status", width = 85, align = "CENTER"},
  {key = "char", name = "Character", width = 120},
  {key = "realm", name = "Realm", width = 115},
  {key = "posted", name = "Posted", width = 100},
  {key = "expiration", name = "Expiration", width = 100},
}
