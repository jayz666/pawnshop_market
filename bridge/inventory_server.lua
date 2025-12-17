InvS = InvS or {}

local function qbCore()
  return exports['qb-core']:GetCoreObject()
end

function InvS.GetCount(src, itemName)
  if Bridge.Inventory == 'ox' then
    return exports.ox_inventory:GetItemCount(src, itemName) or 0
  end

  local QBCore = qbCore()
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player then return 0 end
  local item = Player.Functions.GetItemByName(itemName)
  return item and item.amount or 0
end

function InvS.Remove(src, itemName, amount)
  if Bridge.Inventory == 'ox' then
    return exports.ox_inventory:RemoveItem(src, itemName, amount)
  end

  local QBCore = qbCore()
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player then return false end
  return Player.Functions.RemoveItem(itemName, amount)
end

function InvS.Add(src, itemName, amount)
  if Bridge.Inventory == 'ox' then
    return exports.ox_inventory:AddItem(src, itemName, amount)
  end

  local QBCore = qbCore()
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player then return false end
  return Player.Functions.AddItem(itemName, amount)
end
