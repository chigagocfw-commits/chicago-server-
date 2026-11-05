--       _                           _   _             _                   _             _                
--   ___| | ___  __ _ _ __   ___  __| | | |__  _   _  | |__  _ __ __ _  __| |_   _   ___| |_ ___ _ __     
--  / __| |/ _ \/ _` | '_ \ / _ \/ _` | | '_ \| | | | | '_ \| '__/ _` |/ _` | | | | / __| __/ _ \ '_ \    
-- | (__| |  __/ (_| | | | |  __/ (_| | | |_) | |_| | | |_) | | | (_| | (_| | |_| | \__ \ ||  __/ | | |   
--  \___|_|\___|\__,_|_| |_|\___|\__,_| |_.__/ \__, | |_.__/|_|  \__,_|\__,_|\__, | |___/\__\___|_| |_|   
--  / _(_)_  _____  __| | | |__  _   _  | |__  |___/ ___(_)_ __ ___   | |__  |___/_ __ _ __ ___ _ __ __ _ 
-- | |_| \ \/ / _ \/ _` | | '_ \| | | | | '_ \ / _` |_  / | '_ ` _ \  | '_ \ / _ \ '__| '__/ _ \ '__/ _` |
-- |  _| |>  <  __/ (_| | | |_) | |_| | | | | | (_| |/ /| | | | | | | | | | |  __/ |  | | |  __/ | | (_| |
-- |_| |_/_/\_\___|\__,_| |_.__/ \__, | |_| |_|\__,_/___|_|_| |_| |_| |_| |_|\___|_|  |_|  \___|_|  \__,_|
--                               |___/
--   

Config = {}

Config.Framework = "qbcore"  -- Supported frameworks: standalone, qbcore, esx

Config.InterfaceColor = "#ff66ff" -- UI theme color in HEX format (e.g. #ff66ff)

Config.Language = "English" -- UI language used by the script (English)

Config.OxInventory = true -- Enable this if you are using ox_inventory instead of default inventory system

Config.QBCoreNewInventoryVersion = true -- Enable this if you are using the newer QBCore inventory system (fixes item-related errors)

Config.InventorySystem = "oxinventory" -- types (oxinventory, qbcoreinventory, codeminventory, coreinventory, psinventory, chezza, jaksam_inventory, tgiann-inventory) (you can add your own inventory system in server/other.lua)

Config.SmokingInteractionSystem = 1 -- Interaction style: 1 = Custom interaction, 2 = 3D Text, 3 = GTA Online style, 4 = Floating Text Box Style

Config.Target = false -- Enable target-based interaction (true/false)

Config.Targettype = "oxtarget" -- Target system type: qtarget, qbtarget, oxtarget

Config.TargetSystemsNames = {qtarget = "qtarget", qbtarget = "qb-target", oxtarget = "ox_target"} -- target resource names

Config.TargetIcons = {hookahmanage = "fa-solid fa-list", hookahgrab = "fa-solid fa-smoking"} -- FontAwesome icons used by target interactions

Config.HookahUseKey = "e" -- Key used to interact with the hookah

Config.HookahHoseKey = "g" -- Key used to take or return a hookah hose

Config.HookahRenderDistance = 100.0 -- Maximum distance where hookah objects are rendered

Config.HookahInteractDistance = 2.5 -- Distance required to interact with an hookah

Config.MaxHoses = 2 -- Maximum number of hoses available per hookah

Config.DebugMode = false -- Enables debug prints for hookah system

Config.CoalItem = "shisha_charcoal_box" -- Inventory item used as hookah charcoal

Config.CoalHeatDuration = 15000 -- Time required to heat hookah coal in milliseconds
Config.CoalHeatUpdateInterval = 500 -- Coal heating progress update interval in milliseconds

Config.CoalBurnDuration = 1200000 -- Total coal burn duration in milliseconds
Config.CoalBurnUpdateInterval = 1000 -- Coal burn status update interval in milliseconds

Config.HookahConsumeInterval = 15000 -- Interval for hookah resource consumption in milliseconds
Config.HookahWaterConsume = 3 -- Water amount consumed each hookah tick
Config.HookahTobaccoConsume = 4 -- Tobacco amount consumed each hookah tick
Config.HookahLowWaterLevel = 25 -- Water percentage considered low for hookah use

Config.HookahMaxHoseDistance = 3.0 -- Maximum distance allowed between player and hookah hose

Config.StaticHookahs = {
    [1] = {
        label = "Hookah Bar", -- Display name of the static hookah
        enabled = true, -- Enable or disable this static hookah
        hookahType = 1, -- Hookah type from Config.HookahTypes
        coords = vector3(-557.26, 291.45, 81.17), -- Hookah position
        rotation = vector3(0.0, 0.0, 90.0), -- Hookah rotation

        defaultState = {
            water = { state = "good", level = 100 }, -- Default water state
            tobacco = { state = "prepared", amount = 100, flavor = "Apple" }, -- Default tobacco state
            coal = { state = "placed", progress = 100, durability = 100 }, -- Default coal state
            hoses = { connected = 0, max = 4, players = {} }, -- Hose settings
        },

        managePermissions = {
            everyone = true, -- Allow everyone to manage the hookah
            permissions = {
                { permissiontype = "ace", permission = "hookah.manage" }, -- ACE permission
                { permissiontype = "job", permission = "bahama" }, -- Job permission
                { permissiontype = "identifier", permission = "license:4627fc0ed39b69032cdcb747edf01fbe4a7e67d2" }, -- Identifier permission
            },
        },
    },

    [2] = {
        label = "Empty Hookah", -- Display name of the static hookah
        enabled = true, -- Enable or disable this static hookah
        hookahType = 2, -- Hookah type from Config.HookahTypes
        coords = vector3(2.78, 527.38, 174.18), -- Hookah position
        rotation = vector3(0.0, 0.0, 180.0), -- Hookah rotation

        defaultState = {
            water = { state = "empty", level = 0 }, -- Empty water state
            tobacco = { state = "empty", amount = 0, flavor = nil }, -- Empty tobacco state
            coal = { state = "missing", progress = 0, durability = 0 }, -- No coal placed
            hoses = { connected = 0, max = 4, players = {} }, -- Hose settings
        },

        managePermissions = {
            everyone = true, -- Allow everyone to manage the hookah
            permissions = {
                { permissiontype = "ace", permission = "hookah.manage" }, -- ACE permission
                -- { permissiontype = "job", permission = "bahama" }, -- Job permission
                -- { permissiontype = "identifier", permission = "license:4627fc0ed39b69032cdcb747edf01fbe4a7e67d2" }, -- Identifier permission
            },
        },
    },
}

Config.HookahAdmin = { -- Admin / staff controls for hookahs (commands + forced removal from the hookah menu)
    enabled = true, -- Enable the admin hookah controls

    everyone = false, -- Allow everyone to use the admin hookah controls (only for testing, keep this false on a live server)

    permissions = { -- Who counts as a hookah admin (any matching rule grants access)
        { permissiontype = "ace", permission = "hookah.admin" }, -- ACE permission, add "add_ace group.admin hookah.admin allow" to your server.cfg
        -- { permissiontype = "job", permission = "police" }, -- Job permission, uncomment and change the job name to use it
        -- { permissiontype = "identifier", permission = "license:4627fc0ed39b69032cdcb747edf01fbe4a7e67d2" }, -- Identifier permission, uncomment and change the identifier to use it
    },

    allowStaticRemoval = true, -- Allow hookah admins to remove static hookahs; ordinary managers cannot
    forceDisconnectHoses = true, -- Force-disconnect every connected hose before removing a hookah instead of refusing the removal
    returnItemToAdmin = false, -- Give the hookah item to the admin who removed it (false = the hookah is simply deleted)

    defaultRadius = 5.0, -- Default search radius for the nearby commands
    maxRadius = 100.0, -- Maximum radius a command is allowed to use

    logToConsole = true, -- Print every admin hookah removal to the server console

    commands = { -- Command names (set a value to false to disable that command)
        removeNearby = "removehookah", -- /removehookah [id] - removes the nearest hookah, or the hookah with the given id
        removeRadius = "removehookahs", -- /removehookahs [radius] - removes every hookah inside the radius
        removeAll = "removeallhookahs", -- /removeallhookahs - removes every placed hookah on the server
        cleanNearby = "cleanhookah", -- /cleanhookah [id] - resets water, tobacco and coal of the nearest hookah
        list = "hookahlist", -- /hookahlist - prints every hookah with its id, owner and coords
    },
}

Config.HookahSmokeEffect = { -- Hookah exhale smoke particle settings
    dict = "core", -- Animation or particle dictionary name
    name = "exp_grd_bzgas_smoke", -- Particle effect name

    minHoldMs = 300, -- Minimum hold duration in milliseconds
    maxHoldMs = 5000, -- Maximum hold duration in milliseconds

    minSmokeTimeMs = 800, -- Minimum hookah smoke duration in milliseconds
    maxSmokeTimeMs = 5000, -- Maximum hookah smoke duration in milliseconds

    scale = 0.3, -- Particle or effect scale

    bone = 47495, -- Ped bone index used for prop attachment
    offset = vec3(0.15, 0.0, 0.0), -- Position offset relative to the bone or prop
    rotation = vec3(0.0, 0.0, 0.0) -- Rotation offset relative to the bone or prop
}

Config.SoundEffects = true -- Enable synced sound effects
Config.SoundEffectsVolume = 0.45 -- Default sound volume
Config.SoundEffectsDistance = 5.0 -- Max distance where players can hear sounds

Config.SoundLoopMaxDurationMs = 20000 -- Safety limit for looping sounds (inhale/bong/vape/hookah) in milliseconds
-- Any loop still running after this time is stopped automatically on both the client and the server.
-- This is a fail-safe for edge cases (death, crash, teleport, lost event) and should stay well above your longest possible puff.

Config.SoundLoopAutoStopOnDistance = true -- Automatically stop a looping sound when the player who started it walks out of Config.SoundEffectsDistance
Config.SoundLoopOutOfRangeGraceMs = 3000 -- How long a looping sound stays silently alive after the source player left the hearing range, in milliseconds
-- Out of range the loop is muted immediately and only stopped after this grace time, so briefly stepping away does not cut the sound short.
-- Looping sounds also fade with distance while they play and stop instantly when the source player dies or despawns.


Config.Sounds = {
    inhalenormal = "sounds/inhalenormal.mp3", -- Default inhale sound for cigarettes, cigars, joints
    bongLoop = "sounds/bong.mp3", -- Loop sound while inhaling from bong (water bubbling)
    
    cough_male = "sounds/coughmale.mp3", -- Male cough sound (used on strong hits or forced release)
    cough_female = "sounds/coughfemale.mp3", -- Female cough sound (used on strong hits or forced release)
    
    exhalemale = "sounds/exhalemale.mp3", -- Male exhale sound (optional, if using gender-based exhale)
    exhalefemale = "sounds/exhalefemale.mp3", -- Female exhale sound (optional, if using gender-based exhale)
    
    lighter = "sounds/lighter.mp3", -- Lighter ignition sound (used when lighting cigarettes/joints)
    
    hookahInhale = "sounds/hookah.mp3", -- Loop sound while inhaling from hookah (soft bubbling/airflow)
    
    vape = "sounds/vape.mp3", -- Vape inhale
}

Config.ItemNames = { -- if you want to change the item names you can do it here
	["rolling_paper"] = "rolling_paper",  -- item give name
	["water"] = "water", -- item give name
	["vape_battery"] = "vape_battery", -- item give name
	["lighter"] = "lighter", -- item give name
}

Config.HookahTypes = { -- Available hookah models and colors
    [1] = {
        label = "Shisha (Blue)", -- Display name shown in the UI
        item = "shisha_0", -- Inventory item name
		color = 0, -- Hookah color variation index
    },

    [2] = {
        label = "Shisha (Red)", -- Display name shown in the UI
        item = "shisha_1", -- Inventory item name
		color = 1, -- Hookah color variation index
    },

    [3] = {
        label = "Shisha (Pink)", -- Display name shown in the UI
        item = "shisha_2", -- Inventory item name
		color = 2, -- Hookah color variation index
    },

    [4] = {
        label = "Shisha (Green)", -- Display name shown in the UI
        item = "shisha_3", -- Inventory item name
		color = 3, -- Hookah color variation index
    },

    [5] = {
        label = "Shisha (Yellow)", -- Display name shown in the UI
        item = "shisha_4", -- Inventory item name
		color = 4, -- Hookah color variation index
    },

    [6] = {
        label = "Shisha (Gray)", -- Display name shown in the UI
        item = "shisha_5", -- Inventory item name
		color = 5, -- Hookah color variation index
    },
}

Config.HookahFlavors = { -- Available shisha tobacco flavor varieties
    ["apple"] = {
        label = "Apple", -- Display name shown in the UI
        itemname = "shisha_tobacco_apple", -- Required inventory item
        type = "classic" -- Internal type identifier
    },

    ["blueberry"] = {
        label = "Blueberry", -- Display name shown in the UI
        itemname = "shisha_tobacco_blueberry", -- Required inventory item
        type = "sweet" -- Internal type identifier
    },

    ["lemon"] = {
        label = "Lemon", -- Display name shown in the UI
        itemname = "shisha_tobacco_lemon", -- Required inventory item
        type = "citrus" -- Internal type identifier
    },

    ["mint"] = {
        label = "Mint", -- Display name shown in the UI
        itemname = "shisha_tobacco_mint", -- Required inventory item
        type = "fresh" -- Internal type identifier
    },

    ["orange"] = {
        label = "Orange", -- Display name shown in the UI
        itemname = "shisha_tobacco_orange", -- Required inventory item
        type = "citrus" -- Internal type identifier
    },

    ["strawberry"] = {
        label = "Strawberry", -- Display name shown in the UI
        itemname = "shisha_tobacco_strawberry", -- Required inventory item
        type = "sweet" -- Internal type identifier
    },

    ["vanilla"] = {
        label = "Vanilla", -- Display name shown in the UI
        itemname = "shisha_tobacco_vanilla", -- Required inventory item
        type = "dessert" -- Internal type identifier
    },

    ["watermelon"] = {
        label = "Watermelon", -- Display name shown in the UI
        itemname = "shisha_tobacco_watermelon", -- Required inventory item
        type = "refreshing" -- Internal type identifier
    },
}

Config.HoldKey = 38 -- Key used to hold/use the smoking item (E)

Config.Debug = false -- Enables general debug mode

Config.CycleIdleKey = 104 -- Key to cycle cigarette position while idle (cigarette position change) (H)

Config.SecretSwitchPuffKey = 137 -- Key to switch puff style secretly (Caps Lock)

Config.CancelKey = 177 -- Key to cancel smoking action (stop smoking) (Backspace)

Config.SettingsKey = 23 -- Key to open settings for the current smoking type (F)

Config.GiveKey = 47 -- Key to give a smoking item to another player (G)

Config.GiveDistance = 3.0 -- Maximum distance for giving a smoking item to another player

Config.SelectionSets = { -- Selectable refill or strain options for supported item types
	["vape"] = {
		["apple"] = {
			label = "Apple", -- Display name shown in the UI
			itemname = "eliquid_box_apple", -- Required inventory item
			image = "eliquid_box_apple.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_apple", -- Used object model
			category = "Crisp and refreshing apple flavor" -- Category or description in the selection UI
		},

		["blueberry"] = {
			label = "Blueberry", -- Display name shown in the UI
			itemname = "eliquid_box_blueberry", -- Required inventory item
			image = "eliquid_box_blueberry.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_blueberry", -- Used object model
			category = "Sweet and juicy blueberry flavor" -- Category or description in the selection UI
		},

		["cherry"] = {
			label = "Cherry", -- Display name shown in the UI
			itemname = "eliquid_box_cherry", -- Required inventory item
			image = "eliquid_box_cherry.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_cherry", -- Used object model
			category = "Rich and lightly tart cherry flavor" -- Category or description in the selection UI
		},

		["ecola"] = {
			label = "eCola", -- Display name shown in the UI
			itemname = "eliquid_box_ecola", -- Required inventory item
			image = "eliquid_box_ecola.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_ecola", -- Used object model
			category = "Classic sparkling cola experience" -- Category or description in the selection UI
		},

		["grape"] = {
			label = "Grape", -- Display name shown in the UI
			itemname = "eliquid_box_grape", -- Required inventory item
			image = "eliquid_box_grape.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_grape", -- Used object model
			category = "Bold and sweet grape aroma" -- Category or description in the selection UI
		},

		["lemon"] = {
			label = "Lemon", -- Display name shown in the UI
			itemname = "eliquid_box_lemon", -- Required inventory item
			image = "eliquid_box_lemon.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_lemon", -- Used object model
			category = "Sharp and zesty citrus accent" -- Category or description in the selection UI
		},

		["mint"] = {
			label = "Mint", -- Display name shown in the UI
			itemname = "eliquid_box_mint", -- Required inventory item
			image = "eliquid_box_mint.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_mint", -- Used object model
			category = "Cool and refreshing mint breeze" -- Category or description in the selection UI
		},

		["orange"] = {
			label = "Orange", -- Display name shown in the UI
			itemname = "eliquid_box_orange", -- Required inventory item
			image = "eliquid_box_orange.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_orange", -- Used object model
			category = "Fresh and juicy orange flavor" -- Category or description in the selection UI
		},

		["peach"] = {
			label = "Peach", -- Display name shown in the UI
			itemname = "eliquid_box_peach", -- Required inventory item
			image = "eliquid_box_peach.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_peach", -- Used object model
			category = "Soft and sweet peach flavor" -- Category or description in the selection UI
		},

		["strawberry"] = {
			label = "Strawberry", -- Display name shown in the UI
			itemname = "eliquid_box_strawberry", -- Required inventory item
			image = "eliquid_box_strawberry.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_strawberry", -- Used object model
			category = "Sweet and fruity strawberry delight" -- Category or description in the selection UI
		},

		["vanilla"] = {
			label = "Vanilla", -- Display name shown in the UI
			itemname = "eliquid_box_vanilla", -- Required inventory item
			image = "eliquid_box_vanilla.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_vanilla", -- Used object model
			category = "Smooth and creamy vanilla aroma" -- Category or description in the selection UI
		},

		["watermelon"] = {
			label = "Watermelon", -- Display name shown in the UI
			itemname = "eliquid_box_watermelon", -- Required inventory item
			image = "eliquid_box_watermelon.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_eliquid_flask_watermelon", -- Used object model
			category = "Light and juicy summer watermelon flavor" -- Category or description in the selection UI
		}
	},

    ["bong"] = {
		["og_kush"] = {
			label = "OG Kush", -- Display name shown in the UI
			itemname = "weed_og_kush", -- Required inventory item
			image = "weed_og_kush.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_weed_og", -- Used object model
			category = "Strong classic strain with earthy aroma" -- Category or description in the selection UI
		},

		["purple_haze"] = {
			label = "Purple Haze", -- Display name shown in the UI
			itemname = "weed_purple_haze", -- Required inventory item
			image = "weed_purple_haze.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_weed_purple", -- Used object model
			category = "Sweet aromatic strain with a smooth smoke" -- Category or description in the selection UI
		},

		["amnesia_haze"] = {
			label = "Amnesia Haze", -- Display name shown in the UI
			itemname = "weed_amnesia_haze", -- Required inventory item
			image = "weed_amnesia_haze.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_weed_haze", -- Used object model
			category = "Citrusy strain with a strong kick" -- Category or description in the selection UI
		},

		["white_widow"] = {
			label = "White Widow", -- Display name shown in the UI
			itemname = "weed_white_widow", -- Required inventory item
			image = "weed_white_widow.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_weed_white", -- Used object model
			category = "Balanced hybrid with dense smoke" -- Category or description in the selection UI
		}
    },

    ["joint"] = {
		["og_kush"] = {
			label = "OG Kush", -- Display name shown in the UI
			itemname = "weed_og_kush", -- Required inventory item
			itemnamecrafted = "joint_og_kush", -- Crafted inventory item
			image = "weed_og_kush.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_weed_og", -- Used object model
			category = "Strong classic strain with earthy aroma" -- Category or description in the selection UI
		},

		["purple_haze"] = {
			label = "Purple Haze", -- Display name shown in the UI
			itemname = "weed_purple_haze", -- Required inventory item
			itemnamecrafted = "joint_purple_haze", -- Crafted inventory item
			image = "weed_purple_haze.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_weed_purple", -- Used object model
			category = "Sweet aromatic strain with a smooth smoke" -- Category or description in the selection UI
		},

		["amnesia_haze"] = {
			label = "Amnesia Haze", -- Display name shown in the UI
			itemname = "weed_amnesia_haze", -- Required inventory item
			itemnamecrafted = "joint_amnesia_haze", -- Crafted inventory item
			image = "weed_amnesia_haze.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_weed_haze", -- Used object model
			category = "Citrusy strain with a strong kick" -- Category or description in the selection UI
		},

		["white_widow"] = {
			label = "White Widow", -- Display name shown in the UI
			itemname = "weed_white_widow", -- Required inventory item
			itemnamecrafted = "joint_white_widow", -- Crafted inventory item
			image = "weed_white_widow.png", -- Image file used in the UI
			object = "rtx_sempre_smoking_weed_white", -- Used object model
			category = "Balanced hybrid with dense smoke" -- Category or description in the selection UI
		}
    },

    ["shisha"] = {
        ["apple"] = {
            label = "Apple", -- Display name shown in the UI
            itemname = "shisha_tobacco_apple", -- Required inventory item
            category = "classic" -- Category or description in the selection UI
        },

        ["blueberry"] = {
            label = "Blueberry", -- Display name shown in the UI
            itemname = "shisha_tobacco_blueberry", -- Required inventory item
            category = "sweet" -- Category or description in the selection UI
        },

        ["lemon"] = {
            label = "Lemon", -- Display name shown in the UI
            itemname = "shisha_tobacco_lemon", -- Required inventory item
            category = "citrus" -- Category or description in the selection UI
        },

        ["mint"] = {
            label = "Mint", -- Display name shown in the UI
            itemname = "shisha_tobacco_mint", -- Required inventory item
            category = "fresh" -- Category or description in the selection UI
        },

        ["orange"] = {
            label = "Orange", -- Display name shown in the UI
            itemname = "shisha_tobacco_orange", -- Required inventory item
            category = "citrus" -- Category or description in the selection UI
        },

        ["strawberry"] = {
            label = "Strawberry", -- Display name shown in the UI
            itemname = "shisha_tobacco_strawberry", -- Required inventory item
            category = "sweet" -- Category or description in the selection UI
        },

        ["vanilla"] = {
            label = "Vanilla", -- Display name shown in the UI
            itemname = "shisha_tobacco_vanilla", -- Required inventory item
            category = "dessert" -- Category or description in the selection UI
        },

        ["watermelon"] = {
            label = "Watermelon", -- Display name shown in the UI
            itemname = "shisha_tobacco_watermelon", -- Required inventory item
            category = "refreshing" -- Category or description in the selection UI
        }
    }
}

Config.PackOpenRewards = {
    ["cigarette_redwood_pack"] = { -- Reward for opening a Redwood cigarette pack
        item = 'cigarette_redwood', -- Item received when opened
        count = 20 -- Amount of item received
    },

    ["cigarette_debonair_pack"] = { -- Reward for opening a Debonaire cigarette pack
        item = 'cigarette_debonair', -- Item received when opened
        count = 20 -- Amount of item received
    },

    ["cigar_estancia_pack"] = { -- Reward for opening an Estancia cigar pack
        item = 'cigar_estancia', -- Item received when opened
        count = 5 -- Amount of item received
    },

    ["rolling_papers_pack"] = { -- Reward for opening a rolling paper pack
        item = 'rolling_paper', -- Item received when opened
        count = 20 -- Amount of item received
    }
}

Config.ProgressActions = { -- Progress bar actions and animations
    ["change_battery"] = {
        title = "Vape", -- Progress bar title
        label = "Battery is being changed...", -- Display name shown in the UI
        icon = "fa-solid fa-battery-half", -- FontAwesome icon shown in the UI
        time = 4000, -- Duration of the progress action in milliseconds
        canCancel = true, -- Allows the player to cancel this action
        animation = { -- Animation settings for the progress action
            enabled = true, -- Enables or disables this feature
            dict = "mp_arresting", -- Animation or particle dictionary name
            anim = "a_uncuff", -- Animation clip name
            flag = 49 -- Animation flag controlling playback
        }
    },

    ["fill_water"] = {
        title = "Bong", -- Progress bar title
        label = "Water is being changed...", -- Display name shown in the UI
        icon = "fa-solid fa-droplet", -- FontAwesome icon shown in the UI
        time = 3500, -- Duration of the progress action in milliseconds
        canCancel = true, -- Allows the player to cancel this action
        animation = { -- Animation settings for the progress action
            enabled = true, -- Enables or disables this feature
            dict = "vapeliquid@rtx", -- Animation or particle dictionary name
            anim = "vapeliquid", -- Animation clip name
            flag = 49 -- Animation flag controlling playback
        }
    },

    ["fill_bong"] = {
        title = "Bong", -- Progress bar title
        label = "Bong is being filled...", -- Display name shown in the UI
        icon = "fa-solid fa-cannabis", -- FontAwesome icon shown in the UI
        time = 3500, -- Duration of the progress action in milliseconds
        canCancel = true, -- Allows the player to cancel this action
        animation = { -- Animation settings for the progress action
            enabled = true, -- Enables or disables this feature
            dict = "mp_arresting", -- Animation or particle dictionary name
            anim = "a_uncuff", -- Animation clip name
            flag = 49 -- Animation flag controlling playback
        }
    },

    ["fill_flavour"] = {
        title = "Vape", -- Progress bar title
        label = "Flavor is being filled...", -- Display name shown in the UI
        icon = "fa-solid fa-bottle-droplet", -- FontAwesome icon shown in the UI
        time = 4500, -- Duration of the progress action in milliseconds
        canCancel = true, -- Allows the player to cancel this action
        animation = { -- Animation settings for the progress action
            enabled = true, -- Enables or disables this feature
            dict = "vapeliquid@rtx", -- Animation or particle dictionary name
            anim = "vapeliquid", -- Animation clip name
            flag = 49 -- Animation flag controlling playback
        }
    },

    ["craft_joint"] = {
        title = "Joint", -- Progress bar title
        label = "Joint is being rolled...", -- Display name shown in the UI
        icon = "fa-solid fa-cannabis", -- FontAwesome icon shown in the UI
        time = 5000, -- Duration of the progress action in milliseconds
        canCancel = true, -- Allows the player to cancel this action
        animation = { -- Animation settings for the progress action
            enabled = true, -- Enables or disables this feature
            dict = "mp_arresting", -- Animation or particle dictionary name
            anim = "a_uncuff", -- Animation clip name
            flag = 49 -- Animation flag controlling playback
        }
    }
}

Config.AttachPresets = { -- Attachment presets for props, bones, offsets, and rotations
    ["cigarette_classic"] = {
        mainItem = { -- Attachment settings for the main smoking prop
            idleVariants = { -- Idle prop placement variants
                hand = { -- Hand attachment
                    bone = 57005, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.118000, 0.046000, -0.001000), -- Position offset relative to the bone or prop
                    rotation = vec3(-70.849998, -75.650002, 5.800000) -- Rotation offset relative to the bone or prop
                },

                ear = { -- Ear attachment
                    bone = 31086, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.056000, -0.038000, -0.073000), -- Position offset relative to the bone or prop
                    rotation = vec3(52.000000, -15.150000, -92.199997) -- Rotation offset relative to the bone or prop
                }
            },

            light = { -- Animation or attachment settings for the lighting
                bone = 31086, -- Skeleton bone index for the prop attachment
                offset = vec3(-0.015000, 0.119000, -0.002000), -- Position offset relative to the bone or prop
                rotation = vec3(0.000000, 0.000000, -53.950001) -- Rotation offset relative to the bone or prop
            },
			puffStyles = { -- Available puff animation styles
				[1] = {
					bone = 57005, -- Skeleton bone index for the prop attachment
					offset = vec3(0.171000, 0.017000, -0.009000), -- Position offset relative to the bone or prop
					rotation = vec3(9.300000, 95.150002, -3.650000) -- Rotation offset relative to the bone or prop
				},

				[2] = {
					bone = 6286, -- Skeleton bone index for the prop attachment
					offset = vec3(0.0929, 0.0662, -0.0382), -- Position offset relative to the bone or prop
					rotation = vec3(0.0, 0.0, 90.0) -- Rotation offset relative to the bone or prop
				}
			},
        }, 
        secondaryItem = { -- Attachment settings for the secondary prop
            enabled = true, -- Enables or disables this feature
            model = "p_cs_lighter_01", -- Model name of the secondary prop
            phase = "light", -- Action phase in which this secondary object is shown

            light = { -- Animation or attachment settings for the lighting
                bone = 57005, -- Skeleton bone index for the prop attachment
                offset = vec3(0.123000, 0.018000, -0.019000), -- Position offset relative to the bone or prop
                rotation = vec3(-63.650002, 16.400000, -26.250000) -- Rotation offset relative to the bone or prop
            }
        }
    },
    ["cigar"] = {
        mainItem = { -- Attachment settings for the main smoking prop
            idleVariants = { -- Idle prop placement variants
                hand = { -- Hand attachment
                    bone = 57005, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.157000, 0.048000, 0.001000), -- Position offset relative to the bone or prop
                    rotation = vec3(45.799999, 156.000000, 70.650002) -- Rotation offset relative to the bone or prop
                },

                ear = { -- Ear attachment
                    bone = 31086, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.072000, 0.038000, -0.085000), -- Position offset relative to the bone or prop
                    rotation = vec3(52.000000, -15.150000, -92.199997) -- Rotation offset relative to the bone or prop
                }
            },

            light = { -- Animation or attachment settings for the lighting
                bone = 31086, -- Skeleton bone index for the prop attachment
                offset = vec3(-0.000000, 0.091000, -0.003000), -- Position offset relative to the bone or prop
                rotation = vec3(16.049999, 0.000000, 117.900002) -- Rotation offset relative to the bone or prop
            },
			puffStyles = { -- Available puff animation styles
				[1] = {
					bone = 57005, -- Skeleton bone index for the prop attachment
					offset = vec3(0.161000, 0.026000, -0.019000), -- Position offset relative to the bone or prop
					rotation = vec3(9.200000, 261.500000, 51.150002), -- Rotation offset relative to the bone or prop
				},
				[2] = {
					bone = 31086, -- Skeleton bone index for the prop attachment
					offset = vec3(0.002000, 0.086000, 0.000000), -- Position offset relative to the bone or prop
					rotation = vec3(0.000000, 0.000000, 112.050003), -- Rotation offset relative to the bone or prop
				},
			},			
        },
        secondaryItem = { -- Attachment settings for the secondary prop
            enabled = true, -- Enables or disables this feature
            model = "p_cs_lighter_01", -- Model name of the secondary prop
            phase = "light", -- Action phase in which this secondary object is shown

            light = { -- Animation or attachment settings for the lighting
                bone = 57005, -- Skeleton bone index for the prop attachment
                offset = vec3(0.123000, 0.018000, -0.019000), -- Position offset relative to the bone or prop
                rotation = vec3(-63.650002, 16.400000, -26.250000) -- Rotation offset relative to the bone or prop
            }
        }
    },	
    ["joint"] = {
        mainItem = { -- Attachment settings for the main smoking prop
            idleVariants = { -- Idle prop placement variants
                hand = { -- Hand attachment
                    bone = 57005, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.118000, 0.046000, -0.001000), -- Position offset relative to the bone or prop
                    rotation = vec3(-70.849998, -75.650002, 5.800000) -- Rotation offset relative to the bone or prop
                },

                ear = { -- Ear attachment
                    bone = 31086, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.056000, -0.038000, -0.073000), -- Position offset relative to the bone or prop
                    rotation = vec3(52.000000, -15.150000, -92.199997) -- Rotation offset relative to the bone or prop
                }
            },

            light = { -- Animation or attachment settings for the lighting
                bone = 31086, -- Skeleton bone index for the prop attachment
                offset = vec3(-0.017000, 0.126000, -0.002000), -- Position offset relative to the bone or prop
                rotation = vec3(1.500000, 0.000000, -67.800003) -- Rotation offset relative to the bone or prop
            },

			puffStyles = { -- Available puff animation styles
				[1] = {
					bone = 57005, -- Skeleton bone index for the prop attachment
					offset = vec3(0.171000, 0.017000, -0.009000), -- Position offset relative to the bone or prop
					rotation = vec3(9.300000, 95.150002, -3.650000), -- Rotation offset relative to the bone or prop
				},
				[2] = {
					bone = 31086, -- Skeleton bone index for the prop attachment
					offset = vec3(-0.019000, 0.130000, -0.004000), -- Position offset relative to the bone or prop
					rotation = vec3(22.400000, 0.000000, -56.000000), -- Rotation offset relative to the bone or prop
				},
			},				
        },
        secondaryItem = { -- Attachment settings for the secondary prop
            enabled = true, -- Enables or disables this feature
            model = "p_cs_lighter_01", -- Model name of the secondary prop
            phase = "light", -- Action phase in which this secondary object is shown

            light = { -- Animation or attachment settings for the lighting
                bone = 57005, -- Skeleton bone index for the prop attachment
                offset = vec3(0.123000, 0.018000, -0.019000), -- Position offset relative to the bone or prop
                rotation = vec3(-63.650002, 16.400000, -26.250000) -- Rotation offset relative to the bone or prop
            }
        }
    },	
    ["vape_pen_a"] = {
        mainItem = { -- Attachment settings for the main smoking prop
            idle = { -- Idle animation or attachment settings
                bone = 57005, -- Skeleton bone index for the prop attachment
                offset = vec3(0.139000, 0.038000, -0.021000), -- Position offset relative to the bone or prop
                rotation = vec3(-80.449997, 0.000000, -3.700001) -- Rotation offset relative to the bone or prop
            },
            progress = { -- Attachment settings during progress actions
                fillFlavour = { -- Attachment while refilling the vape flavor
                    bone = 57005, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.116000, 0.059000, -0.049000), -- Position offset relative to the bone or prop
                    rotation = vec3(310.250000, 50.700001, 64.949997), -- Rotation offset relative to the bone or prop
                },
            },
            puff = { -- Puff action settings
                bone = 57005, -- Skeleton bone index for the prop attachment
                offset = vec3(0.110000, 0.024000, -0.022000), -- Position offset relative to the bone or prop
                rotation = vec3(-70.900002, 6.400000, -24.799990) -- Rotation offset relative to the bone or prop
            }
        },
        secondaryItem = { -- Attachment settings for the secondary prop
            enabled = false, -- Enables or disables this feature
            progress = { -- Attachment settings during progress actions
                fillFlavour = { -- Attachment while refilling the vape flavor
                    bone = 18905, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.151000, 0.010000, 0.053000), -- Position offset relative to the bone or prop
                    rotation = vec3(-1.600000, -4.699998, -4.850000), -- Rotation offset relative to the bone or prop
                },
            },	
        }
    },

    ["vape_pen_b"] = {
        mainItem = { -- Attachment settings for the main smoking prop
            idle = { -- Idle animation or attachment settings
                bone = 57005, -- Skeleton bone index for the prop attachment
                offset = vec3(0.093000, -0.031000, -0.038000), -- Position offset relative to the bone or prop
                rotation = vec3(-59.150002, 23.400000, -0.950000) -- Rotation offset relative to the bone or prop
            },
            progress = { -- Attachment settings during progress actions
                fillFlavour = { -- Attachment while refilling the vape flavor
                    bone = 57005, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.114000, -0.010000, -0.071000), -- Position offset relative to the bone or prop
                    rotation = vec3(-55.349998, 52.150002, 66.849998), -- Rotation offset relative to the bone or prop
                },
            },
            puff = { -- Puff action settings
                bone = 57005, -- Skeleton bone index for the prop attachment
                offset = vec3(0.068000, -0.029000, -0.027000), -- Position offset relative to the bone or prop
                rotation = vec3(-20.450001, 76.900002, 53.250000) -- Rotation offset relative to the bone or prop
            }
        },

        secondaryItem = { -- Attachment settings for the secondary prop
            enabled = false, -- Enables or disables this feature
            progress = { -- Attachment settings during progress actions
                fillFlavour = { -- Attachment while refilling the vape flavor
                    bone = 18905, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.151000, 0.010000, 0.053000), -- Position offset relative to the bone or prop
                    rotation = vec3(-12.600000, -4.699998, -4.850000), -- Rotation offset relative to the bone or prop
                },
            },				
        }
    },
    ["bong_classic"] = {
        mainItem = { -- Attachment settings for the main smoking prop
            idle = { -- Idle animation or attachment settings
                bone = 57005, -- Skeleton bone index for the prop attachment
                offset = vec3(0.120000, -0.205000, -0.116000), -- Position offset relative to the bone or prop
                rotation = vec3(-29.449997, 64.199997, 71.69999) -- Rotation offset relative to the bone or prop
            },
            progress = { -- Attachment settings during progress actions
                fillWater = { -- Attachment while filling with water
                    bone = 57005, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.167000, -0.302000, -0.158000), -- Position offset relative to the bone or prop
                    rotation = vec3(21.549999, 69.650002, 107.250000), -- Rotation offset relative to the bone or prop
                },
            },
            puff = { -- Puff action settings
                bone = 57005, -- Skeleton bone index for the prop attachment
                offset = vec3(0.060000, -0.205000, -0.116000), -- Position offset relative to the bone or prop
                rotation = vec3(-29.449997, 64.199997, 71.69999) -- Rotation offset relative to the bone or prop
            }
        },

        secondaryItem = { -- Attachment settings for the secondary prop
            enabled = true, -- Enables or disables this feature
            model = "p_cs_lighter_01", -- Model name of the secondary prop
            phase = "puff", -- Action phase in which this secondary object is shown

            idle = { -- Idle animation or attachment settings
                bone = 18905, -- Skeleton bone index for the prop attachment
                offset = vec3(0.139000, 0.007000, 0.027000), -- Position offset relative to the bone or prop
                rotation = vec3(13.950000, 90.400002, 56.299995) -- Rotation offset relative to the bone or prop
            },
            progress = { -- Attachment settings during progress actions
                fillWater = { -- Attachment while filling with water
                    bone = 18905, -- Skeleton bone index for the prop attachment
                    offset = vec3(0.141000, 0.014000, -0.006000), -- Position offset relative to the bone or prop
                    rotation = vec3(-1.850000, -9.850000, 10.400000), -- Rotation offset relative to the bone or prop
                },
            },	
            puff = { -- Puff action settings
                bone = 18905, -- Skeleton bone index for the prop attachment
                offset = vec3(0.139000, 0.007000, 0.027000), -- Position offset relative to the bone or prop
                rotation = vec3(13.950000, 90.400002, 56.299995) -- Rotation offset relative to the bone or prop
            }
        }
    }
}

