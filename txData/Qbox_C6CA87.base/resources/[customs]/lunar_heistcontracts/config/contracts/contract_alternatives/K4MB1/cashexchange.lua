Config.contracts.cashexchange = {
    ---@type ContractSettings
    settings = {
        disabled = false,
        chance = 10,
        price = 125,
        requiredExperience = 750,
        expiry = 24 * 60,
        timeToStart = 2 * 60,
        minMembers = 4,
        -- maxMembers = 6,
        rewards = { crypto = 65, experience = 500 }, -- Other rewards such as items are listed below
        minPolice = 6,
        cooldown = 30, -- Minutes before this contract can spawn again after completion (false = no cooldown)
    },

    duration = 120, -- minutes before reset
    alarmDuration = 30, -- seconds

    -- Blip shown to the players after the contract is started
    blip = {
        name = locale('cashexchange'),
        sprite = 1,
        size = 0.75,
        color = 1
    },

    dispatch = {
        enabled = true,
        code = '10-68',
        title = locale('dispatch_cashexchange_title'),
        message = locale('dispatch_cashexchange_message'),
    },

    startPanel = {
        requiredItem = 'hack_usb',
        removeAfterUse = false
    },

    electricBox = {
        requiredItem = 'hack_usb',
        removeAfterUse = false
    },

    unlockVault = {
        requiredItem = 'hack_card',
        removeAfterUse = false,
        delay = 1, -- The vault will unlock in 2 minutes
        offset = vector3(1.3, 0.02, 0.05), -- Inverted X offset for K4MB1 vault door orientation
        rotationOffset = 180.0,
        interactionOffset = vector3(1.05, 1.10, 0.0), 
        spawnLootEarly = true -- Keep this on true for the K4MB1 integration
    },

    doorModels = {
        entry = `k4mb1_secdoor_01`,
        other = {`v_ilev_arm_secdoor`},
        vault = `k4mb1_gavscashexchange_cage_door`
    },

    locations = {
        {
            image = './contracts/cashexchange.png',
            startPanel = {
                coords = vector4(137.510223, -1334.379028, 29.523590, 130.0),
                offset = vector3(-0.07, 0.05, 0.05)
            },
            alarm = vector3(126.8754, -1348.2876, 32.9710),
            electricBox = vector4(131.6, -1338.1, 29.59, 43.45),
            cancelPoint = vector3(129.1895, -1346.6144, 29.7104),
            doors = {
                entry = vector3(139.81774902344, -1338.3587646484, 29.355503082275),
                other = {
                    vector3(133.75094604492, -1347.6704101562, 29.457305908203),
                },
                vault = {
                    vector3(132.18185424805, -1340.7572021484, 29.651550292969),
                }
            },
            props = {
              -- Empty for the K4MB1 map
            },
            removeProps = {
                { coords = vector3(135.34568786621, -1342.0241699219, 28.768236160278), model = `prop_cash_trolly` },
                { coords = vector3(134.55442810059, -1342.84375, 28.768236160278), model = `prop_cash_trolly` },
                { coords = vector3(133.02893066406, -1343.0037841797, 28.768236160278), model = `prop_cash_trolly` },
                { coords = vector3(132.30473327637, -1342.1616210938, 28.768236160278), model = `prop_cash_trolly` },
                { coords = vector3(133.76385498047, -1342.3514404297, 28.292663574219), model = `ch_prop_ch_cashtrolley_01a` },
            },
            -- There's also a second location below, don't forget to change the loot there
            ---@type LootData
            loot = {
                rewards = {
                    ['cash'] = { account = 'money', count = { pile = 72000, trolley = 112500 } },
                },
                goldChance = 0,
                locations = {
                    {
                        coords = vec4(135.350, -1342.046, 29.29, 47.100),
                        type = 'trolley',
                    },
                    {
                        coords = vec4(134.480, -1342.989, 29.29, 47.100),
                        type = 'trolley',
                    },
                    {
                        coords = vec4(133.26797485352, -1342.9865722656, 29.29, -44.874), 
                        type = 'trolley',
                    },
                    {
                        coords = vec4(132.45042419434, -1342.1668701172, 29.29, -44.874),
                        type = 'trolley',
                    },
                }
            }
        },
    }
}