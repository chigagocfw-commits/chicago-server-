-- ░██████╗░███████╗███╗░░██╗███████╗██████╗░░█████╗░██╗░░░░░
-- ██╔════╝░██╔════╝████╗░██║██╔════╝██╔══██╗██╔══██╗██║░░░░░
-- ██║░░██╗░█████╗░░██╔██╗██║█████╗░░██████╔╝███████║██║░░░░░
-- ██║░░╚██╗██╔══╝░░██║╚████║██╔══╝░░██╔══██╗██╔══██║██║░░░░░
-- ╚██████╔╝███████╗██║░╚███║███████╗██║░░██║██║░░██║███████╗
-- ░╚═════╝░╚══════╝╚═╝░░╚══╝╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝╚══════╝
Config                = {}
Locales               = Locales or {}
Config.Language       = "en"      -- tr en
Config.Framework      = "qbox"      -- esx, oldesx, qb, oldqb, qbox
Config.SQL            = "oxmysql" -- oxmysql, ghmattimysql, mysql-async
Config.VersionChecker = false
--[[
    qb_target,
    ox_target,
    qb_textui,
    esx_textui,
    drawtext,
    codem_textui,
    okok_textui,
    eth_textUi
]]
Config.InteractionHandler    = "ox_target"

Config.CurrencyUnit          = "$" -- $ £ €
Config.DefaultProfilePicture = "https://r2.fivemanage.com/p0WfhJFBqn6SlWAIJkdTx/def.png"

--[[
    qb-inventory
    codem-inventory
    esx-inventory
    ox-inventory
    qs-inventory
]]
Config.Inventory                      = "ox-inventory"
Config.DiscordLog                     = false
Config.DeleteLogsAfterDays            = 7
Config.MiniGameTimer                  = 25
Config.FishArrivalTime                = {
    min = 5, -- seconds
    max = 5  -- seconds
}
Config.FishIsCoughtXp                 = {
    min = 10,
    max = 50,
}

Config.RegisterKeyMapping             = {
    ['stopfishing'] = 'G',
    ['baitmenu'] = 'J'
}

Config.Commands                       = {
    ['setfishinglevel'] = 'setfishinglevel'
}

Config.AdminPermissions               = {
    'admin',
    'superadmin',
    'god',
}

-- ███╗░░██╗██████╗░░█████╗░  ░██████╗███████╗████████╗████████╗██╗███╗░░██╗░██████╗░░██████╗
-- ████╗░██║██╔══██╗██╔══██╗  ██╔════╝██╔════╝╚══██╔══╝╚══██╔══╝██║████╗░██║██╔════╝░██╔════╝
-- ██╔██╗██║██████╔╝██║░░╚═╝  ╚█████╗░█████╗░░░░░██║░░░░░░██║░░░██║██╔██╗██║██║░░██╗░╚█████╗░
-- ██║╚████║██╔═══╝░██║░░██╗  ░╚═══██╗██╔══╝░░░░░██║░░░░░░██║░░░██║██║╚████║██║░░╚██╗░╚═══██╗
-- ██║░╚███║██║░░░░░╚█████╔╝  ██████╔╝███████╗░░░██║░░░░░░██║░░░██║██║░╚███║╚██████╔╝██████╔╝
-- ╚═╝░░╚══╝╚═╝░░░░░░╚════╝░  ╚═════╝░╚══════╝░░░╚═╝░░░░░░╚═╝░░░╚═╝╚═╝░░╚══╝░╚═════╝░╚═════╝░
Config.FishingNPC                     = {
    Coords = vector3(-1038.9, -1396.98, 5.55 - 0.98),
    Model = "a_m_m_hillbilly_01",
    Blip = {
        Show = true,
        Sprite = 540,
        Color = 5,
        Name = "Fishing",
        Scale = 0.7,
    },
    Heading = 71.44,
}

