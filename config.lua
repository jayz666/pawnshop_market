Config = {}

Config.AutoDetect = true

-- If AutoDetect=false:
Config.Inventory = 'ox'   -- 'ox' or 'qb'
Config.Target = 'ox'      -- 'ox' or 'qb'
Config.Menu = 'ox'        -- 'ox' or 'qb'
Config.Money = 'qb'       -- 'qb' or 'ox_item'
Config.CurrencyItem = 'money' -- used only if Money='ox_item'
Config.JunkRules.MaxDaysWithSale = 7

-- Market tuning
Config.BuyMarkup = 1.35
Config.MaxStockDiscount = 0.80
Config.StockScale = 100
Config.EnableStockDecay = true
Config.StockDecayPerHour = 1

-- Learning / Junk filtering
Config.Learning = {
  DefaultBase = 50,          -- base price used until history exists
  MinHistoryForLearned = 5,  -- after this, base price becomes learned AVG
}

Config.JunkRules = {
  MinHistoryCount = 3, -- after X history rows, apply junk filter
  MinSellUnitPrice = 5 -- if unit price below this and has enough history -> ignore
}

-- Quantity presets
Config.QuantityPresets = { 1, 5, 10 }

-- Shops
Config.Shops = {
  {
    id = 'davis',
    label = 'Davis Pawn',
    coords = vec3(412.3, 314.1, 103.1),
    radius = 2.0,
    npc = { enabled = true, model = 'a_m_m_business_01', heading = 90.0 }
  },
  {
    id = 'sandy',
    label = 'Sandy Pawn',
    coords = vec3(139.1, 3538.9, 35.0),
    radius = 2.0,
    npc = { enabled = false }
  }
}
