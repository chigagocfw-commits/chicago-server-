Config.contracts.bobcat = {
    ---@type ContractSettings
    settings = {
        disabled = false,
        chance = 10,
        price = 350,
        requiredExperience = 1250,
        expiry = 24 * 60,
        timeToStart = 2 * 60,
        minMembers = 5,
        -- maxMembers = 10,
        rewards = { crypto = 400, experience = 750 }, -- Other rewards such as items are listed below
        minPolice = 5,
        cooldown = 45, -- Minutes before this contract can spawn again after completion (false = no cooldown)
    },

    duration = 60, -- minutes before reset
    image = './contracts/bobcat_k4mb1.png',

    -- Blip shown to the players after the contract is started
    blip = {
        coords = vector3(1397.19, -2616.77, 49.67),
        name = locale('bobcat_security'),
        sprite = 1,
        size = 0.75,
        color = 1
    },
    
    alarm = {
        coords = vector3(1376.18, -2620.07, 53.12),
        duration = 60
    },

    dispatch = {
        enabled = true,
        code = '10-68',
        title = locale('dispatch_bobcat_title'),
        message = locale('dispatch_bobcat_message'),
    },

    entryDoor = {
        model = `v_ilev_gendoor01`,
        heading = 95.0,
        requiredItem = 'thermite',
        -- It's a double door thus there are two coords defined
        locations = {
            vector3(1402.31, -2618.55, 49.83),
            vector3(1402.08, -2615.96, 49.83)
        }
    },

    securityDoor = {
        model = `v_ilev_gendoor01`,
        coords = vector4(1395.9508056641, -2616.8, 49.825199127197, 95.0),
        requiredItem = 'thermite',
    },

    guardedArea = {
        keypad = {
            coords = vector4(1392.62, -2619.77, 49.98, 95.0), 
            requiredItem = 'hack_usb',
            removeAfterUse = false
        },
        door = {
            { coords = vector3(1392.43, -2619.42, 49.82), model = `v_ilev_cd_door` },
            { coords = vector3(1392.2, -2616.83, 49.82), model = `v_ilev_cd_door` },
            { coords = vector3(1372.28, -2611.79, 49.83), model = `v_ilev_cd_door` },
            { coords = vector3(1372.05, -2609.2, 49.83), model = `v_ilev_cd_door` },
        },
        guards = {
            enabled = true,
            model = `s_m_m_chemsec_01`,
            minPolice = 0,
            accuracy = 80, -- from 0 - 100
            combatAbility = 100, -- from 0 - 100, peds can start to run away if less than 50
            looting = {
                enabled = false, -- Players can loot the guards
                progressDuration = 5000
            },
            ---@type GuardWeapon[]
            weapons = {
                { name = 'weapon_carbinerifle', ammo = { name = 'ammo-rifle', min = 2, max = 10 } },
                { name = 'weapon_combatpistol', ammo = { name = 'ammo-9', min = 2, max = 10 } },
            },
            locations = {
                vector4(1362.13, -2611.25, 49.67, 235.11),
                vector4(1370.2, -2616.81, 49.67, 152.59),
                vector4(1363.91, -2628.13, 49.67, 332.27),
                vector4(1368.42, -2634.24, 49.67, 270.06),
                vector4(1375.44, -2630.57, 49.67, 241.23),
                vector4(1379.05, -2635.31, 49.67, 297.35),
                vector4(1385.97, -2634.27, 49.67, 0.87),
                vector4(1384.23, -2625.03, 49.67, 336.34),
                vector4(1383.56, -2617.3, 49.67, 244.83),
            },
        },
        vault = {
            coords = vector4(1377.82, -2630.05, 50.03, 4.77),
            requiredItem = 'bomb_c4',
            explosion = {
                delay = 10, -- It blows up 10 seconds after it's planted
                type = 4,
                cameraShake = 5.0
            },
            ---@type LootData
            loot = {
                rewards = {
                    -- ['cash'] = { account = 'money', count = { pile = 72000, trolley = 112500 } },
                    ['cash'] = { item = 'money', count = { pile = 20, trolley = 45 }  },
                    ['gold'] = { item = 'gold_bar', count = { pile = 20, trolley = 45 } },
                },
                goldChance = 20,
                locations = {
                    {
                        coords = vector4(1378.7891845703, -2620.0073242188, 49.67, 143.686), 
                        type = 'trolley'
                    },
                    {
                        coords = vector4(1379.223, -2624.198, 49.67, 68.045),
                        type = 'trolley'
                    },
                    {
                        coords = vector4(1380.753, -2625.582, 49.67, 93.781),
                        type = 'trolley'
                    },
                    {
                        coords = vector4(1380.924, -2627.618, 49.67, 95.474),
                        type = 'trolley'
                    },
                    {
                        coords = vector4(1376.88, -2622.61, 49.55, 4.52),
                        type = 'pile'
                    },
                    {
                        coords = vector4(1376.81, -2621.71, 49.55, 192.25),
                        type = 'pile'
                    },
                }
            },
            ---@type { model: string | number, progressDuration: integer, items: { name: string, count: integer | { min: integer, max: integer }, chance: integer?, metadata: any? }[], locations: vector4[] }[]
            weaponsLoot = {
                {
                    model = `ex_prop_crate_expl_bc`,
                    progressDuration = 7500,
                    items = {
                        { name = 'rifle_ammo', count = { min = 3, max = 15 }},
                        { name = 'smg_ammo', count = { min = 3, max = 15 }},
                        { name = 'pistol_ammo', count = { min = 6, max = 20 }, chance = 75},
                        { name = 'classified_docs', count = { min = 1, max = 5 }, chance = 25 },
                        { name = 'bomb_c4', count = { min = 1, max = 5 }, chance = 20 },
                        { name = 'thermite', count = { min = 1, max = 5 }, chance = 20 },
                    },
                    locations = {
                        vector4(1374.06, -2628.82, 48.79, 95.0)
                    }
                },
                {
                    model = `ex_prop_crate_ammo_sc`,
                    progressDuration = 7500,
                    items = {
                        { name = 'weapon_smg', count = { min = 1, max = 3 }, chance = 45 },
                        { name = 'rifle_ammo', count = { min = 3, max = 15 }},
                        { name = 'smg_ammo', count = { min = 3, max = 15 }},
                        { name = 'pistol_ammo', count = { min = 6, max = 20 }, chance = 75},
                        { name = 'weapon_pistol', count = { min = 1, max = 2 }, chance = 50 },
                        { name = 'rare_coins', count = { min = 1, max = 3 }, chance = 20 },
                    },
                    locations = {
                        vector4(1373.58, -2626.31, 48.81, 95.0)
                    }
                },
                {
                    model = `ex_prop_crate_ammo_bc`,
                    progressDuration = 7500,
                    items = {
                        { name = 'weapon_assaultrifle', count = { min = 1, max = 3 }, chance = 15 },
                        { name = 'weapon_carbinerifle', count = { min = 1, max = 3 }, chance = 15 },
                        { name = 'rifle_ammo', count = { min = 3, max = 15 }},
                        { name = 'smg_ammo', count = { min = 3, max = 15 }},
                        { name = 'pistol_ammo', count = { min = 6, max = 20 }, chance = 75},
                        { name = 'rare_coins', count = { min = 1, max = 3 }, chance = 20 },
                    },
                    locations = {
                        vector4(1373.35, -2623.68, 48.8, 95.0)
                    }
                },
                {
                    model = `ex_prop_crate_expl_sc`,
                    progressDuration = 7500,
                    items = {
                        { name = 'rifle_ammo', count = { min = 3, max = 15 }},
                        { name = 'smg_ammo', count = { min = 3, max = 15 }},
                        { name = 'pistol_ammo', count = { min = 6, max = 20 }, chance = 75},
                        { name = 'rare_coins', count = { min = 1, max = 3 }, chance = 20 },
                        { name = 'classified_docs', count = { min = 1, max = 5 }, chance = 25 },
                        { name = 'bomb_c4', count = { min = 1, max = 5 }, chance = 20 },
                        { name = 'thermite', count = { min = 1, max = 5 }, chance = 20 },
                    },
                    locations = {
                        vector4(1373.31, -2621.14, 48.8, 95.0)
                    }
                },
            }
        }
    },

    removeProps = {
        
    }
}

RegisterNetEvent('lunar_contracts:bobcat:bombPlanted', function()
    local config = Config.contracts.bobcat
    local delay = config.guardedArea.vault.explosion.delay * 1000 + 2866
    Wait(delay)
    local interiorId = GetInteriorAtCoords(1378.81700000, -2622.62700000, 48.67468000)
    ActivateInteriorEntitySet(interiorId, "k4mb1_bobcat_start")
    DeactivateInteriorEntitySet(interiorId, "k4mb1_bobcat_start")
    ActivateInteriorEntitySet(interiorId, "k4mb1_bobcat_destroyed")
    RefreshInterior(interiorId)
end)


RegisterNetEvent('lunar_contracts:bobcat:reset', function()
    local interiorId = GetInteriorAtCoords(1378.81700000, -2622.62700000, 48.67468000)
    DeactivateInteriorEntitySet(interiorId, "k4mb1_bobcat_destroyed")
    ActivateInteriorEntitySet(interiorId, "k4mb1_bobcat_start")
    RefreshInterior(interiorId)
end)