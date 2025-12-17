Inv = Inv or {}


-- Helper to get QBCore object
local function qbCore()
  return exports['qb-core']:GetCoreObject()
end

-- Returns a filtered list of player's inventory items (no weapons/serials)
function Inv.GetPlayerInventory()
  -- OX Inventory logic
  if Bridge.Inventory == 'ox' then
    local items = exports.ox_inventory:GetPlayerItems()
    local inv = {}
    for _, item in pairs(items or {}) do
      -- Only include items with a name and count > 0, skip serials
      if item.name and item.count and item.count > 0 then
        if not (item.metadata and item.metadata.serial) then
          inv[#inv+1] = { name = item.name, count = item.count }
        end
      end
    end
    return inv
  end

  -- QB Inventory logic
  local QBCore = qbCore()
  local PlayerData = QBCore.Functions.GetPlayerData()
  local inv = {}

  for _, item in pairs(PlayerData.items or {}) do
    -- Only include items with a name and amount > 0, skip weapons/serials
    if item.name and item.amount and item.amount > 0 then
      if not (item.type == 'weapon' or (item.info and item.info.serial)) then
        inv[#inv+1] = { name = item.name, count = item.amount }
      end
    end
  end

  return inv
end