-- ██████╗░░█████╗░░█████╗░████████╗  ██████╗░███████╗███╗░░██╗████████╗
-- ██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝  ██╔══██╗██╔════╝████╗░██║╚══██╔══╝
-- ██████╦╝██║░░██║███████║░░░██║░░░  ██████╔╝█████╗░░██╔██╗██║░░░██║░░░
-- ██╔══██╗██║░░██║██╔══██║░░░██║░░░  ██╔══██╗██╔══╝░░██║╚████║░░░██║░░░
-- ██████╦╝╚█████╔╝██║░░██║░░░██║░░░  ██║░░██║███████╗██║░╚███║░░░██║░░░
-- ╚═════╝░░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░  ╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝░░░╚═╝░░░
Config.BoatRentPed                    = {
    Coords = vector3(-720.22, -1323.75, 1.6 - 0.98),
    Model = "s_m_y_valet_01",
    Blip = {
        Show = true,
        Sprite = 540,
        Color = 5,
        Name = "Boat Rent",
        Scale = 0.7,
    },
    Heading = 145.34,
}
Config.BoatRent                       = {
    {
        name = 'dinghy',
        label = 'Dinghy',
        price = 250,
    },
    {
        name = 'suntrap',
        label = 'Suntrap',
        price = 500,
    },
    {
        name = 'marquis',
        label = 'Marquis',
        price = 750,
    },
}
Config.RentVehicleDeliveryPoint       = {
    { coords = vector3(-707.73, -1333.09, 0.41), blip = true, marker = true, text = true }
}
Config.SpawnBoatCoords                = {
    vector4(-724.21, -1329.19, 0.12, 232.45),
    vector4(-731.16, -1335.3, 0.11, 229.52),
    vector4(-736.14, -1342.65, 0.12, 232.74)
}
Config.TeleportAfterVehicleWipeCoords = vector4(-720.61, -1325.34, 1.6, 229.06)


-- ██████╗░██████╗░░█████╗░██████╗░░██████╗
-- ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝
-- ██████╔╝██████╔╝██║░░██║██████╔╝╚█████╗░
-- ██╔═══╝░██╔══██╗██║░░██║██╔═══╝░░╚═══██╗
-- ██║░░░░░██║░░██║╚█████╔╝██║░░░░░██████╔╝
-- ╚═╝░░░░░╚═╝░░╚═╝░╚════╝░╚═╝░░░░░╚═════╝░
Config.FishingRodProps = {
    ["standartrod"] = "prop_fishing_rod_01",
    ["woodenrod"] = "prop_fishing_rod_01",
    ["danishrod"] = "qua_fishing_rod_yellow",
    ["koirod"] = "qua_fishing_rod_neon_blue",
    ["finewoodrod"] = "qua_fishing_rod_neon_purple",
}

-- ██████╗░░█████╗░██╗██╗░░░░░██╗░░░██╗███╗░░░███╗██╗░██████╗░██████╗░█████╗░███╗░░██╗░██████╗
-- ██╔══██╗██╔══██╗██║██║░░░░░╚██╗░██╔╝████╗░████║██║██╔════╝██╔════╝██╔══██╗████╗░██║██╔════╝
-- ██║░░██║███████║██║██║░░░░░░╚████╔╝░██╔████╔██║██║╚█████╗░╚█████╗░██║░░██║██╔██╗██║╚█████╗░
-- ██║░░██║██╔══██║██║██║░░░░░░░╚██╔╝░░██║╚██╔╝██║██║░╚═══██╗░╚═══██╗██║░░██║██║╚████║░╚═══██╗
-- ██████╔╝██║░░██║██║███████╗░░░██║░░░██║░╚═╝░██║██║██████╔╝██████╔╝╚█████╔╝██║░╚███║██████╔╝
-- ╚═════╝░╚═╝░░╚═╝╚═╝╚══════╝░░░╚═╝░░░╚═╝░░░░░╚═╝╚═╝╚═════╝░╚═════╝░░╚════╝░╚═╝░░╚══╝╚═════╝░

Config.DailyMission = {
    ['catchfish'] = {
        Count = 50,
        name = "catchfish",
        RewardXP = 2500,
        label = "Catch At Least 50 Fish"
    },
    ['sellfish'] = {
        Count = 25,
        name = "sellfish",
        RewardXP = 2000,
        label = "Sell Fishes And Earn $2500"
    },
    ['rareclass'] = {
        Count = 5,
        name = "rareclass",
        RewardXP = 2000,
        label = "Catch A 5 Rare Fish"
    },
    ['legendaryclass'] = {
        Count = 5,
        RewardXP = 2000,
        name = "legendaryclass",
        label = "Catch A 5 Legendary Fish"
    },
}

