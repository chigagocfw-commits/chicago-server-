--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/tndFR89Sye - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.st/
--]]

Config = {}

Config.Currency = 'cash'

Config.UseTarget = false 

Config.DepositPercent = 0.25

Config.RefundPercent = 0.15 

Config.ImageBaseUrl = 'https://docs.fivem.net/vehicles/'

Config.ServerLogo = 'https://media.discordapp.net/attachments/1427935145796833290/1526988974663401524/c5cfb0e4-f7d1-4127-bd63-7a71786ff5a4-removebg-preview_1.png?ex=6a5906cd&is=6a57b54d&hm=c09cffa8eb56c4837f11851096dd02d97357955392554f8ad1f70c04767d7bb3&=&format=webp&quality=lossless'

Config.BrandName = 'LB Rental'
Config.BrandSub = 'Premium Vehicles'

Config.Labels = {
    searchPlaceholder = 'Search vehicles...',
    vehCount = 'vehicles',
    rentBadge = 'Rent',
    priceSuffix = '/hr',
    returnTitle = 'Return Vehicle',
    returnSub = 'End your rental',
    returnCardTitle = 'Finish Rental?',
    returnCardDesc = 'Return the vehicle to receive your deposit refund',
    returnConfirmBtn = 'Confirm Return',
    returnCancelBtn = 'Cancel',
    confirmDurationLabel = 'Rental Duration',
    confirmDepositLabel = 'Deposit (25%)',
    confirmTotalLabel = 'Total Charge',
    confirmRentBtn = 'Confirm Rental',
    confirmCancelBtn = 'Cancel',
    noVehicles = 'No vehicles available',
    noMatch = 'No vehicles match',
    loading = 'Loading vehicles...',
    noRentalData = 'No rental data',
}

Config.Blip = {
    sprite = 225,
    color = 1, 
    scale = 0.8,
    label = 'Car Rental',
}

Config.NPC = {
    model = 's_m_y_valet_01',
    scenario = 'WORLD_HUMAN_CLIPBOARD',
}

Config.Locations = {
    {
        name = 'Downtown Rental',
        coords = vector4(215.17, -810.29, 30.72, 340.0),
    },
    {
        name = 'Airport Rental',
        coords = vector4(-1034.43, -2737.11, 20.17, 330.0),
    },
    {
        name = 'Paleto Bay Rental',
        coords = vector4(-322.25, 6253.81, 31.49, 225.0),
    },
}

Config.Vehicles = {
    {
        model = 'adder',
        label = 'Adder',
        price = 500,
        category = 'super',
        image = 'https://docs.fivem.net/vehicles/adder.webp',
        stats = { speed = 9.5, accel = 8.5, braking = 7.0, handling = 7.5 },
    },
    {
        model = 'zentorno',
        label = 'Zentorno',
        price = 450,
        category = 'super',
        image = 'https://docs.fivem.net/vehicles/zentorno.webp',
        stats = { speed = 9.0, accel = 9.0, braking = 7.5, handling = 8.0 },
    },
    {
        model = 'sultan',
        label = 'Sultan',
        price = 150,
        category = 'sports',
        image = 'https://docs.fivem.net/vehicles/sultan.webp',
        stats = { speed = 7.0, accel = 6.5, braking = 6.0, handling = 7.0 },
    },
    {
        model = 'sentinel',
        label = 'Sentinel',
        price = 120,
        category = 'coupes',
        image = 'https://docs.fivem.net/vehicles/sentinel.webp',
        stats = { speed = 6.5, accel = 6.0, braking = 6.5, handling = 7.5 },
    },
    {
        model = 'dilettante',
        label = 'Dilettante',
        price = 50,
        category = 'compacts',
        image = 'https://docs.fivem.net/vehicles/dilettante.webp',
        stats = { speed = 4.0, accel = 4.5, braking = 5.0, handling = 6.0 },
    },
    {
        model = 'bati',
        label = 'Bati 801',
        price = 100,
        category = 'motorcycles',
        image = 'https://docs.fivem.net/vehicles/bati.webp',
        stats = { speed = 8.5, accel = 8.0, braking = 5.0, handling = 8.5 },
    },
    {
        model = 'schafter2',
        label = 'Schafter',
        price = 180,
        category = 'sedans',
        image = 'https://docs.fivem.net/vehicles/schafter2.webp',
        stats = { speed = 6.0, accel = 5.5, braking = 6.5, handling = 6.5 },
    },
    {
        model = 'xls',
        label = 'XLS',
        price = 200,
        category = 'suvs',
        image = 'https://docs.fivem.net/vehicles/xls.webp',
        stats = { speed = 5.5, accel = 5.0, braking = 6.0, handling = 6.0 },
    },
}

