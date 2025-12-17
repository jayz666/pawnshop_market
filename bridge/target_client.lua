Target = Target or {}


-- Register pawnshop zone with ox_target
local function addOxTarget(shop, handlers)
  exports.ox_target:addSphereZone({
    coords = shop.coords,
    radius = shop.radius,
    options = {
      { label = 'Sell Items', icon = 'fa-hand-holding-dollar', onSelect = function() handlers.sell(shop) end },
      { label = 'Buy Items',  icon = 'fa-cart-shopping',       onSelect = function() handlers.buy(shop) end  },
      { label = 'View Stock', icon = 'fa-box',                 onSelect = function() handlers.stock(shop) end},
    }
  })
end


-- Register pawnshop zone with qb-target
local function addQbTarget(shop, handlers)
  exports['qb-target']:AddCircleZone(
    ('pawn_%s'):format(shop.id),
    shop.coords,
    shop.radius,
    { useZ = true },
    {
      options = {
        { label = 'Sell Items', action = function() handlers.sell(shop) end },
        { label = 'Buy Items',  action = function() handlers.buy(shop) end  },
        { label = 'View Stock', action = function() handlers.stock(shop) end},
      },
      distance = math.max(shop.radius, 2.0)
    }
  )
end


-- Register a pawnshop with the appropriate target system
function Target.RegisterShop(shop, handlers)
  -- Validation for shop fields
  if not shop or type(shop) ~= 'table' then
    print('[pawnshop_market] ERROR: shop is nil or not a table!')
    return
  end
  if not shop.id then print('[pawnshop_market] WARNING: shop.id is missing!') end
  if not shop.coords or type(shop.coords) ~= 'vector3' then print('[pawnshop_market] WARNING: shop.coords is missing or not a vector3!') end
  if not shop.radius or type(shop.radius) ~= 'number' then print('[pawnshop_market] WARNING: shop.radius is missing or not a number!') end

  -- Validation for handlers
  if not handlers or type(handlers) ~= 'table' then
    print('[pawnshop_market] ERROR: handlers is nil or not a table!')
    return
  end
  if type(handlers.sell) ~= 'function' then print('[pawnshop_market] WARNING: handlers.sell is missing or not a function!') end
  if type(handlers.buy) ~= 'function' then print('[pawnshop_market] WARNING: handlers.buy is missing or not a function!') end
  if type(handlers.stock) ~= 'function' then print('[pawnshop_market] WARNING: handlers.stock is missing or not a function!') end

  if Bridge.Target == 'qb' then
    addQbTarget(shop, handlers)
  else
    addOxTarget(shop, handlers)
  end
end