-- ██████╗░░█████╗░██╗██╗░░░░░██╗░░░██╗ ██████╗░███████╗██╗░░░░░██╗██╗░░░██╗███████╗██████╗░██╗░░░██╗
-- ██╔══██╗██╔══██╗██║██║░░░░░╚██╗░██╔╝ ██╔══██╗██╔════╝██║░░░░░██║██║░░░██║██╔════╝██╔══██╗╚██╗░██╔╝
-- ██║░░██║███████║██║██║░░░░░░╚████╔╝░ ██║░░██║█████╗░░██║░░░░░██║╚██╗░██╔╝█████╗░░██████╔╝░╚████╔╝░
-- ██║░░██║██╔══██║██║██║░░░░░░░╚██╔╝░░ ██║░░██║██╔══╝░░██║░░░░░██║░╚████╔╝░██╔══╝░░██╔══██╗░░╚██╔╝░░
-- ██████╔╝██║░░██║██║███████╗░░░██║░░░ ██████╔╝███████╗███████╗██║░░╚██╔╝░░███████╗██║░░██║░░░██║░░░
-- ╚═════╝░╚═╝░░╚═╝╚═╝╚══════╝░░░╚═╝░░░ ╚═════╝░╚══════╝╚══════╝╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚═╝░░░╚═╝░░░
Config.DailyDelivery = {
    ['millarfishary'] = {
        name = 'millarfishary',
        price = 4500,
        requiredAmount = 50,
        fishtype = 'rare',
        npcCoords = {
            coords = vector3(1301.92, 4319.25, 38.21 - 0.98),
            heading = 303.56,
            model = "a_m_m_hillbilly_01",
        }
    },
    ['laspada'] = {
        name = 'laspada',
        price = 6500,
        requiredAmount = 50,
        fishtype = 'epic',
        npcCoords = {
            coords = vector3(-2173.51, 4281.96, 49.11 - 0.98),
            heading = 238.74,
            model = "a_m_m_hillbilly_01",
        }
    },
    ['hookies'] = {
        name = 'hookies',
        price = 8500,
        requiredAmount = 50,
        fishtype = 'legendary',
        npcCoords = {
            coords = vector3(-371.01, 277.63, 86.42 - 0.98),
            heading = 306.73,
            model = "a_m_m_hillbilly_01",
        }
    },
}

