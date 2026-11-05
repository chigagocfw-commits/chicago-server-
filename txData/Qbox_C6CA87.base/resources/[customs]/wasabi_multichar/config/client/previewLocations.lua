-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

--[[
    PREVIEW LOCATIONS – Character selection scenes (camera + ped slots).
    Full guide: docs/PREVIEW_LOCATIONS_GUIDE.md

    Each location set can contain:
        hiddenCoords, pedInterior, startCam, cinematicCam, slots  (required/core)
        ipls         = { 'ipl1', 'ipl2', ... }  -- IPLs to load/unload with this location
        stopCamParams = { x, y, z, rotX, rotY, rotZ, duration }  -- camera transition during exit
        useFladeAnim  = true  -- when true, slot focus uses fade-out / cut / fade-in instead of camera interpolation
        commonCam, commonCamSlots  -- optional bridge camera for slots behind a wall
        minSlots, vehicles  -- optional: minimum characters to pick this location; vehicles to spawn
    Per-slot: pos, cam, anim, attachToSlot, previewStartposition (optional start cam for interpolation)
    Anim props: prop and secondProp = { model, bone, placement }
--]]

Config.PreviewLocations = {

    [1] = {
        hiddenCoords = vector4(2735.5588, 1578.6628, 66.4772, 37.8185),
        pedInterior  = vector3(2735.5588, 1578.6628, 66.4772),
        startCam     = vector3(-1720.7660, -1180.8932, 27.7457),
        cinematicCam = {
            pos    = vector3(2719.5703, 1567.6654, 66.7429),
            pointAt = vector3(2729.2446, 1574.6409, 65.4772),
        },
        -- Exit animation when a character is selected (qbx StopCinematicCam). Uses peds 1 and 2 only.
        exitAnim = {
            dict      = 'missfinale_b_ig_5',
            animDrop1 = 'hold_michael_drop_fra',
            animDrop2 = 'hold_michael_drop_mic 2',
            animBut1  = 'hold_michael_headbut_fra',
            animBut2  = 'hold_michael_headbut_mic',
        },
        -- Camera transition during exit: final position and duration (ms). Shorter = exit cam closes sooner.
        stopCamParams = {
            x = 2725.5703, y = 1570.6654, z = 67.4429,
            rotX = 2.0, rotY = 0.0, rotZ = 0.0,
            durationHeadbutt = 2000,  -- was 10000; lower = cam closes sooner
            durationDrop     = 1500,  -- was 5000; lower = cam closes sooner
        },
        minSlots = 2,
        slots = {
            [1] = {
                pos = vector4(2729.2446, 1574.6409, 66.4772, 133.6893),
                cam = vector4(2724.5703, 1571.6654, 66.7429, 301.2187),
                anim = { type = 'animation', dict = 'missfinale_b_ig_5', clip = 'hold_michael_loop_fra' },
                attachToSlot = false,
            },
            [2] = {
                pos = vector4(2728.6931, 1574.4105, 64.810, 114.7388),
                cam = vector4(2724.5703, 1571.6654, 66.7429, 301.2187),
                anim = { type = 'animation', dict = 'missfinale_b_ig_5', clip = 'hold_michael_loop_mic' },
                attachToSlot = 1,
            },
            [3] = {
                pos = vector4(2729.5991, 1578.9985, 66.4772, 171.6847),
                cam = vector4(2724.5703, 1571.6654, 66.7429, 301.2187),
                anim = { type = 'scenario', name = 'WORLD_HUMAN_MOBILE_FILM_SHOCKING' },
                attachToSlot = false,
            },
            [4] = {
                pos = vector4(2733.9724, 1574.3318, 66.5380, 169.6273),
                cam = vector4(2730.5522, 1569.4454, 68.8066, 315.2617),
                anim = { type = 'animation', dict = 'fix_trip3_ext-4', clip = 'a_f_y_vinewood_02_dual-4' },
                attachToSlot = false,
            },
            [5] = {
                pos = vector4(2729.4043, 1576.3790, 66.5380, 309.0357),
                cam = vector4(2724.5703, 1571.6654, 66.7429, 301.2187),
                anim = { type = 'animation', dict = 'anim@heists@prison_heistig_5_p1_rashkovsky_idle', clip = 'idle' },
                attachToSlot = false,
            },
        },
    },

    -- =============================================================================
    -- LOCATION SET [2] – Interior apartment (dpemotes anims + props)
    -- =============================================================================
    [2] = {
        hiddenCoords = vector4(-773.8143, 323.0187, 196.9124, 30.5918),
        pedInterior  = vector3(-773.8143, 323.0187, 196.9124),
        startCam     = vector3(-769.0007, 314.1014, 197.0686),
        cinematicCam = {
            pos     = vector3(-779.9788, 315.7104, 195.8861),
            pointAt = vector3(-774.3140, 319.8440, 196.3172),
            waypoints = {
                { pos = vector3(-777.7614, 322.8509, 195.8861), pointAt = vector3(-774.8031, 319.1049, 196.0512), duration = 8000 },
                { pos = vector3(-778.5465, 314.4397, 195.8864), pointAt = vector3(-769.2138, 317.7834, 195.9946), duration = 10000 },
                { pos = vector3(-771.4794, 332.7948, 196.0861), pointAt = vector3(-778.5047, 328.7659, 196.0861), duration = 10000 },
                { pos = vector3(-773.9379, 315.5357, 195.8864), pointAt = vector3(-773.8875, 312.1620, 197.1411), duration = 8000 },
                { pos = vector3(-765.8898, 333.8127, 196.0857), pointAt = vector3(-766.2681, 335.7188, 196.0857), duration = 10000 },
                { pos = vector3(-761.3962, 331.0184, 196.0858), pointAt = vector3(-765.9470, 330.5887, 196.0858), duration = 8000 },
            },
        },
        stopCamParams = {
            x = -770.0, y = 318.0, z = 197.5,
            rotX = 2.0, rotY = 0.0, rotZ = 0.0,
            duration = 2000,
        },
        slots = {
            -- [1] Sit TV (dpemotes: sittv) – remote in right hand
            [1] = {
                pos  = vector4(-774.8995, 319.0152, 195.8862, 93.2444),
                cam  = vector4(-776.8101, 321.7390, 195.8861, 221.3624),
                anim = {
                    type = 'animation',
                    dict = 'anim@heists@heist_safehouse_intro@variations@male@tv',
                    clip = 'tv_part_one_loop',
                    prop = {
                        model     = 'v_res_tre_remote',
                        bone      = 57005,
                        placement = { 0.099, 0.017, -0.03, -64.76, -109.544, 18.717 },
                    },
                },
                attachToSlot = false,
            },
            -- [2] Lean Bar 6 (dpemotes: nekoleanbar6) – joint in left hand
            [3] = {
                pos  = vector4(-769.8065, 319.9534, 197.6107, 89.3220),
                cam  = vector4(-773.1310, 323.3941, 195.8865, 223.9488),
                anim = {
                    type = 'animation',
                    dict = 'switch@michael@pier',
                    clip = 'pier_lean_smoke_idle',
                    prop = {
                        model     = 'p_cs_joint_02',
                        bone      = 58867,
                        placement = { 0.06, 0.005, -0.015, 40.3, 78.3, 124.1 },
                    },
                },
                attachToSlot = false,
            },
            -- [3] Check Out 2 (dpemotes: checkcar2 / jcheckout2) – no prop
            [4] = {
                pos  = vector4(-773.0419, 314.8651, 195.8864, 181.9086),
                cam  = vector4(-770.6024, 316.9800, 195.8862, 137.8306),
                anim = {
                    type = 'animation',
                    dict = 'anim@amb@carmeet@checkout_car@male_c@idles',
                    clip = 'idle_a',
                },
                attachToSlot = false,
            },
            -- [4] Wine 3 (dpemotes: wine3) – wine bottle in left hand
            [5] = {
                pos  = vector4(-772.7614, 327.6090, 196.1227, 177.1161),
                cam  = vector4(-770.9621, 324.3499, 196.0860, 25.1237),
                anim = {
                    type = 'animation',
                    dict = 'amb@world_human_drinking@beer@female@idle_a',
                    clip = 'idle_e',
                    prop = {
                        model     = 'prop_wine_rose',
                        bone      = 28422,
                        placement = { 0.0, 0.04, -0.19, 10.0, 0.0, 0.0 },
                    },
                },
                attachToSlot = false,
            },
            -- [5] Sit Chair 7 (dpemotes: nekositchair7) – joint in left hand
            [2] = {
                pos  = vector4(-778.7349, 321.6591, 195.8863, 219.5113),
                cam  = vector4(-779.3123, 318.2097, 195.8861, 347.4196),
                anim = {
                    type = 'animation',
                    dict = 'anim@amb@nightclub@smoking@',
                    clip = 'blunt_idle_a',
                    prop = {
                        model     = 'p_cs_joint_02',
                        bone      = 28422,
                        placement = { 0.08, -0.005, -0.035, 175.5, 311.0, 232.0 },
                    },
                },
                attachToSlot = false,
            },
        },
    },

    -- =============================================================================
    -- LOCATION SET [3] – Underground club/bar (GTAOHouseMid1 interior, loaded by bob74_ipl)
    -- =============================================================================
    [3] = {
        hiddenCoords = vector4(378.7917, -1000.7216, -98.9999, 320.3495),
        pedInterior  = vector3(378.7917, -1000.7216, -98.9999),
        cinematicCam = {
            pos     = vector3(376.2376, -1003.5831, -99.0001),
            pointAt = vector3(376.9164, -991.5180, -98.6050),
        },
        stopCamParams = {
            x = 377.0, y = -1000.0, z = -98.5,
            rotX = 2.0, rotY = 0.0, rotZ = 0.0,
            duration = 2000,
        },
        slots = {
            -- [1] Guitar (dpemotes: guitar)
            [1] = {
                pos  = vector4(376.9164, -991.5180, -98.6050, 185.2975),
                cam  = vector4(374.5976, -995.9521, -98.9999, 335.4564),
                anim = {
                    type = 'animation',
                    dict = 'amb@world_human_musician@guitar@male@idle_a',
                    clip = 'idle_b',
                    prop = {
                        model     = 'prop_acc_guitar_01',
                        bone      = 24818,
                        placement = { -0.1, 0.31, 0.1, 0.0, 20.0, 150.0 },
                    },
                },
                attachToSlot = false,
            },
            -- [2] Sit bar 2 (dpemotes: sitbar2)
            [2] = {
                pos  = vector4(375.8319, -1001.9019, -99.1830, 92.3090),
                cam  = vector4(374.2117, -1003.3367, -98.9999, 294.8478),
                anim = {
                    type = 'animation',
                    dict = 'amb@prop_human_seat_bar@male@elbows_on_bar@idle_b',
                    clip = 'idle_d',
                },
                attachToSlot = false,
            },
            -- [3] Bartender (dpemotes: bartender)
            [3] = {
                pos  = vector4(374.6731, -1000.9058, -99.0000, 268.9113),
                cam  = vector4(376.9442, -1000.7503, -98.9999, 78.0859),
                anim = {
                    type = 'animation',
                    dict = 'anim@amb@clubhouse@bar@drink@idle_a',
                    clip = 'idle_a_bartender',
                },
                attachToSlot = false,
            },
            -- [4] Dance drink 4 (dpemotes: dancedrink4) — whiskey in left hand
            [4] = {
                pos  = vector4(378.8938, -994.4517, -98.9999, 40.7828),
                cam  = vector4(377.0056, -993.1852, -98.9999, 240.8519),
                anim = {
                    type = 'animation',
                    dict = 'anim@amb@nightclub_island@dancers@beachdanceprops@male@',
                    clip = 'mi_idle_b_m04',
                    prop = {
                        model     = 'ba_prop_battle_whiskey_opaque_s',
                        bone      = 28422,
                        placement = { -0.01, 0.0, 0.0, 0.0, 0.0, 10.0 },
                    },
                },
                attachToSlot = false,
            },
            -- [5] Mop 2 (dpemotes: mop2) — mop prop
            [5] = {
                pos  = vector4(381.0228, -1000.9365, -98.9999, 71.2751),
                cam  = vector4(378.6825, -1000.4200, -98.9999, 262.4400),
                anim = {
                    type = 'animation',
                    dict = 'move_mop',
                    clip = 'idle_scrub_small_player',
                    prop = {
                        model     = 'prop_cs_mop_s',
                        bone      = 28422,
                        placement = { 0.0, 0.0, 0.12, 0.0, 0.0, 0.0 },
                    },
                },
                attachToSlot = false,
            },
        },
    },

    -- =============================================================================
    -- LOCATION SET [4] – Biker clubhouse garage (vehicles + min 2 characters)
    -- IPL: bkr_biker_interior_placement_interior_0_biker_dlc_int_01_milo (bob74_ipl BikerClubhouse1)
    -- =============================================================================
    [4] = {
        hiddenCoords   = vector4(1109.9276, -3157.0212, -37.5186, 282.5090),
        pedInterior    = vector3(1109.9276, -3157.0212, -37.5186),
        startCam       = vector3(1116.4662, -3157.1995, -37.0628),
        cinematicCam   = {
            pos     = vector3(1116.4662, -3157.1995, -37.0628),
            pointAt = vector3(1116.6698, -3152.5381, -37.0628),
        },
        stopCamParams  = {
            x = 1110.0, y = -3156.0, z = -37.0,
            rotX = 2.0, rotY = 0.0, rotZ = 0.0,
            duration = 2000,
        },
        useFladeAnim = true,
        ipls = { 'bkr_biker_interior_placement_interior_0_biker_dlc_int_01_milo' },
        --- Only pick this location when at least this many character slots are filled.
        minSlots = 2,
        --- Vehicles to spawn when this location is used; cleared on destroy/stopCinematicCam.
        vehicles = {
            { model = 'champion', pos = vector4(1101.3929, -3157.0500, -38.1455, 267.4560) },
            { model = 'emerus',   pos = vector4(1099.6053, -3145.4443, -38.2254, 180.4957) },
        },
        slots = {
            [1] = {
                pos  = vector4(1117.0592, -3153.5525, -37.0664, 84.1829),
                cam  = vector4(1117.3806, -3154.4219, -37.0628, 53.6555),
                anim = { type = 'animation', dict = 'mini@arm_wrestling', clip = 'nuetral_idle_a' },
                attachToSlot = false,
            },
            [2] = {
                pos  = vector4(1115.9224, -3153.1599, -37.0541, 265.6235),
                cam  = vector4(1117.4832, -3153.9409, -37.0628, 268.7429),
                anim = { type = 'animation', dict = 'mini@arm_wrestling', clip = 'nuetral_idle_b' },
                attachToSlot = false,
            },
            [3] = {
                pos  = vector4(1116.0625, -3149.2783, -37.4674, 196.4084),
                cam  = vector4(1116.4600, -3152.5149, -37.0628, 3.1983),
                anim = { type = 'animation', dict = 'missdrfriedlanderdrf_idles', clip = 'drf_idle_drf' },
                attachToSlot = false,
            },
            [4] = {
                pos  = vector4(1103.6893, -3157.0981, -37.5186, 271.6161),
                cam  = vector4(1108.4808, -3154.1553, -37.3524, 118.4733),
                anim = { type = 'animation', dict = 'switch@michael@sitting_on_car_premiere', clip = 'sitting_on_car_premiere_loop_player' },
                attachToSlot = false,
            },
            [5] = {
                pos  = vector4(1100.7203, -3145.1091, -37.5186, 280.4077),
                cam  = vector4(1102.0, -3146.0, -36.5, 100.0),
                anim = { type = 'animation', dict = 'amb@world_human_leaning@male@wall@back@foot_up@idle_a', clip = 'idle_a' },
                attachToSlot = false,
            },        
        },
    },
}