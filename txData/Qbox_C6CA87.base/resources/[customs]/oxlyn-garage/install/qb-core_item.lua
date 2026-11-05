

-- ════════════════════════════════════════════════════════════════════════
--  OXLYN Garage — qb-core / Qbox item (qb-inventory, ps-inventory,
--  lj-inventory, qs-inventory, …)
--  Paste inside qb-core/shared/items.lua and copy the two images from
--  oxlyn-garage/images/ into your inventory's html/images (or images/)
--  folder. The garage registers the item as usable by itself.
-- ════════════════════════════════════════════════════════════════════════

['vehicle_contract'] = {
    name = 'vehicle_contract',
    label = 'Vehicle Sale Contract',
    weight = 50,
    type = 'item',
    image = 'vehicle_contract.png',
    unique = true,
    useable = true,
    shouldClose = true,
    combinable = nil,
    description = 'A vehicle sale agreement. Sit in your vehicle with the buyer and use it to sell the vehicle on the spot.',
},