-- ██╗████████╗███████╗███╗░░░███╗░██████╗
-- ██║╚══██╔══╝██╔════╝████╗░████║██╔════╝
-- ██║░░░██║░░░█████╗░░██╔████╔██║╚█████╗░
-- ██║░░░██║░░░██╔══╝░░██║╚██╔╝██║░╚═══██╗
-- ██║░░░██║░░░███████╗██║░╚═╝░██║██████╔╝
-- ╚═╝░░░╚═╝░░░╚══════╝╚═╝░░░░░╚═╝╚═════╝░
Config.Items = {
    standartrod     = {
        type = 'rod',
        name = 'standartrod',
        label = 'Standart Rod',
        price = 12,
        requiredLevel = 1,
        classname = 'commonclass',
        catchRate = {
            { class = 'common',    change = 50, fishtoshow = { name = 'bluegill', label = 'Bluegill', } },
            { class = 'uncommon',  change = 35, fishtoshow = { name = 'bluebackherring', label = 'Blueback Herring', } },
            { class = 'rare',      change = 10, fishtoshow = { name = 'americanshad', label = 'American Shad', } },
            { class = 'epic',      change = 5,  fishtoshow = { name = 'arowana', label = 'Arowana', } },
            { class = 'legendary', change = 2,  fishtoshow = { name = 'shark', label = 'Shark', } },
        }
    },
    woodenrod       = {
        type = 'rod',
        name = 'woodenrod',
        label = 'Wooden Rod',
        price = 12,
        requiredLevel = 10,
        classname = 'uncommonclass',
        catchRate = {
            { class = 'common',    change = 35, fishtoshow = { name = 'bluegill', label = 'Bluegill', } },
            { class = 'uncommon',  change = 55, fishtoshow = { name = 'bluebackherring', label = 'Blueback Herring', } },
            { class = 'rare',      change = 15, fishtoshow = { name = 'americanshad', label = 'American Shad', } },
            { class = 'epic',      change = 7,  fishtoshow = { name = 'arowana', label = 'Arowana', } },
            { class = 'legendary', change = 4,  fishtoshow = { name = 'shark', label = 'Shark', } },
        }
    },
    danishrod       = {
        type = 'rod',
        name = 'danishrod',
        label = 'Danish Rod',
        price = 12,
        requiredLevel = 20,
        classname = 'rareclass',
        catchRate = {
            { class = 'common',    change = 25, fishtoshow = { name = 'bluegill', label = 'Bluegill', } },
            { class = 'uncommon',  change = 35, fishtoshow = { name = 'bluebackherring', label = 'Blueback Herring', } },
            { class = 'rare',      change = 40, fishtoshow = { name = 'americanshad', label = 'American Shad', } },
            { class = 'epic',      change = 10, fishtoshow = { name = 'arowana', label = 'Arowana', } },
            { class = 'legendary', change = 7,  fishtoshow = { name = 'shark', label = 'Shark', } },
        }
    },
    finewoodrod     = {
        type = 'rod',
        name = 'finewoodrod',
        label = 'Finewood Rod',
        price = 12,
        requiredLevel = 30,
        classname = 'epicclass',
        catchRate = {
            { class = 'common',    change = 10, fishtoshow = { name = 'bluegill', label = 'Bluegill', } },
            { class = 'uncommon',  change = 20, fishtoshow = { name = 'bluebackherring', label = 'Blueback Herring', } },
            { class = 'rare',      change = 30, fishtoshow = { name = 'americanshad', label = 'American Shad', } },
            { class = 'epic',      change = 25, fishtoshow = { name = 'arowana', label = 'Arowana', } },
            { class = 'legendary', change = 15, fishtoshow = { name = 'shark', label = 'Shark', } },
        }
    },
    koirod          = {
        type = 'rod',
        name = 'koirod',
        label = 'Koi Rod',
        price = 12,
        requiredLevel = 40,
        classname = 'legendaryclass',
        catchRate = {
            { class = 'common',    change = 5,  fishtoshow = { name = 'bluegill', label = 'Bluegill', } },
            { class = 'uncommon',  change = 10, fishtoshow = { name = 'bluebackherring', label = 'Blueback Herring', } },
            { class = 'rare',      change = 20, fishtoshow = { name = 'americanshad', label = 'American Shad', } },
            { class = 'epic',      change = 30, fishtoshow = { name = 'arowana', label = 'Arowana', } },
            { class = 'legendary', change = 35, fishtoshow = { name = 'shark', label = 'Shark', } },
        }
    },
    spoonlure       = {
        type          = 'bait',
        name          = 'spoonlure',
        label         = 'Spoon Lure',
        price         = 12,
        requiredLevel = 1,
        classname     = 'commonclass',
        baitEffect    = {
            { type = 'speed', value = 0 }
        }
    },
    threesided      = {
        type = 'bait',
        name = 'threesided',
        label = 'Three Sided Lure',
        price = 12,
        requiredLevel = 10,
        classname = 'uncommonclass',
        baitEffect = {
            { type = 'speed', value = 25 }
        }
    },
    tailfish        = {
        type = 'bait',
        name = 'tailfish',
        label = 'Tail Fish',
        price = 12,
        requiredLevel = 20,
        classname = 'rareclass',
        baitEffect = {
            { type = 'speed', value = 35 }
        }
    },
    doublehook      = {
        type = 'bait',
        name = 'doublehook',
        label = 'Double Hook',
        price = 12,
        requiredLevel = 30,
        classname = 'epicclass',
        baitEffect = {
            { type = 'fishcount', fishamount = 2, value = 50 },
            { type = 'speed',     value = 45 }
        }
    },
    triplehook      = {
        type = 'bait',
        name = 'triplehook',
        label = 'Triple Hook',
        price = 12,
        requiredLevel = 40,
        classname = 'legendaryclass',
        baitEffect = {
            { type = 'fishcount', fishamount = 3, value = 50 },
            { type = 'speed',     value = 55 }
        }
    },
    bluegill        = {
        type = 'fish',
        name = 'bluegill',
        label = 'Bluegill',
        price = 3,
        classname = 'commonclass'
    },
    goldentrout     = {
        type = 'fish',
        name = 'goldentrout',
        label = 'Golden Trout',
        price = 3,
        classname = 'commonclass'
    },
    silverymonnow   = {
        type = 'fish',
        name = 'silverymonnow',
        label = 'Silvery Mannow',
        price = 3,
        classname = 'commonclass'
    },
    strippedbass    = {
        type = 'fish',
        name = 'strippedbass',
        label = 'Stripped Bass',
        price = 3,
        classname = 'commonclass'
    },
    tench           = {
        type = 'fish',
        name = 'tench',
        label = 'Tench',
        price = 3,
        classname = 'commonclass'
    },
    whitefish       = {
        type = 'fish',
        name = 'whitefish',
        label = 'White fish',
        price = 3,
        classname = 'commonclass'
    },
    crappie         = {
        type = 'fish',
        name = 'crappie',
        label = 'Crappie',
        price = 3,
        classname = 'commonclass'
    },
    cruciancarp     = {
        type = 'fish',
        name = 'cruciancarp',
        label = 'Crucian Carp',
        price = 3,
        classname = 'commonclass'
    },
    bluebackherring = {
        type = 'fish',
        name = 'bluebackherring',
        label = 'Blueback Herring',
        price = 6,
        classname = 'uncommonclass'
    },
    bulltrout       = {
        type = 'fish',
        name = 'bulltrout',
        label = 'Bull Trout',
        price = 6,
        classname = 'uncommonclass'
    },
    laketrout       = {
        type = 'fish',
        name = 'laketrout',
        label = 'Lake Trout',
        price = 6,
        classname = 'uncommonclass'
    },
    perch           = {
        type = 'fish',
        name = 'perch',
        label = 'Perch',
        price = 6,
        classname = 'uncommonclass'
    },
    pearchy         = {
        type = 'fish',
        name = 'pearchy',
        label = 'Pearchy',
        price = 6,
        classname = 'uncommonclass'
    },
    coloradominnow  = {
        type = 'fish',
        name = 'coloradominnow',
        label = 'Colorodo Minnow',
        price = 6,
        classname = 'uncommonclass'
    },
    drumfish        = {
        type = 'fish',
        name = 'drumfish',
        label = 'Drum Fish',
        price = 6,
        classname = 'uncommonclass'
    },
    walleye         = {
        type = 'fish',
        name = 'walleye',
        label = 'Walleye',
        price = 6,
        classname = 'uncommonclass',
    },
    americanshad    = {
        type = 'fish',
        name = 'americanshad',
        label = 'American Shad',
        price = 9,
        classname = 'rareclass'
    },
    palidsturgeon   = {
        type = 'fish',
        name = 'palidsturgeon',
        label = 'Palid Sturgeon',
        price = 9,
        classname = 'rareclass'
    },
    pike            = {
        type = 'fish',
        name = 'pike',
        label = 'Pike',
        price = 9,
        classname = 'rareclass'
    },
    blackcrappie    = {
        type = 'fish',
        name = 'blackcrappie',
        label = 'Black Crappie',
        price = 9,
        classname = 'rareclass'
    },
    bream           = {
        type = 'fish',
        name = 'bream',
        label = 'Bream',
        price = 9,
        classname = 'rareclass'
    },
    brooktrout      = {
        type = 'fish',
        name = 'brooktrout',
        label = 'Brook Trout',
        price = 9,
        classname = 'rareclass'
    },
    shortnosesucker = {
        type = 'fish',
        name = 'shortnosesucker',
        label = 'Shortnose Sucker',
        price = 9,
        classname = 'rareclass'
    },
    smallmouthbass  = {
        type = 'fish',
        name = 'smallmouthbass',
        label = 'Smallmouth Bass',
        price = 9,
        classname = 'rareclass'
    },
    arowana         = {
        type = 'fish',
        name = 'arowana',
        label = 'Arowana',
        price = 12,
        classname = 'epicclass'
    },
    sweetfish       = {
        type = 'fish',
        name = 'sweetfish',
        label = 'Sweet Fish',
        price = 12,
        classname = 'epicclass'
    },
    whitebass       = {
        type = 'fish',
        name = 'whitebass',
        label = 'White Bass',
        price = 12,
        classname = 'epicclass'
    },
    alabamasturgeon = {
        type = 'fish',
        name = 'alabamasturgeon',
        label = 'Alabama Sturgeon',
        price = 12,
        classname = 'epicclass'
    },
    lakesturgeon    = {
        type = 'fish',
        name = 'lakesturgeon',
        label = 'Lake Sturgeon',
        price = 15,
        classname = 'legendaryclass'
    },
    koicarpblack    = {
        type = 'fish',
        name = 'koicarpblack',
        label = 'Koi Carp Black',
        price = 15,
        classname = 'legendaryclass'
    },
    lahontantrout   = {
        type = 'fish',
        name = 'lahontantrout',
        label = 'Lahontan Trout',
        price = 15,
        classname = 'legendaryclass'
    },
    shark           = {
        type = 'fish',
        name = 'shark',
        label = 'Shark',
        price = 15,
        classname = 'legendaryclass'
    },

}

