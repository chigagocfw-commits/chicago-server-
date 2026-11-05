

-- ════════════════════════════════════════════════════════════════════════
--  OXLYN Garage — ox_inventory item
--  Paste inside ox_inventory/data/items.lua and copy the two images from
--  oxlyn-garage/images/ into ox_inventory/web/images/.
--
--  `server.export` makes ox_inventory hand the use to the garage script,
--  which opens the agreement paper and removes the sheet itself when the
--  sale completes (Config.Contract.consumeItem) — that is why consume = 0.
-- ════════════════════════════════════════════════════════════════════════

['vehicle_contract'] = {
    label = 'Vehicle Sale Contract',
    weight = 50,
    stack = false,
    close = true,
    consume = 0,
    description = 'A vehicle sale agreement. Sit in your vehicle with the buyer and use it to sell the vehicle on the spot.',
    server = { export = 'oxlyn-garage.vehicle_contract' },
},

