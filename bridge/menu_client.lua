Menu = Menu or {}

local hasOxLib = lib ~= nil
local hasQbMenu = GetResourceState('qb-menu') == 'started'

-- ======================
-- NOTIFY
-- ======================
function Menu.Notify(msg, kind)
    kind = kind or 'inform'
    if hasOxLib then
        lib.notify({ type = kind, description = msg })
    else
        TriggerEvent('QBCore:Notify', msg, kind == 'error' and 'error' or 'primary')
    end
end

-- ======================
-- KEYBOARD INPUT (QB fallback)
-- ======================
local function KeyboardInput(text)
    AddTextEntry('FMMC_KEY_TIP1', text)
    DisplayOnscreenKeyboard(1, 'FMMC_KEY_TIP1', '', '', '', '', '', 3)
    while UpdateOnscreenKeyboard() == 0 do Wait(0) end
    return GetOnscreenKeyboardResult()
end

-- ======================
-- CONFIRM DIALOG (OX + QB)
-- ======================
function Menu.Confirm(title, msg, cb)
    -- OX
    if Bridge.Menu == 'ox' and lib then
        local result = lib.alertDialog({
            header = title,
            content = msg,
            centered = true,
            cancel = true,
            labels = { confirm = 'Confirm', cancel = 'Cancel' }
        })

        if result == 'confirm' then
            cb()
        end
        return
    end

    -- QB fallback
    local res = KeyboardInput(msg .. ' (type YES)')
    if res and res:upper() == 'YES' then
        cb()
    end
end