-- ██╗░░░░░███████╗██╗░░░██╗███████╗██╗░░░░░░█████╗░███╗░░██╗██████╗░██╗░░██╗██████╗░
-- ██║░░░░░██╔════╝██║░░░██║██╔════╝██║░░░░░██╔══██╗████╗░██║██╔══██╗╚██╗██╔╝██╔══██╗
-- ██║░░░░░█████╗░░╚██╗░██╔╝█████╗░░██║░░░░░███████║██╔██╗██║██║░░██║░╚███╔╝░██████╔╝
-- ██║░░░░░██╔══╝░░░╚████╔╝░██╔══╝░░██║░░░░░██╔══██║██║╚████║██║░░██║░██╔██╗░██╔═══╝░
-- ███████╗███████╗░░╚██╔╝░░███████╗███████╗██║░░██║██║░╚███║██████╔╝██╔╝╚██╗██║░░░░░
-- ╚══════╝╚══════╝░░░╚═╝░░░╚══════╝╚══════╝╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚═╝░░╚═╝╚═╝░░░░░
local baseXP = 1000
local xpIncrement = 500
local xpMultiplier = 1.05
Config.RequiredXP = {}

for level = 1, 250 do
    Config.RequiredXP[level] = math.floor(baseXP + (level - 1) * xpIncrement * xpMultiplier ^ (level - 1))