Config.SmokingVariants = { -- Configured usable smoking item variants
    ["cigarette_redwood"] = {
        item = "cigarette_redwood", -- Inventory item name
        type = "cigarette", -- Internal type identifier
        label = "Cigarette", -- Display name shown in the UI
        brand = "Redwood", -- Brand displayed for this variant
        image = "cigarette.png", -- Image file used in the UI
        prop = "prop_cs_ciggy_01b", -- Prop model spawned for this variant
        attachPreset = "cigarette_classic" -- Used attachment preset
    },

    ["cigarette_debonair"] = {
        item = "cigarette_debonair", -- Inventory item name
        type = "cigarette", -- Internal type identifier
        label = "Cigarette", -- Display name shown in the UI
        brand = "Debonaire", -- Brand displayed for this variant
        image = "cigarette.png", -- Image file used in the UI
        prop = "prop_cs_ciggy_01b", -- Prop model spawned for this variant
        attachPreset = "cigarette_classic" -- Used attachment preset
    },

    ["cigar_estancia"] = {
        item = "cigar_estancia", -- Inventory item name
        type = "cigar", -- Internal type identifier
        label = "Cigar", -- Display name shown in the UI
        brand = "Estancia", -- Brand displayed for this variant
        image = "cigar.png", -- Image file used in the UI
        prop = "prop_cigar_03", -- Prop model spawned for this variant
        attachPreset = "cigar" -- Used attachment preset
    },

    ["joint_og_kush"] = {
        item = "joint_og_kush", -- Inventory item name
        type = "joint", -- Internal type identifier
        label = "Joint", -- Display name shown in the UI
        image = "joint.png", -- Image file used in the UI
        prop = "p_cs_joint_01", -- Prop model spawned for this variant
        attachPreset = "joint" -- Used attachment preset
    },

    ["joint_purple_haze"] = {
        item = "joint_purple_haze", -- Inventory item name
        type = "joint", -- Internal type identifier
        label = "Joint", -- Display name shown in the UI
        image = "joint.png", -- Image file used in the UI
        prop = "p_cs_joint_01", -- Prop model spawned for this variant
        attachPreset = "joint" -- Used attachment preset
    },

    ["joint_amnesia_haze"] = {
        item = "joint_amnesia_haze", -- Inventory item name
        type = "joint", -- Internal type identifier
        label = "Joint", -- Display name shown in the UI
        image = "joint.png", -- Image file used in the UI
        prop = "p_cs_joint_01", -- Prop model spawned for this variant
        attachPreset = "joint" -- Used attachment preset
    },

    ["joint_white_widow"] = {
        item = "joint_white_widow", -- Inventory item name
        type = "joint", -- Internal type identifier
        label = "Joint", -- Display name shown in the UI
        image = "joint.png", -- Image file used in the UI
        prop = "p_cs_joint_01", -- Prop model spawned for this variant
        attachPreset = "joint" -- Used attachment preset
    },

	["vape_1_red"] = {
		item = "vape_1_red", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_1_red.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig", -- Prop model spawned for this variant
		attachPreset = "vape_pen_b", -- Used attachment preset
		tintValue = 1 -- Object tint or color variation value
	},

	["vape_1_blue"] = {
		item = "vape_1_blue", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_1_blue.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig", -- Prop model spawned for this variant
		attachPreset = "vape_pen_b", -- Used attachment preset
		tintValue = 0 -- Object tint or color variation value
	},

	["vape_1_pink"] = {
		item = "vape_1_pink", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_1_pink.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig", -- Prop model spawned for this variant
		attachPreset = "vape_pen_b", -- Used attachment preset
		tintValue = 2 -- Object tint or color variation value
	},

	["vape_1_turquoise"] = {
		item = "vape_1_turquoise", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_1_turquoise.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig", -- Prop model spawned for this variant
		attachPreset = "vape_pen_b", -- Used attachment preset
		tintValue = 3 -- Object tint or color variation value
	},

	["vape_1_yellow"] = {
		item = "vape_1_yellow", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_1_yellow.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig", -- Prop model spawned for this variant
		attachPreset = "vape_pen_b", -- Used attachment preset
		tintValue = 4 -- Object tint or color variation value
	},

	["vape_1_white"] = {
		item = "vape_1_white", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_1_white.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig", -- Prop model spawned for this variant
		attachPreset = "vape_pen_b", -- Used attachment preset
		tintValue = 5 -- Object tint or color variation value
	},

	["vape_2_red"] = {
		item = "vape_2_red", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_2_red.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig_2", -- Prop model spawned for this variant
		attachPreset = "vape_pen_a", -- Used attachment preset
		tintValue = 1 -- Object tint or color variation value
	},

	["vape_2_blue"] = {
		item = "vape_2_blue", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_2_blue.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig_2", -- Prop model spawned for this variant
		attachPreset = "vape_pen_a", -- Used attachment preset
		tintValue = 0 -- Object tint or color variation value
	},

	["vape_2_pink"] = {
		item = "vape_2_pink", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_2_pink.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig_2", -- Prop model spawned for this variant
		attachPreset = "vape_pen_a", -- Used attachment preset
		tintValue = 2 -- Object tint or color variation value
	},

	["vape_2_turquoise"] = {
		item = "vape_2_turquoise", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_2_turquoise.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig_2", -- Prop model spawned for this variant
		attachPreset = "vape_pen_a", -- Used attachment preset
		tintValue = 3 -- Object tint or color variation value
	},

	["vape_2_yellow"] = {
		item = "vape_2_yellow", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_2_yellow.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig_2", -- Prop model spawned for this variant
		attachPreset = "vape_pen_a", -- Used attachment preset
		tintValue = 4 -- Object tint or color variation value
	},

	["vape_2_white"] = {
		item = "vape_2_white", -- Inventory item name
		type = "vape", -- Internal type identifier
		label = "Vape", -- Display name shown in the UI
		image = "vape_2_white.png", -- Image file used in the UI
		prop = "rtx_sempre_smoking_e_cig_2", -- Prop model spawned for this variant
		attachPreset = "vape_pen_a", -- Used attachment preset
		tintValue = 5 -- Object tint or color variation value
	},

    ["bong"] = {
        item = "bong", -- Inventory item name
        type = "bong", -- Internal type identifier
        label = "Bong", -- Display name shown in the UI
        image = "bong.png", -- Image file used in the UI
        prop = "prop_sh_bong_01", -- Prop model spawned for this variant
        attachPreset = "bong_classic" -- Used attachment preset
    },
}

