Money = Money or {}

local function qbCore()
  return exports['qb-core']:GetCoreObject()
end

function Money.Add(src, amount)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return false end

  if Bridge.Money == 'qb' then
    local QBCore = qbCore()
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    Player.Functions.AddMoney('cash', amount, 'pawnshop-market')
    return true
  end

  return exports.ox_inventory:AddItem(src, Config.CurrencyItem, amount)
end

function Money.Remove(src, amount)
  amount = math.floor(tonumber(amount) or 0)
  if amount <= 0 then return false end

  if Bridge.Money == 'qb' then
    local QBCore = qbCore()
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    return Player.Functions.RemoveMoney('cash', amount, 'pawnshop-market')
  end

  return exports.ox_inventory:RemoveItem(src, Config.CurrencyItem, amount)
end

function Money.Notify(src, msg, kind)
  kind = kind or 'inform'
  if GetResourceState('ox_lib') == 'started' then
    TriggerClientEvent('ox_lib:notify', src, { type = kind, description = msg })
  else
    TriggerClientEvent('chat:addMessage', src, { args = { 'PAWN', msg } })
  end
end
