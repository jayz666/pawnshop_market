InvS = InvS or {}


-- Helper to get QBCore object, with error handling
local function qbCore()
  local ok, obj = pcall(function() return exports['qb-core']:GetCoreObject() end)
  if not ok or not obj then
    print('[pawnshop_market] ERROR: qb-core export not found!')
    return nil
  end
  return obj
end


-- Returns the count of a specific item in a player's inventory
function InvS.GetCount(src, itemName)
  -- OX Inventory logic
  if Bridge.Inventory == 'ox' then
    if not exports.ox_inventory then
      print('[pawnshop_market] ERROR: ox_inventory export not found!')
      return 0
    end
    return exports.ox_inventory:GetItemCount(src, itemName) or 0
  end

  -- QB Inventory logic
  local QBCore = qbCore()
  if not QBCore then return 0 end
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player then return 0 end
  local item = Player.Functions.GetItemByName(itemName)
  return item and item.amount or 0
end


-- Removes a specific item from a player's inventory
function InvS.Remove(src, itemName, amount)
  -- OX Inventory logic
  if Bridge.Inventory == 'ox' then
    if not exports.ox_inventory then
      print('[pawnshop_market] ERROR: ox_inventory export not found!')
      return false
    end
    return exports.ox_inventory:RemoveItem(src, itemName, amount)
  end

  -- QB Inventory logic
  local QBCore = qbCore()
  if not QBCore then return false end
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player then return false end
  return Player.Functions.RemoveItem(itemName, amount)
end


-- Adds a specific item to a player's inventory
function InvS.Add(src, itemName, amount)
  -- OX Inventory logic
  if Bridge.Inventory == 'ox' then
    if not exports.ox_inventory then
      print('[pawnshop_market] ERROR: ox_inventory export not found!')
      return false
    end
    return exports.ox_inventory:AddItem(src, itemName, amount)
  end

  -- QB Inventory logic
  local QBCore = qbCore()
  if not QBCore then return false end
  local Player = QBCore.Functions.GetPlayer(src)
  if not Player then return false end
  return Player.Functions.AddItem(itemName, amount)
end
