Config.contracts.mazebank = {
    ---@type ContractSettings
    settings = {
        disabled = false,
        chance = 2,
        price = 1250,
        requiredExperience = 2000,
        expiry = 24 * 60,
        timeToStart = 2 * 60,
        minMembers = 1,
        -- maxMembers = 16,
        rewards = { crypto = 625, experience = 3500 },
        minPolice = 0,
        cooldown = 60, -- Minutes before this contract can spawn again after completion (false = no cooldown)
    },

    duration = 120, -- The bank will reset after this duration (minutes)
    image = './contracts/mazebank_k4mb1.png',
    
    blip = {
        coords = vector3(-1348.04, -474.86, 33.58),
        name = locale('mazebank'),
        sprite = 1,
        size = 0.75,
        color = 1
    },

    dispatch = {
        enabled = true,
        code = '10-68',
        title = locale('dispatch_mazebank_title'),
        message = locale('dispatch_mazebank_message'),
    },

    alarm = {
        coords = vector3(-1366.59, -485.25, 33.19),
        duration = 60, -- seconds
        silentDelay = 2 -- minutes after the main vault door is opened
    },

    cancelPoint = vector3(-1308.7822, -822.1907, 16.9513),
    
    securityDoors = {
        requiredItem = 'hack_card',
        removeAfterUse = false,
        locations = {
            { 
                model = `k4mb1_mazebank_door2`,
                coords = vector3(-1347.9718017578126, -475.3099670410156, 33.85235214233398),
                keypad = vector4(-1347.458, -476.017, 33.975, 125.0) 
            },
            { 
                model = `k4mb1_mazebank_door2`,
                coords = vector3(-1351.9138183594, -495.54833984375, 33.35701751709),
                keypad = vector4(-1350.380, -494.953, 33.565, -172.0) 
            },
            { 
                model = `k4mb1_mazebank_door3`,
                coords = vector3(-1360.6346435547, -495.04556274414, 32.170955657959), 
                keypad = vector4(-1361.059, -496.922, 33.625, -80.152) 
            },
            { 
                model = `k4mb1_mazebank_door3`,
                coords = vector3(-1361.685546875, -488.28393554688, 32.172454833984), 
                keypad = vector4(-1361.747, -489.943, 33.625, -80.152) 
            },
            { 
                model = `k4mb1_mazebank_door2`,
                coords = vector3(-1360.2803955078, -499.36904907227, 33.360599517822),
                keypad = vector4(-1360.120, -499.592, 33.625, 97.0) 
            },
        }
    },

    garage = {
        door = {
            model = `k4mb1_mazebank_garagedoor1`,
            coords = vector3(-1416.5506591797, -478.5725402832, 34.784683227539)
        },
        panel = vector3(-1415.8383789062, -473.6552734375, 33.888637542725)
    },

    -- The doors you get access to by hacking the laptops
    keypadDoors = {
        laptops = {
            model = `xm_prop_x17_laptop_mrsr`,
            requiredItem = 'hack_usb',
            removeAfterUse = false,
            locations = {
                vector4(-1358.205, -491.789, 33.084 + 0.08, 100.0),
                vector4(-1359.336, -485.167, 33.084 + 0.08, 100.0),
                vector4(-1340.525, -496.684, 32.990 + 0.08, -76.747),
                vector4(-1356.192, -503.287, 33.002 + 0.08, 8.799),
                vector4(-1380.927, -488.256, 32.929 + 0.08, 104.999)
            }
        },
        keypads = {
            vector3(-1345.5629882812, -498.17135620117, 33.632091522217), 
            vector3(-1371.298828125, -486.37127685547, 33.632091522217)
        },
        doors = {
            model = `k4mb1_mazebank_door2`,
            locations = {
                vector3(-1347.1337890625, -498.49478149414, 33.35701751709),
                vector3(-1371.7587890625, -484.90582275391, 33.362937927246)
            }
        }
    },

    lasers = {
        -- The lasers will only render when 25.0 meters close
        -- This saves resmon for players that are not near
        render = {
            coords = vector4(-1368.95, -476.76, 33.19, 187.77),
            radius = 25.0,
            debug = false
        },
        -- Players need to disable this so the lasers go away
        electricBox = {
            model = `h4_prop_h4_elecbox_01a`,
            coords = vector4(-1348.5100097656, -499.92636108398, 33.198, 99.266 + 180),
            requiredItem = false,
        },
        origins = {
            vector3(-1363.694946, -481.653992, 35.792999),
            vector3(-1363.692993, -481.670013, 35.240002),
            vector3(-1363.691040, -481.677002, 34.626999),
            vector3(-1363.692017, -481.669006, 34.035000),
            vector3(-1363.694946, -481.644989, 33.387001),
            vector3(-1363.697998, -481.622009, 32.806000),
            vector3(-1363.702026, -481.598999, 32.223000),
            vector3(-1363.702026, -481.598999, 32.223000),
        },

        ends = {
            vector3(-1371.843018, -482.880005, 35.842999),
            vector3(-1371.842041, -482.885986, 35.299000),
            vector3(-1371.839966, -482.897003, 34.680000),
            vector3(-1371.848022, -482.845001, 34.013000),
            vector3(-1371.852051, -482.821014, 33.471001),
            vector3(-1371.850952, -482.826996, 32.984001),
            vector3(-1371.855957, -482.791992, 32.403000),
        },
    },

    serverRoomTerminal = {
        coords = vector4(-1347.219970703125, -502.9291259765627, 33.498, -172.018), 
        requiredItem = 'hack_card',
        removeAfterUse = false
    },
    
    cameras = {
        desks = {
            vector3(-1375.6268310546876, -487.1119079589844, 33.06980514526367),
        },
        settings = {
            rotateSpeed = 0.2,
            controls = {
                left = 34,
                right = 35,
                up = 32,
                down = 33
            }
        },
        options = {
            {
                title = locale('cam_sidevault_1'),
                coords = vector4(-1358.8540, -464.2414, 34.9010, 137.0264)
            },
            {
                title = locale('cam_sidevault_2'),
                coords = vector4(-1379.6912, -467.8214, 34.9310, 244.6342)
            },
            {
                title = locale('cam_prevault_1'), 
                coords = vector4(-1371.7678, -481.6926, 35.2613, 277.5829)
            },
            {
                title = locale('cam_vault_1'),
                coords = vector4(-1374.0360, -466.3766, 35.9711, 222.4620)
            },
            {
                title = locale('cam_vault_2'),
                coords = vector4(-1365.0070, -465.0616, 36.0312, 147.9092)
            },
            {
                title = locale('cam_lobby_1'), 
                coords = vector4(-1368.4041, -501.5964, 35.9412, 303.0628)
            },
            {
                title = locale('cam_lobby_2'), 
                coords = vector4(-1381.4033, -497.2496, 36.0112, 0.5505)
            },
            {
                title = locale('cam_lobby_3'), 
                coords = vector4(-1366.2631, -489.8670, 36.2311, 99.9836)
            },
            {
                title = locale('cam_lobby_4'), 
                coords = vector4(-1366.0730, -486.3401, 36.5411, 15.7689)
            },
            {
                title = locale('cam_top_1'), 
                coords = vector4(-1351.3694, -494.8537, 35.1191, 12.3723)
            },
            {
                title = locale('cam_top_2'), 
                coords = vector4(-1344.7548, -496.2787, 35.3982, 102.7536)
            },
            {
                title = locale('cam_top_3'), 
                coords = vector4(-1360.0316, -498.6740, 35.3882, 275.2399)
            },
            {
                title = locale('cam_garage'), 
                coords = vector4(-1374.9044, -483.4442, 35.7204, 49.5601)
            },        
        }
    },

    basement = {
        doors = {
            {
                model = `k4mb1_mazebank_door`,
                coords = vector3(-1366.6614990234, -481.69906616211, 33.457691192627),
            },
            {
                model = `k4mb1_mazebank_door`,
                coords = vector3(-1368.8894042969, -482.05157470703, 33.457691192627),
            },
            {
                model = `k4mb1_mazebank_gate`,
                coords = vector3(-1372.8220214844, -478.40386962891, 33.346076965332),
                
            },
            {
                model = `k4mb1_mazebank_vaultdoor`,
                coords = vector3(-1368.8709716797, -475.85897827148, 33.757358551025),
                unlocks = 'mainVault1',
                shouldScramble = true, -- Should scramble without the overloaded circuit
                triggersReward = true -- This triggers the XP rewards for the contract, should only be included once
            },
            {
                model = `k4mb1_mazebank_gate`,
                coords = vector3(-1371.2772216797, -475.08959960938, 33.523082733154),
                shouldScramble = true, -- Should scramble without the overloaded circuit
                
            },
            {
                model = `k4mb1_mazebank_framedoor`,
                coords = vector3(-1374.4760742188, -469.4482421875, 33.446662902832),
                unlocks = 'mainVault2',
                shouldScramble = true -- Should scramble without the overloaded circuit
            },
            {
                model = `k4mb1_mazebank_framedoor`,
                coords = vector3(-1363.6848144531, -466.0654296875, 33.426918029785),
                unlocks = 'mainVault3',
                shouldScramble = true -- Should scramble without the overloaded circuit
            },
        },
        circuitOverload = {
            coords = vector4(-1377.68579101562, -470.806884765625, 33.44852447509765, 7.493),
            requiredItem = 'hack_usb',
            removeAfterUse = false
        },
        props = {
            { coords = vector4(-1345.5629882812, -498.17135620117, 34.632091522217, -170.826), model = `ch_prop_casino_keypad_02` },
            { coords = vector4(-1371.298828125, -486.37127685547, 34.632091522217, 99.937), model = `ch_prop_casino_keypad_02` },
            { coords = vector4(-1377.7115478516, -474.69250488281, 34.007038116455,7.493), model = `prop_elecbox_18` },
            { coords = vector4(-1347.157, -503.193, 33.198, -172.018), model = `xm_base_cia_server_01` }
        },                    
        ---@type LootData
        loot = {
            rewards = {
                ['cash'] = { account = 'money', count = { pile = 72000, trolley = 112500 } },
                ['gold'] = { item = 'gold_bar', count = { pile = 20, trolley = 45 } },
            },
            goldChance = 20,
            locations = {

                -- Main vault
                {
                    coords = vector4(-1365.109, -465.184, 33.164, -171.875), 
                    type = 'trolley',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1366.571, -465.393, 33.164, -171.875), 
                    type = 'trolley',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1368.061, -465.605, 33.164, -171.875), 
                    type = 'trolley',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1370.4676513672, -465.94860839844, 33.164, -171.875), 
                    type = 'trolley',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1371.9581298828, -466.16137695312, 33.164, -171.875), 
                    type = 'trolley',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1373.5643310547, -466.39068603516, 33.164, -171.875), 
                    type = 'trolley',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1368.5842285156, -469.37835693359, 33.164, 8.875), 
                    type = 'trolley',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1368.515, -470.568, 33.164, -171.875), 
                    type = 'trolley',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1366.295, -471.687, 33.077, -81.125),
                    type = 'pile',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1365.529, -472.108, 33.077, 8.875),
                    type = 'pile',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1365.213, -471.395, 33.077, 98.875),
                    type = 'pile',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1365.945, -470.985, 33.077, -171.875),
                    type = 'pile',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1373.211, -473.542, 33.164, -81.125),
                    type = 'trolley',
                    requires = 'mainVault1'
                },
                {
                    coords = vector4(-1373.439, -472.077, 33.164, -81.125),
                    type = 'trolley',
                    requires = 'mainVault1',
                },

                -- Mainvault subvault 1
                {
                    coords = vector4(-1378.529, -470.225, 33.164, -81.875),
                    type = 'trolley',
                    requires = 'mainVault2'
                },
                {
                    coords = vector4(-1378.656, -468.104, 33.164, -171.875),
                    type = 'trolley',
                    requires = 'mainVault2'
                },
                {
                    coords = vector4(-1376.331, -470.097, 33.164, 8.875),
                    type = 'trolley',
                    requires = 'mainVault2'
                },
                {
                    coords = vector4(-1376.883, -467.152, 33.097, 8.875),
                    type = 'pile',
                    requires = 'mainVault2'
                },
                {
                    coords = vector4(-1379.387, -468.786, 33.097, 98.875),
                    type = 'pile',
                    requires = 'mainVault2'
                },
                {
                    coords = vector4(-1377.593, -470.957, 33.097, -171.875),
                    type = 'pile',
                    requires = 'mainVault2'
                },
                
                
                -- Mainvault subvault 2
                {
                    coords = vector4(-1361.766, -467.834, 33.163, 8.875),
                    type = 'trolley',
                    requires = 'mainVault3',
                },
                {
                    coords = vector4(-1359.647, -465.266, 33.163, 98.875),
                    type = 'trolley',
                    requires = 'mainVault3',
                },
                {
                    coords = vector4(-1362.113, -464.876, 33.097, 8.875),
                    type = 'pile',
                    requires = 'mainVault3'
                },
                {
                    coords = vector4(-1361.069, -464.713, 33.097, 8.875),
                    type = 'pile',
                    requires = 'mainVault3'
                },
                {
                    coords = vector4(-1360.195, -468.278, 33.097, -171.125),
                    type = 'pile',
                    requires = 'mainVault3'
                },
                {
                    coords = vector4(-1358.775, -466.076, 33.097, -81.125),
                    type = 'pile',
                    requires = 'mainVault3'
                },
            }
        }
    }
}