end


-- ███████╗██╗░░░██╗███████╗██╗░░░░░
-- ██╔════╝██║░░░██║██╔════╝██║░░░░░
-- █████╗░░██║░░░██║█████╗░░██║░░░░░
-- ██╔══╝░░██║░░░██║██╔══╝░░██║░░░░░
-- ██║░░░░░╚██████╔╝███████╗███████╗
-- ╚═╝░░░░░░╚═════╝░╚══════╝╚══════╝
Config.FuelSystem          = "cdn-fuel"                    -- LegacyFuel / x-fuel

Config.SetVehicleFuel      = function(vehicle, fuel_level) -- you can change LegacyFuel export if you use another fuel system
    if Config.FuelSystem == 'LegacyFuel' then
        return exports["LegacyFuel"]:SetFuel(vehicle, fuel_level)
    elseif Config.FuelSystem == 'x-fuel' then
        return exports["x-fuel"]:SetFuel(vehicle, fuel_level)
    elseif Config.FuelSystem == 'cdn-fuel' then
        return exports["cdn-fuel"]:SetFuel(vehicle, 100.0)
    else
        return SetVehicleFuelLevel(vehicle, fuel_level + 0.0)
    end
end

-- ██╗░░░██╗███████╗██╗░░██╗██╗░█████╗░██╗░░░░░███████╗██╗░░██╗███████╗██╗░░░██╗
-- ██║░░░██║██╔════╝██║░░██║██║██╔══██╗██║░░░░░██╔════╝██║░██╔╝██╔════╝╚██╗░██╔╝
-- ╚██╗░██╔╝█████╗░░███████║██║██║░░╚═╝██║░░░░░█████╗░░█████═╝░█████╗░░░╚████╔╝░
-- ░╚████╔╝░██╔══╝░░██╔══██║██║██║░░██╗██║░░░░░██╔══╝░░██╔═██╗░██╔══╝░░░░╚██╔╝░░
-- ░░╚██╔╝░░███████╗██║░░██║██║╚█████╔╝███████╗███████╗██║░╚██╗███████╗░░░██║░░░
-- ░░░╚═╝░░░╚══════╝╚═╝░░╚═╝╚═╝░╚════╝░╚══════╝╚══════╝╚═╝░░╚═╝╚══════╝░░░╚═╝░░░
Config.Vehiclekey          = false
Config.VehicleSystem       = "qbx-vehiclekeys" -- cd_garage / qs-vehiclekeys / wasabi-carlock / qb-vehiclekeys
Config.Removekeys          = false
Config.RemoveVehicleSystem =
"qbx-vehiclekeys"                                             -- cd_garage / qs-vehiclekeys / wasabi-carlock / qb-vehiclekeys