-- ======================
-- SIMPLE LIST MENU
-- ======================
function Menu.ShowSimple(title, options)
    options = options or {}

    if Bridge.Menu == 'ox' and lib then
        lib.registerContext({
            id = 'pawn_simple_' .. title,
            title = title,
            options = options
        })
        lib.showContext('pawn_simple_' .. title)
        return
    end

    local menu = { { header = title, isMenuHeader = true } }
    for _, o in pairs(options) do
        menu[#menu + 1] = {
            header = o.title or 'Item',
            txt = o.description or ''
        }
    end
    menu[#menu + 1] = { header = 'Close', params = { event = '' } }
    exports['qb-menu']:openMenu(menu)
end

-- ======================
-- QUANTITY INPUT
-- ======================
local function AskQuantity(max)
    if Bridge.Menu == 'ox' and hasOxLib then
        local input = lib.inputDialog('Quantity', {
            { type = 'number', label = ('Amount (max %d)'):format(max), min = 1, max = max, required = true }
        })
        return input and tonumber(input[1])
    end

    local res = KeyboardInput(('Amount (max %d)'):format(max))
    local n = tonumber(res)
    if not n then return nil end
    return math.min(math.max(1, math.floor(n)), max)
end

-- ======================
-- MENU OPENERS
-- ======================
local function OpenOx(id, title, options)
    if not hasOxLib then return end
    lib.registerContext({ id = id, title = title, options = options })
    lib.showContext(id)
end

local function OpenQb(menu)
    if hasQbMenu then exports['qb-menu']:openMenu(menu) end
end

-- ======================
-- SELL MENU
-- ======================
function Menu.ShowSell(shop, offers)
    if not offers or #offers == 0 then
        Menu.Notify('Pawn is not interested right now.')
        return
    end

    if Bridge.Menu == 'ox' and hasOxLib then
        local opts = {}

        for _, o in pairs(offers) do
            opts[#opts + 1] = {
                title = o.name,
                description = ('$%d each | You have %d'):format(o.unit_price, o.count),
                onSelect = function()
                    local qty = AskQuantity(o.count)
                    if not qty then return end

                    Menu.Confirm(
                        'Confirm Sale',
                        ('Sell %d %s for $%d?'):format(qty, o.name, qty * o.unit_price),
                        function()
                            TriggerServerEvent('pawn:SellItem', shop.id, o.name, qty)
                        end
                    )
                end
            }
        end

        OpenOx('pawn_sell_' .. shop.id, shop.label .. ' – Sell Items', opts)
        return
    end

    -- QB MENU
    local menu = { { header = shop.label .. ' – Sell Items', isMenuHeader = true } }
    for _, o in pairs(offers) do
        menu[#menu + 1] = {
            header = o.name,
            txt = ('$%d each | You have %d'):format(o.unit_price, o.count),
            params = {
                event = 'pawn:SellItemClient',
                args = { shopId = shop.id, item = o.name, max = o.count, unit = o.unit_price }
            }
        }
    end
    menu[#menu + 1] = { header = 'Close', params = { event = '' } }
    OpenQb(menu)
end

RegisterNetEvent('pawn:SellItemClient', function(args)
    local qty = AskQuantity(args.max)
    if not qty then return end

    Menu.Confirm(
        'Confirm Sale',
        ('Sell %d %s for $%d?'):format(qty, args.item, qty * args.unit),
        function()
            TriggerServerEvent('pawn:SellItem', args.shopId, args.item, qty)
        end
    )
end)

-- ======================
-- BUY MENU
-- ======================
function Menu.ShowBuy(shop, rows)
    if not rows or #rows == 0 then
        Menu.Notify('Nothing for sale right now.')
        return
    end

    if Bridge.Menu == 'ox' and hasOxLib then
        local opts = {}

        for _, r in pairs(rows) do
            opts[#opts + 1] = {
                title = r.item,
                description = ('$%d each | Stock %d'):format(r.buy_unit, r.stock),
                onSelect = function()
                    local qty = AskQuantity(r.stock)
                    if not qty then return end

                    Menu.Confirm(
                        'Confirm Purchase',
                        ('Buy %d %s for $%d?'):format(qty, r.item, qty * r.buy_unit),
                        function()
                            TriggerServerEvent('pawn:BuyItem', shop.id, r.item, qty)
                        end
                    )
                end
            }
        end

        OpenOx('pawn_buy_' .. shop.id, shop.label .. ' – Buy Items', opts)
        return
    end

    -- QB MENU
    local menu = { { header = shop.label .. ' – Buy Items', isMenuHeader = true } }
    for _, r in pairs(rows) do
        menu[#menu + 1] = {
            header = r.item,
            txt = ('$%d each | Stock %d'):format(r.buy_unit, r.stock),
            params = {
                event = 'pawn:BuyItemClient',
                args = { shopId = shop.id, item = r.item, max = r.stock, unit = r.buy_unit }
            }
        }
    end
    menu[#menu + 1] = { header = 'Close', params = { event = '' } }
    OpenQb(menu)
end

RegisterNetEvent('pawn:BuyItemClient', function(args)
    local qty = AskQuantity(args.max)
    if not qty then return end

    Menu.Confirm(
        'Confirm Purchase',
        ('Buy %d %s for $%d?'):format(qty, args.item, qty * args.unit),
        function()
            TriggerServerEvent('pawn:BuyItem', args.shopId, args.item, qty)
        end
    )
end)

-- ======================
-- STOCK MENU
-- ======================
function Menu.ShowStock(shop, rows)
    if not rows or #rows == 0 then
        Menu.Notify('Pawn stock is empty.')
        return
    end

    local opts = {}
    for _, r in pairs(rows) do
        opts[#opts + 1] = {
            title = r.item,
            description = ('Stock: %d'):format(r.stock),
            onSelect = function()
                TriggerServerEvent('pawn:GetPriceHistory', shop.id, r.item)
            end
        }
    end

    if Bridge.Menu == 'ox' and hasOxLib then
        OpenOx('pawn_stock_' .. shop.id, shop.label .. ' – Stock', opts)
    else
        local menu = { { header = shop.label .. ' – Stock', isMenuHeader = true } }
        for _, r in pairs(rows) do
            menu[#menu + 1] = {
                header = r.item,
                txt = ('Stock: %d | Click for history'):format(r.stock),
                params = { event = 'pawn:HistoryItemClient', args = { shopId = shop.id, item = r.item } }
            }
        end
        menu[#menu + 1] = { header = 'Close', params = { event = '' } }
        OpenQb(menu)
    end
end
