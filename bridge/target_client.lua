Target = Target or {}

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

function Target.RegisterShop(shop, handlers)
  if Bridge.Target == 'qb' then
    addQbTarget(shop, handlers)
  else
    addOxTarget(shop, handlers)
  end
end
