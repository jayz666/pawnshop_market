Bridge = Bridge or {}


-- Helper to check if a resource is running
local function running(name)
  return GetResourceState(name) == 'started'
end


-- Detects which framework/resources are running and sets integration accordingly
function Bridge.Detect()
  if not Config.AutoDetect then
    -- Use manual config if autodetect is off
    Bridge.Inventory = Config.Inventory
    Bridge.Target = Config.Target
    Bridge.Menu = Config.Menu
    Bridge.Money = Config.Money
    return
  end

  -- Auto-detect based on running resources
  Bridge.Inventory = running('ox_inventory') and 'ox' or (running('qb-inventory') and 'qb' or 'ox')
  Bridge.Target    = running('ox_target') and 'ox' or (running('qb-target') and 'qb' or 'ox')
  Bridge.Menu      = running('ox_lib') and 'ox' or (running('qb-menu') and 'qb' or 'ox')
  Bridge.Money     = running('qb-core') and 'qb' or 'ox_item'
end

Bridge.Detect()
