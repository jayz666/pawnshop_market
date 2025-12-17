local LastOffers = {} -- LastOffers[src][shopId][item] = { maxCount, unitSell }

local function clamp(n,a,b) return math.max(a, math.min(b, n)) end

-- =========================
-- STOCK + HISTORY HELPERS
-- =========================
local function getStock(shopId, item)
  local row = MySQL.single.await(
    'SELECT stock FROM pawnshop_stock WHERE shop_id = ? AND item = ?',
    { shopId, item }
  )
  return row and row.stock or 0
end

local function addStock(shopId, item, delta)
  MySQL.prepare.await([[
    INSERT INTO pawnshop_stock (shop_id, item, stock)
    VALUES (?, ?, ?)
    ON DUPLICATE KEY UPDATE stock = GREATEST(stock + VALUES(stock), 0)
  ]], { shopId, item, delta })
end

local function addHistory(shopId, item, action, unitPrice, qty)
  -- use await so it’s consistent (and easier to debug)
  MySQL.prepare.await([[
    INSERT INTO pawnshop_history (shop_id, item, action, unit_price, qty)
    VALUES (?, ?, ?, ?, ?)
  ]], { shopId, item, action, unitPrice, qty })
end

-- =========================
-- LEARNED BASE PRICE
-- =========================
local function getLearnedBase(item)
  local row = MySQL.single.await([[
    SELECT COUNT(*) c, AVG(unit_price) avgp
    FROM pawnshop_history
    WHERE item = ? AND action='sell'
  ]], { item })

  local c = row and row.c or 0
  if c >= Config.Learning.MinHistoryForLearned then
    return math.max(math.floor(row.avgp or Config.Learning.DefaultBase), 1), c
  end

  return Config.Learning.DefaultBase, c
end

-- =========================
-- TIME-BASED JUNK CHECK (MySQL handles dates)
-- =========================
local function isTimeJunk(item)
  local days = tonumber(Config.JunkRules.MaxDaysWithoutSale or 0)
  if days <= 0 then return false end

  local row = MySQL.single.await([[
    SELECT DATEDIFF(NOW(), MAX(ts)) AS days_since
    FROM pawnshop_history
    WHERE item = ? AND action = 'sell'
  ]], { item })

  if not row or row.days_since == nil then
    return false -- never sold before, allow it (so it can be discovered)
  end

  return tonumber(row.days_since) > days
end

-- =========================
-- MARKET MOOD (NPC dialogue)
-- =========================
local function getMarketMood(shopId, item)
  local stock = getStock(shopId, item)
  if stock >= Config.StockScale * 0.7 then return 'crash' end
  if stock <= Config.StockScale * 0.1 then return 'hot' end
  return 'normal'
end

-- =========================
-- PRICE COMPUTE
-- =========================
local function computeSellUnit(shopId, item)
  local base, histCount = getLearnedBase(item)
  local stock = getStock(shopId, item)

  local stockFactor = 1.0 - math.min(stock / Config.StockScale, Config.MaxStockDiscount)
  local unit = math.max(math.floor(base * stockFactor), 1)

  -- Junk filter by unit price (only once it has some history)
  if histCount >= Config.JunkRules.MinHistoryCount and unit < Config.JunkRules.MinSellUnitPrice then
    return nil
  end

  -- Junk filter by time since last sale (MySQL-based)
  if isTimeJunk(item) then
    return nil
  end

  return unit
end

local function computeBuyUnit(shopId, item)
  local sellUnit = computeSellUnit(shopId, item) or Config.Learning.DefaultBase
  return math.max(math.floor(sellUnit * Config.BuyMarkup), 1)
end

-- =========================
-- SCAN INVENTORY / OFFERS
-- =========================
RegisterNetEvent('pawn:ScanInventory', function(shopId, inventory)
  local src = source
  LastOffers[src] = LastOffers[src] or {}
  LastOffers[src][shopId] = {}

  local offers = {}

  for _, it in pairs(inventory or {}) do
    if it.name and it.count and it.count > 0 then
      local unit = computeSellUnit(shopId, it.name)
      if unit then
        offers[#offers+1] = {
          name = it.name,
          count = it.count,
          unit_price = unit,
          total_price = unit * it.count
        }
        LastOffers[src][shopId][it.name] = { maxCount = it.count, unitSell = unit }
      end
    end
  end

  TriggerClientEvent('pawn:ShowSellOffers', src, shopId, offers)
end)

-- =========================
-- SELL
-- =========================
RegisterNetEvent('pawn:SellItem', function(shopId, item, qtyReq)
  local src = source
  local offer = LastOffers[src] and LastOffers[src][shopId] and LastOffers[src][shopId][item]
  if not offer then
    Money.Notify(src, 'No valid offer for that item.', 'error')
    return
  end

  local qty = clamp(tonumber(qtyReq) or 0, 1, offer.maxCount)
  local have = InvS.GetCount(src, item)
  if have < qty then
    Money.Notify(src, "You don't have enough.", 'error')
    return
  end

  local payout = offer.unitSell * qty

  if not InvS.Remove(src, item, qty) then
    Money.Notify(src, 'Failed to remove item.', 'error')
    return
  end

  Money.Add(src, payout)
  addStock(shopId, item, qty)
  addHistory(shopId, item, 'sell', offer.unitSell, qty)

  Money.Notify(src, ('Sold %s x%d for $%d'):format(item, qty, payout), 'success')

  -- NPC mood
  TriggerClientEvent('pawn:NpcTalk', src, getMarketMood(shopId, item), item)
end)

