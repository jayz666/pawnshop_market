-- =========================
-- SHOP LOOKUP HELPER
-- =========================
local ShopIndex = {}
local ShopPeds = {}

CreateThread(function()
    for _, shop in pairs(Config.Shops) do
        ShopIndex[shop.id] = shop
    end
end)

-- =========================
-- NPC SPAWNING
-- =========================
local function spawnNpc(shop)
    if not (shop.npc and shop.npc.enabled) then return end

    local model = joaat(shop.npc.model)
    RequestModel(model)
    while not HasModelLoaded(model) do Wait(50) end

    local ped = CreatePed(
        4,
        model,
        shop.coords.x,
        shop.coords.y,
        shop.coords.z - 1.0,
        shop.npc.heading or 0.0,
        false,
        false
    )

    SetEntityInvincible(ped, true)
    FreezeEntityPosition(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- Store ped reference by shop id
    ShopPeds[shop.id] = ped
end

-- =========================
-- INITIALIZE SHOPS
-- =========================
CreateThread(function()
    for _, shop in pairs(Config.Shops) do
        spawnNpc(shop)

        Target.RegisterShop(shop, {
            sell = function(s)
                TriggerEvent('pawn:FaceNpc', s.id)
                TriggerServerEvent('pawn:ScanInventory', s.id, Inv.GetPlayerInventory())
            end,

            buy = function(s)
                TriggerEvent('pawn:FaceNpc', s.id)
                TriggerServerEvent('pawn:GetBuyList', s.id)
            end,

            stock = function(s)
                TriggerEvent('pawn:FaceNpc', s.id)
                TriggerServerEvent('pawn:GetStock', s.id)
            end
        })

    -- Make the shop NPC face the player when interacting
    RegisterNetEvent('pawn:FaceNpc', function(shopId)
        local ped = ShopPeds[shopId]
        if not ped or not DoesEntityExist(ped) then return end
        local playerPed = PlayerPedId()
        TaskTurnPedToFaceEntity(ped, playerPed, 1000)

        -- Play a random animation for the NPC
        local anims = {
            { dict = 'mp_common', name = 'givetake1_a' }, -- handover
            { dict = 'amb@prop_human_bum_bin@idle_b', name = 'idle_d' }, -- inspect
            { dict = 'anim@mp_player_intcelebrationmale@thumbs_up', name = 'thumbs_up' }, -- greeting
            { dict = 'anim@mp_player_intincarbodhi@ps', name = 'idle_a' }, -- casual
            { dict = 'anim@mp_player_intcelebrationmale@face_palm', name = 'face_palm' }, -- fun
        }
        local anim = anims[math.random(#anims)]
        RequestAnimDict(anim.dict)
        local timeout = 0
        while not HasAnimDictLoaded(anim.dict) and timeout < 100 do Wait(10) timeout = timeout + 1 end
        if HasAnimDictLoaded(anim.dict) then
            TaskPlayAnim(ped, anim.dict, anim.name, 8.0, -8.0, 2000, 49, 0, false, false, false)
        end
    end)
    end
end)

-- =========================
-- SELL MENU
-- =========================
RegisterNetEvent('pawn:ShowSellOffers', function(shopId, offers)
    local shop = ShopIndex[shopId]
    if not shop then return end

    Menu.ShowSell(shop, offers)
end)

-- =========================
-- BUY MENU
-- =========================
RegisterNetEvent('pawn:ShowBuyMenu', function(shopId, rows)
    local shop = ShopIndex[shopId]
    if not shop then return end

    Menu.ShowBuy(shop, rows)
end)

-- =========================
-- STOCK MENU
-- =========================
RegisterNetEvent('pawn:ShowStock', function(shopId, rows)
    local shop = ShopIndex[shopId]
    if not shop then return end

    Menu.ShowStock(shop, rows)
end)

-- =========================
-- PRICE HISTORY (ITEM)
-- =========================
RegisterNetEvent('pawn:ShowPriceHistory', function(shopId, item, rows)
    local shop = ShopIndex[shopId]
    if not shop then return end

    if not rows or #rows == 0 then
        Menu.Notify('No history for ' .. item)
        return
    end

    local opts = {}
    for _, r in pairs(rows) do
        opts[#opts + 1] = {
            title = string.format('%s  $%d', r.action:upper(), r.unit_price),
            description = string.format('Qty %d | %s', r.qty, r.ts)
        }
    end

    Menu.ShowSimple(shop.label .. ' – ' .. item .. ' History', opts)
end)

-- =========================
-- PRICE HISTORY (LIST)
-- =========================
RegisterNetEvent('pawn:ShowHistoryList', function(shopId, rows)
    local shop = ShopIndex[shopId]
    if not shop then return end

    if not rows or #rows == 0 then
        Menu.Notify('No history yet.')
        return
    end

    local opts = {}
    for _, r in pairs(rows) do
        opts[#opts + 1] = {
            title = r.item,
            description = string.format('Last: %s $%d', r.action, r.unit_price),
            onSelect = function()
                TriggerServerEvent('pawn:GetPriceHistory', shopId, r.item)
            end
        }
    end

    -- ox_lib
    if Bridge.Menu == 'ox' and lib then
        lib.registerContext({
            id = 'pawn_history_' .. shopId,
            title = shop.label .. ' – Market History',
            options = opts
        })
        lib.showContext('pawn_history_' .. shopId)
        return
    end

    -- qb-menu fallback
    local menu = {
        { header = shop.label .. ' – Market History', isMenuHeader = true }
    }

    for _, r in pairs(rows) do
        menu[#menu + 1] = {
            header = r.item,
            txt = string.format('Last: %s $%d', r.action, r.unit_price),
            params = {
                event = 'pawn:HistoryItemClient',
                args = { shopId = shopId, item = r.item }
            }
        }
    end

    menu[#menu + 1] = { header = 'Close', params = { event = '' } }
    exports['qb-menu']:openMenu(menu)
end)

RegisterNetEvent('pawn:HistoryItemClient', function(args)
    TriggerServerEvent('pawn:GetPriceHistory', args.shopId, args.item)
end)