Config.GiveVehicleKey      = function(plate, model, vehicle) -- you can change vehiclekeys export if you use another vehicle key system
    if Config.Vehiclekey then
        if Config.VehicleSystem == 'cd_garage' then
            TriggerEvent('cd_garage:AddKeys', plate)
        elseif Config.VehicleSystem == 'qs-vehiclekeys' then
            model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            exports['qs-vehiclekeys']:GiveKeys(plate, model, true)
        elseif Config.VehicleSystem == 'wasabi-carlock' then
            exports.wasabi_carlock:GiveKey(plate)
        elseif Config.VehicleSystem == 'qb-vehiclekeys' then
            TriggerServerEvent('qb-vehiclekeys:server:AcquireVehicleKeys', plate)
        end
    end
end
Config.RemoveVehiclekey    = function(plate, model, vehicle)
    if Config.Removekeys then
        if Config.RemoveVehicleSystem == 'cd_garage' then
            TriggerServerEvent('cd_garage:RemovePersistentVehicles', plate)
        elseif Config.RemoveVehicleSystem == 'qs-vehiclekeys' then
            model = GetDisplayNameFromVehicleModel(GetEntityModel(vehicle))
            exports['qs-vehiclekeys']:RemoveKeys(plate, model)
        elseif Config.RemoveVehicleSystem == 'wasabi-carlock' then
            exports.wasabi_carlock:RemoveKey(plate)
        elseif Config.RemoveVehicleSystem == 'qb-vehiclekeys' then
            TriggerEvent('qb-vehiclekeys:client:RemoveKeys', plate)
        end
    end
end



-- ███╗░░██╗░█████╗░████████╗██╗███████╗██╗░█████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
-- ████╗░██║██╔══██╗╚══██╔══╝██║██╔════╝██║██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
-- ██╔██╗██║██║░░██║░░░██║░░░██║█████╗░░██║██║░░╚═╝███████║░░░██║░░░██║██║░░██║██╔██╗██║
-- ██║╚████║██║░░██║░░░██║░░░██║██╔══╝░░██║██║░░██╗██╔══██║░░░██║░░░██║██║░░██║██║╚████║
-- ██║░╚███║╚█████╔╝░░░██║░░░██║██║░░░░░██║╚█████╔╝██║░░██║░░░██║░░░██║╚█████╔╝██║░╚███║
-- ╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░╚═╝╚═╝░░░░░╚═╝░╚════╝░╚═╝░░╚═╝░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝


Config.Notify       = function(header, text)
    if not header then
        header = "Fishing Job"
    end
    if not text then
        text = "No message"
    end
    TriggerEvent("codem-fishingjob:Notify", header, text)
end

Config.ServerNotify = function(src, header, text)
    if not header then
        header = "Fishing Job"
    end
    if not text then
        text = "No message"
    end
    TriggerClientEvent('codem-fishingjob:Notify', src, header, text)
end
