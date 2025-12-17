Bridge = Bridge or {}

local function running(name)
  return GetResourceState(name) == 'started'
end

function Bridge.Detect()
  if not Config.AutoDetect then
    Bridge.Inventory = Config.Inventory
    Bridge.Target = Config.Target
    Bridge.Menu = Config.Menu
    Bridge.Money = Config.Money
    return
  end

  Bridge.Inventory = running('ox_inventory') and 'ox' or (running('qb-inventory') and 'qb' or 'ox')
  Bridge.Target    = running('ox_target') and 'ox' or (running('qb-target') and 'qb' or 'ox')
  Bridge.Menu      = running('ox_lib') and 'ox' or (running('qb-menu') and 'qb' or 'ox')
  Bridge.Money     = running('qb-core') and 'qb' or 'ox_item'
end

Bridge.Detect()