Config.Items = { -- Main behavior configuration for smoking items
    ["cigarette"] = {
        label = "Cigarette", -- Display name shown in the UI
        supportsLighting = true, -- Defines whether this item must be lit before use

        nui = { -- NUI display settings
            type = "cigarette", -- Internal type identifier
            emptyText = "Not selected" -- Text when no selection was made
        },

        requirements = { -- Usage requirement settings
            requireSelection = false -- Requires a selection of refill, flavor, or strain
        },

        stats = { -- Item stat definitions
            durability = { -- Durability configuration
                label = "Durability", -- Display name shown in the UI
                minRequiredToUse = 1.0 -- Minimum stat value required to use the item
            }
        },

        consumption = { -- Consumption settings while using the item
            puff = { -- Puff action settings
                duration = {
                    minHoldMs = 150, -- Minimum hold duration in milliseconds
                    maxHoldMs = 3500 -- Maximum hold duration in milliseconds
                },

                stats = { -- Item stat definitions
                    durability = { -- Durability configuration
                        perSecond = 7.0, -- Amount consumed per second while using the item
                        min = 0.5, -- Minimum consumption per use
                        max = 8.0 -- Maximum consumption per use
                    }
                }
            }
        },

        animations = { -- Animation settings for this item
            idle = { -- Idle animation or attachment settings
                enabled = false, -- Enables or disables this feature
                dict = "amb@world_human_smoking_fat@male@male_b@idle_a", -- Animation or particle dictionary name
                anim = "idle_a", -- Animation clip name
                flag = 49 -- Animation flag controlling playback behavior
            },

            light = { -- Animation or attachment settings for the lighting
                enabled = true, -- Enables or disables this feature
                dict = "ciglightning@rtx", -- Animation or particle dictionary name
                anim = "ciglightning_clip", -- Animation clip name
                flag = 49, -- Animation flag controlling playback behavior
                durationMs = 2500 -- Animation or effect duration in milliseconds
            },

            puffStyles = { -- Available puff animation styles
				[1] = {
					enabled = true, -- Enables or disables this feature
					dict = "cigsmoke_2@rtx", -- Animation or particle dictionary name
					anim = "cigsmoke_2_clip", -- Animation clip name
					flag = 49, -- Animation flag controlling playback behavior
				},

				[2] = {
					enabled = true, -- Enables or disables this feature
					dict = "cigsmoke@rtx", -- Animation or particle dictionary name
					anim = "cigsmoke_clip", -- Animation clip name
					flag = 49, -- Animation flag controlling playback behavior
				},
			},
            forceRelease = { -- Forced release or coughing animation settings
                enabled = true, -- Enables or disables this feature
                dict = "timetable@gardener@smoking_joint", -- Animation or particle dictionary name
                anim = "idle_cough", -- Animation clip name
                flag = 49, -- Animation flag controlling playback behavior
                durationMs = 1500 -- Animation or effect duration in milliseconds
            },
        },

        particles = { -- Particle effect settings
			
			idleMain = { -- Idle smoke particle settings
				enabled = true, -- Enables or disables this feature
				attachTo = "mainItem", -- Attachment target used for particle effects
				ptfxDict = "core", -- Particle effect dictionary name
				ptfxName = "ent_anim_cig_smoke", -- Particle effect name
				scale = 0.8, -- Particle or effect scale
				offset = vec3(-0.070, 0.0, 0.00), -- Position offset relative to the bone or prop
				rotation = vec3(0.0, 0.0, 90.0), -- Rotation offset relative to the bone or prop
			},
            lightSecondary = { -- Lighter flame particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "secondaryItem", -- Attachment target used for particle effects
                ptfxDict = "cut_family1", -- Particle effect dictionary name
                ptfxName = "cs_mich1_lighter_flame", -- Particle effect name
                scale = 0.8, -- Particle or effect scale
                offset = vec3(-0.005, 0.0, 0.054), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 80.0) -- Rotation offset relative to the bone or prop
            },

            exhale = { -- Exhale smoke particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "mouth", -- Attachment target used for particle effects
                ptfxDict = "core", -- Particle effect dictionary name
                ptfxName = "exp_grd_bzgas_smoke", -- Particle effect name
                scale = 0.22, -- Particle or effect scale
                mouthBone = 47495, -- Mouth bone index used for exhale particles
                offset = vec3(0.12, 0.0, 0.0), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 0.0), -- Rotation offset relative to the bone or prop
                minHoldMs = 200, -- Minimum hold duration in milliseconds
                maxHoldMs = 3000, -- Maximum hold duration in milliseconds
                minDurationMs = 250, -- Minimum particle duration in milliseconds
                maxDurationMs = 1000 -- Maximum particle duration in milliseconds
            }
        }
    },
    ["joint"] = {
        label = "Joint", -- Display name shown in UI
        supportsLighting = true, -- Defines whether this item must be lit before use

        nui = { -- NUI display settings
            type = "joint", -- Internal item type identifier
            emptyText = "Not selected" -- Text shown when no selection is selected
        },

        requirements = { -- Usage requirement settings
            requireSelection = false -- Requires player to select a refill, flavor, or strain
        },

        stats = { -- Item stat definitions
            durability = { -- Durability stat configuration
                label = "Durability", -- Display name shown in UI
                minRequiredToUse = 1.0 -- Minimum stat value required to use the item
            }
        },

        consumption = { -- Consumption settings while using the item
            puff = { -- Puff action settings
                duration = {
                    minHoldMs = 150, -- Minimum hold duration in milliseconds
                    maxHoldMs = 3500 -- Maximum hold duration in milliseconds
                },

                stats = { -- Item stat definitions
                    durability = { -- Durability stat configuration
                        perSecond = 7.0, -- Amount consumed per second while using the item
                        min = 0.5, -- Minimum amount consumed per use
                        max = 8.0 -- Maximum amount consumed per use
                    }
                }
            }
        },

        animations = { -- Animation settings for this item
            idle = { -- Idle animation or attachment settings
                enabled = false, -- Enables or disables this feature
                dict = "amb@world_human_smoking_fat@male@male_b@idle_a", -- Animation or particle dictionary name
                anim = "idle_a", -- Animation clip name
                flag = 49 -- Animation flag controlling playback behavior
            },

            light = { -- Lighting animation or attachment settings
                enabled = true, -- Enables or disables this feature
                dict = "ciglightning@rtx", -- Animation or particle dictionary name
                anim = "ciglightning_clip", -- Animation clip name
                flag = 49, -- Animation flag controlling playback behavior
                durationMs = 2500 -- Animation or effect duration in milliseconds
            },

            puffStyles = { -- Available puff animation styles
				[1] = {
					enabled = true, -- Enables or disables this feature
					dict = "cigsmoke_2@rtx", -- Animation or particle dictionary name
					anim = "cigsmoke_2_clip", -- Animation clip name
					flag = 49, -- Animation flag controlling playback behavior
				},

				[2] = {
					enabled = true, -- Enables or disables this feature
					dict = "cigsmoke@rtx", -- Animation or particle dictionary name
					anim = "cigsmoke_clip", -- Animation clip name
					flag = 49, -- Animation flag controlling playback behavior
				},
			},

            forceRelease = { -- Forced release or cough animation settings
                enabled = true, -- Enables or disables this feature
                dict = "timetable@gardener@smoking_joint", -- Animation or particle dictionary name
                anim = "idle_cough", -- Animation clip name
                flag = 49, -- Animation flag controlling playback behavior
                durationMs = 1500 -- Animation or effect duration in milliseconds
            }
        },

        particles = { -- Particle effect settings
            idleMain = { -- Idle smoke particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "mainItem", -- Attachment target used for particle effects
                ptfxDict = "core", -- Particle effect dictionary name
                ptfxName = "ent_anim_cig_smoke", -- Particle effect name
                scale = 0.15, -- Particle or effect scale
                offset = vec3(-0.09, 0.0, 0.00), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 90.0) -- Rotation offset relative to the bone or prop
            },

            lightSecondary = { -- Lighter flame particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "secondaryItem", -- Attachment target used for particle effects
                ptfxDict = "cut_family1", -- Particle effect dictionary name
                ptfxName = "cs_mich1_lighter_flame", -- Particle effect name
                scale = 0.8, -- Particle or effect scale
                offset = vec3(-0.005, 0.0, 0.054), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 80.0) -- Rotation offset relative to the bone or prop
            },

            exhale = { -- Exhale smoke particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "mouth", -- Attachment target used for particle effects
                ptfxDict = "core", -- Particle effect dictionary name
                ptfxName = "exp_grd_bzgas_smoke", -- Particle effect name
                scale = 0.22, -- Particle or effect scale
                mouthBone = 47495, -- Mouth bone index used for exhale particles
                offset = vec3(0.12, 0.0, 0.0), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 0.0), -- Rotation offset relative to the bone or prop
                minHoldMs = 200, -- Minimum hold duration in milliseconds
                maxHoldMs = 3000, -- Maximum hold duration in milliseconds
                minDurationMs = 250, -- Minimum particle duration in milliseconds
                maxDurationMs = 1000 -- Maximum particle duration in milliseconds
            }
        }
    },
    ["cigar"] = {
        label = "Cigar", -- Display name shown in UI
        supportsLighting = true, -- Defines whether this item must be lit before use

        nui = { -- NUI display settings
            type = "cigar", -- Internal item type identifier
            emptyText = "Not selected" -- Text shown when no selection is selected
        },

        requirements = { -- Usage requirement settings
            requireSelection = false -- Requires player to select a refill, flavor, or strain
        },

        stats = { -- Item stat definitions
            durability = { -- Durability stat configuration
                label = "Durability", -- Display name shown in UI
                minRequiredToUse = 1.0 -- Minimum stat value required to use the item
            }
        },

        consumption = { -- Consumption settings while using the item
            puff = { -- Puff action settings
                duration = {
                    minHoldMs = 150, -- Minimum hold duration in milliseconds
                    maxHoldMs = 3500 -- Maximum hold duration in milliseconds
                },

                stats = { -- Item stat definitions
                    durability = { -- Durability stat configuration
                        perSecond = 7.0, -- Amount consumed per second while using the item
                        min = 0.5, -- Minimum amount consumed per use
                        max = 8.0 -- Maximum amount consumed per use
                    }
                }
            }
        },

        animations = { -- Animation settings for this item
            idle = { -- Idle animation or attachment settings
                enabled = false, -- Enables or disables this feature
                dict = "amb@world_human_smoking_fat@male@male_b@idle_a", -- Animation or particle dictionary name
                anim = "idle_a", -- Animation clip name
                flag = 49 -- Animation flag controlling playback behavior
            },

            light = { -- Lighting animation or attachment settings
                enabled = true, -- Enables or disables this feature
                dict = "ciglightning@rtx", -- Animation or particle dictionary name
                anim = "ciglightning_clip", -- Animation clip name
                flag = 49, -- Animation flag controlling playback behavior
                durationMs = 2500 -- Animation or effect duration in milliseconds
            },

            puffStyles = { -- Available puff animation styles
				[1] = {
					enabled = true, -- Enables or disables this feature
					dict = "cigsmoke_2@rtx", -- Animation or particle dictionary name
					anim = "cigsmoke_2_clip", -- Animation clip name
					flag = 49, -- Animation flag controlling playback behavior
				},

				[2] = {
					enabled = true, -- Enables or disables this feature
					dict = "cigsmoke@rtx", -- Animation or particle dictionary name
					anim = "cigsmoke_clip", -- Animation clip name
					flag = 49, -- Animation flag controlling playback behavior
				},
			},

            forceRelease = { -- Forced release or cough animation settings
                enabled = true, -- Enables or disables this feature
                dict = "timetable@gardener@smoking_joint", -- Animation or particle dictionary name
                anim = "idle_cough", -- Animation clip name
                flag = 49, -- Animation flag controlling playback behavior
                durationMs = 1500 -- Animation or effect duration in milliseconds
            }
        },
        particles = { -- Particle effect settings
            idleMain = { -- Idle smoke particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "mainItem", -- Attachment target used for particle effects
                ptfxDict = "core", -- Particle effect dictionary name
                ptfxName = "ent_anim_cig_smoke", -- Particle effect name
                scale = 0.8, -- Particle or effect scale
                offset = vec3(0.115, 0.0, 0.00), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 90.0), -- Rotation offset relative to the bone or prop
            },

            lightSecondary = { -- Lighter flame particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "secondaryItem", -- Attachment target used for particle effects
                ptfxDict = "cut_family1", -- Particle effect dictionary name
                ptfxName = "cs_mich1_lighter_flame", -- Particle effect name
                scale = 0.8, -- Particle or effect scale
                offset = vec3(-0.005, 0.0, 0.054), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 80.0) -- Rotation offset relative to the bone or prop
            },

            exhale = { -- Exhale smoke particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "mouth", -- Attachment target used for particle effects
                ptfxDict = "core", -- Particle effect dictionary name
                ptfxName = "exp_grd_bzgas_smoke", -- Particle effect name
                scale = 0.22, -- Particle or effect scale
                mouthBone = 47495, -- Mouth bone index used for exhale particles
                offset = vec3(0.12, 0.0, 0.0), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 0.0), -- Rotation offset relative to the bone or prop
                minHoldMs = 200, -- Minimum hold duration in milliseconds
                maxHoldMs = 3000, -- Maximum hold duration in milliseconds
                minDurationMs = 250, -- Minimum particle duration in milliseconds
                maxDurationMs = 1000 -- Maximum particle duration in milliseconds
            }
        }
    },	
    ["vape"] = {
        label = "Vape", -- Display name shown in UI
        supportsLighting = false, -- Defines whether this item must be lit before use

        nui = { -- NUI display settings
            type = "vape", -- Internal item type identifier
            emptyText = "Not selected" -- Text shown when no selection is selected
        },

        requirements = { -- Usage requirement settings
            requireSelection = true -- Requires player to select a refill, flavor, or strain
        },

        stats = { -- Item stat definitions
            fill = { -- Fill status configuration
                label = "Flavor status", -- Display name shown in UI
                minRequiredToUse = 1.0 -- Minimum stat value required to use the item
            },

            battery = { -- Battery status configuration
                label = "Battery", -- Display name shown in UI
                minRequiredToUse = 1.0 -- Minimum stat value required to use the item
            }
        },

        consumption = { -- Consumption settings while using the item
            puff = { -- Puff action settings
                duration = {
                    minHoldMs = 150, -- Minimum hold duration in milliseconds
                    maxHoldMs = 5000 -- Maximum hold duration in milliseconds
                },

                stats = { -- Item stat definitions
                    fill = { -- Fill status configuration
                        perSecond = 5.0, -- Amount consumed per second while using the item
                        min = 0.25, -- Minimum amount consumed per use
                        max = 4.0 -- Maximum amount consumed per use
                    },

                    battery = { -- Battery status configuration
                        perSecond = 1.5, -- Amount consumed per second while using the item
                        min = 0.1, -- Minimum amount consumed per use
                        max = 1.5 -- Maximum amount consumed per use
                    }
                }
            }
        },

        animations = { -- Animation settings for this item
            idle = { -- Idle animation or attachment settings
                enabled = false, -- Enables or disables this feature
                dict = "", -- Animation or particle dictionary name
                anim = "", -- Animation clip name
                flag = 49 -- Animation flag controlling playback behavior
            },

            light = { -- Lighting animation or attachment settings
                enabled = false, -- Enables or disables this feature
                dict = "", -- Animation or particle dictionary name
                anim = "", -- Animation clip name
                flag = 49, -- Animation flag controlling playback behavior
                durationMs = 0 -- Animation or effect duration in milliseconds
            },

            puff = { -- Puff action settings
                enabled = true, -- Enables or disables this feature
                dict = "shishaanimsmoke@rtx", -- Animation or particle dictionary name
                anim = "shishaanimsmoke", -- Animation clip name
                flag = 49 -- Animation flag controlling playback behavior
            },

            forceRelease = { -- Forced release or cough animation settings
                enabled = true, -- Enables or disables this feature
                dict = "timetable@gardener@smoking_joint", -- Animation or particle dictionary name
                anim = "idle_cough", -- Animation clip name
                flag = 49, -- Animation flag controlling playback behavior
                durationMs = 1500 -- Animation or effect duration in milliseconds
            }
        },

        particles = { -- Particle effect settings
            exhale = { -- Exhale smoke particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "mouth", -- Attachment target used for particle effects
                ptfxDict = "core", -- Particle effect dictionary name
                ptfxName = "exp_grd_bzgas_smoke", -- Particle effect name
                scale = 0.55, -- Particle or effect scale
                mouthBone = 47495, -- Mouth bone index used for exhale particles
                offset = vec3(0.15, 0.0, 0.0), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 0.0), -- Rotation offset relative to the bone or prop
                minHoldMs = 300, -- Minimum hold duration in milliseconds
                maxHoldMs = 5000, -- Maximum hold duration in milliseconds
                minDurationMs = 500, -- Minimum particle duration in milliseconds
                maxDurationMs = 3000 -- Maximum particle duration in milliseconds
            }
        }
    },

    ["bong"] = {
        label = "Bong", -- Display name shown in UI
        supportsLighting = false, -- Defines whether this item must be lit before use

        nui = { -- NUI display settings
            type = "bong", -- Internal item type identifier
            emptyText = "Not selected" -- Text shown when no selection is selected
        },

        requirements = { -- Usage requirement settings
            requireSelection = true -- Requires player to select a refill, flavor, or strain
        },

        stats = { -- Item stat definitions
            fill = { -- Fill status configuration
                label = "Fill level", -- Display name shown in UI
                minRequiredToUse = 1.0 -- Minimum stat value required to use the item
            },

            water = { -- Water status configuration
                label = "Water", -- Display name shown in UI
                minRequiredToUse = 1.0 -- Minimum stat value required to use the item
            }
        },

        consumption = { -- Consumption settings while using the item
            puff = { -- Puff action settings
                duration = {
                    minHoldMs = 200, -- Minimum hold duration in milliseconds
                    maxHoldMs = 5000 -- Maximum hold duration in milliseconds
                },

                stats = { -- Item stat definitions
                    fill = { -- Fill status configuration
                        perSecond = 4.0, -- Amount consumed per second while using the item
                        min = 0.25, -- Minimum amount consumed per use
                        max = 3.0 -- Maximum amount consumed per use
                    },

                    water = { -- Water status configuration
                        perSecond = 0.8, -- Amount consumed per second while using the item
                        min = 0.05, -- Minimum amount consumed per use
                        max = 0.8 -- Maximum amount consumed per use
                    }
                }
            }
        },

        animations = { -- Animation settings for this item
            idle = { -- Idle animation or attachment settings
                enabled = false, -- Enables or disables this feature
                dict = "", -- Animation or particle dictionary name
                anim = "", -- Animation clip name
                flag = 49 -- Animation flag controlling playback behavior
            },

            light = { -- Lighting animation or attachment settings
                enabled = false, -- Enables or disables this feature
                dict = "", -- Animation or particle dictionary name
                anim = "", -- Animation clip name
                flag = 49, -- Animation flag controlling playback behavior
                durationMs = 0 -- Animation or effect duration in milliseconds
            },

            puff = { -- Puff action settings
                enabled = true, -- Enables or disables this feature
                dict = "bongosmoke@rtx", -- Animation or particle dictionary name
                anim = "bongosmoke", -- Animation clip name
                flag = 49 -- Animation flag controlling playback behavior
            },

            forceRelease = { -- Forced release or cough animation settings
                enabled = true, -- Enables or disables this feature
                dict = "timetable@gardener@smoking_joint", -- Animation or particle dictionary name
                anim = "idle_cough", -- Animation clip name
                flag = 49, -- Animation flag controlling playback behavior
                durationMs = 1500 -- Animation or effect duration in milliseconds
            }
        },

        particles = { -- Particle effect settings
            puffSecondary = { -- Puff flame particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "secondaryItem", -- Attachment target used for particle effects
                ptfxDict = "cut_family1", -- Particle effect dictionary name
                ptfxName = "cs_mich1_lighter_flame", -- Particle effect name
                scale = 0.8, -- Particle or effect scale
                offset = vec3(-0.005, 0.0, 0.054), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 80.0) -- Rotation offset relative to the bone or prop
            },

            exhale = { -- Exhale smoke particle settings
                enabled = true, -- Enables or disables this feature
                attachTo = "mouth", -- Attachment target used for particle effects
                ptfxDict = "core", -- Particle effect dictionary name
                ptfxName = "exp_grd_bzgas_smoke", -- Particle effect name
                scale = 0.45, -- Particle or effect scale
                mouthBone = 47495, -- Mouth bone index used for exhale particles
                offset = vec3(0.15, 0.0, 0.0), -- Position offset relative to the bone or prop
                rotation = vec3(0.0, 0.0, 0.0), -- Rotation offset relative to the bone or prop
                minHoldMs = 300, -- Minimum hold duration in milliseconds
                maxHoldMs = 5000, -- Maximum hold duration in milliseconds
                minDurationMs = 500, -- Minimum particle duration in milliseconds
                maxDurationMs = 3000 -- Maximum particle duration in milliseconds
            }
        }
    }
}