-- =========================
-- STOCK VIEW
-- =========================
RegisterNetEvent('pawn:GetStock', function(shopId)
  local src = source
  local rows = MySQL.query.await([[
    SELECT item, stock
    FROM pawnshop_stock
    WHERE shop_id = ? AND stock > 0
    ORDER BY stock DESC
    LIMIT 100
  ]], { shopId }) or {}

  TriggerClientEvent('pawn:ShowStock', src, shopId, rows)
end)

-- =========================
-- BUY LIST
-- =========================
RegisterNetEvent('pawn:GetBuyList', function(shopId)
  local src = source
  local rows = MySQL.query.await([[
    SELECT item, stock
    FROM pawnshop_stock
    WHERE shop_id = ? AND stock > 0
    ORDER BY stock DESC
    LIMIT 50
  ]], { shopId }) or {}

  for _, r in pairs(rows) do
    r.buy_unit = computeBuyUnit(shopId, r.item)
  end

  TriggerClientEvent('pawn:ShowBuyMenu', src, shopId, rows)
end)

-- =========================
-- BUY
-- =========================
RegisterNetEvent('pawn:BuyItem', function(shopId, item, qtyReq)
  local src = source
  local qty = clamp(tonumber(qtyReq) or 1, 1, 50)

  local stock = getStock(shopId, item)
  if stock < qty then
    Money.Notify(src, 'Not enough stock.', 'error')
    return
  end

  local unit = computeBuyUnit(shopId, item)
  local cost = unit * qty

  if not Money.Remove(src, cost) then
    Money.Notify(src, "You don't have enough money.", 'error')
    return
  end

  if not InvS.Add(src, item, qty) then
    Money.Add(src, cost)
    Money.Notify(src, 'Could not give item (refunded).', 'error')
    return
  end

  addStock(shopId, item, -qty)
  addHistory(shopId, item, 'buy', unit, qty)

  Money.Notify(src, ('Bought %s x%d for $%d'):format(item, qty, cost), 'success')

  -- NPC mood
  TriggerClientEvent('pawn:NpcTalk', src, getMarketMood(shopId, item), item)
end)

-- =========================
-- PRICE HISTORY (10 rows)
-- =========================
RegisterNetEvent('pawn:GetPriceHistory', function(shopId, item)
  local src = source
  local rows = MySQL.query.await([[
    SELECT action, unit_price, qty, ts
    FROM pawnshop_history
    WHERE shop_id = ? AND item = ?
    ORDER BY ts DESC
    LIMIT 10
  ]], { shopId, item }) or {}

  TriggerClientEvent('pawn:ShowPriceHistory', src, shopId, item, rows)
end)

-- =========================
-- HISTORY LIST (latest per item)
-- =========================
RegisterNetEvent('pawn:GetHistoryList', function(shopId)
  local src = source
  local rows = MySQL.query.await([[
    SELECT h1.item, h1.action, h1.unit_price
    FROM pawnshop_history h1
    INNER JOIN (
      SELECT item, MAX(ts) max_ts
      FROM pawnshop_history
      WHERE shop_id = ?
      GROUP BY item
    ) h2
    ON h1.item = h2.item AND h1.ts = h2.max_ts
    WHERE h1.shop_id = ?
    ORDER BY h1.ts DESC
    LIMIT 50
  ]], { shopId, shopId }) or {}

  TriggerClientEvent('pawn:ShowHistoryList', src, shopId, rows)
end)

-- =========================
-- GRAPH DATA (50 rows, ASC)
-- =========================
RegisterNetEvent('pawn:GetGraphData', function(shopId, item)
  local src = source
  local rows = MySQL.query.await([[
    SELECT unit_price, action, ts
    FROM pawnshop_history
    WHERE shop_id = ? AND item = ?
    ORDER BY ts ASC
    LIMIT 50
  ]], { shopId, item }) or {}

  TriggerClientEvent('pawn:OpenGraph', src, shopId, item, rows)
end)

-- =========================
-- CLEANUP (avoid memory bloat)
-- =========================
AddEventHandler('playerDropped', function()
  local src = source
  LastOffers[src] = nil
end)

-- =========================
-- STOCK DECAY
-- =========================
if Config.EnableStockDecay then
  CreateThread(function()
    while true do
      Wait(60 * 60 * 1000)
      local d = tonumber(Config.StockDecayPerHour) or 0
      if d > 0 then
        MySQL.query([[
          UPDATE pawnshop_stock
          SET stock = GREATEST(stock - ?, 0)
          WHERE stock > 0
        ]], { d })
      end
    end
  end)
end