Config.HookahForceRelease = {
    enabled = true, -- Enable forced release / cough for hookah
    maxHoldMs = 3500, -- Maximum inhale hold time before cough starts
    dict = "timetable@gardener@smoking_joint", -- Cough animation dictionary
    anim = "idle_cough", -- Cough animation name
    flag = 49, -- Animation flag
    durationMs = 1500, -- Cough animation duration
    coughSound = true -- Play cough sound when forced release happens
}

Config.SmokeEffects = { -- Optional screen and movement effects triggered by smoking
    enabled = true, -- Enables or disables this feature

    triggerStage = "puff_end", -- puff_end / puff_start

    categories = { -- Effect trigger settings by item category
        ["joint"] = {
            enabled = true, -- Enables or disables this feature
            chance = 8, -- %
            effects = { "weed_relaxed", "weed_heavy" } -- Effects that can be randomly applied
        },

        ["bong"] = {
            enabled = true, -- Enables or disables this feature
            chance = 80, -- Percentage chance to trigger this effect
            effects = { "weed_relaxed", "weed_heavy", "weed_wobbly" } -- Effects that can be randomly applied
        },

        ["cigarette"] = {
            enabled = true, -- Enables or disables this feature
            chance = 0, -- Percentage chance to trigger this effect
            effects = {} -- No special effects are configured for this category
        },

        ["cigar"] = {
            enabled = true, -- Enables or disables this feature
            chance = 0, -- Percentage chance to trigger this effect
            effects = {} -- No special effects are configured for this category
        },

        ["vape"] = {
            enabled = true, -- Enables or disables this feature
            chance = 0, -- Percentage chance to trigger this effect
            effects = {} -- No special effects are configured for this category
        },
    },

    effects = { -- Effect definitions
        ["weed_relaxed"] = {
            label = "Entspannter Rausch", -- Display name shown in UI
            durationMs = 30000, -- Animation or effect duration in milliseconds
            screenEffect = "ChopVision", -- GTA screen effect name
            timecycle = "spectator5", -- GTA timecycle modifier name
            movementClipset = "MOVE_M@DRUNK@VERYDRUNK", -- Movement clipset applied during the effect
            shake = 1.5, -- Camera shake intensity
            isDrunk = true, -- Applies drunk movement behavior when enabled
            motionBlur = false -- Enables motion blur during the effect
        },

        ["weed_heavy"] = {
            label = "Starker Rausch", -- Display name shown in UI
            durationMs = 30000, -- Animation or effect duration in milliseconds
            screenEffect = "DrugsMichaelAliensFight", -- GTA screen effect name
            timecycle = "spectator5", -- GTA timecycle modifier name
            movementClipset = "MOVE_M@DRUNK@VERYDRUNK", -- Movement clipset applied during the effect
            shake = 3.0, -- Camera shake intensity
            isDrunk = true, -- Applies drunk movement behavior when enabled
            motionBlur = false -- Enables motion blur during the effect
        },

        ["weed_wobbly"] = {
            label = "Wackeliger Rausch", -- Display name shown in UI
            durationMs = 30000, -- Animation or effect duration in milliseconds
            screenEffect = "HeistCelebPass", -- GTA screen effect name
            timecycle = "drug_wobbly", -- GTA timecycle modifier name
            movementClipset = "move_m@hobo@a", -- Movement clipset applied during the effect
            shake = 3.0, -- Camera shake intensity
            isDrunk = true, -- Applies drunk movement behavior when enabled
            motionBlur = false -- Enables motion blur during the effect
        }
    }
}

Config.ESXFramework = { -- ESX framework compatibility settings
	newversion = true, -- Set to true if you're using the newer ESX versions (prevents old SharedObject errors)
	getsharedobject = "esx:getSharedObject", -- Event name used to fetch ESX shared object (old ESX compatibility)
	resourcename = "es_extended" -- Name of your ESX resource folder
}

Config.QBCoreFrameworkResourceName = "qbx-core" -- QBCore resource name (change if your core resource has a different folder name)

function Notify(notifytype, title, text)
    SendNUIMessage({
        message = 'NotifyShow',
        type = notifytype,
        title = title,
        text = text,
        timeout = 5000,
    })
end