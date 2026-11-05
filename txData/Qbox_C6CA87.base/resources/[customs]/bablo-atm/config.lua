
Config = {}
Config.DEBUG = false      -- Options: true, false

Config.Framework = "auto" -- Options: "esx", "qbcore", "qbox"
Config.BankingResource = "bablo-banking"

-- Currency formatting for UI
Config.Currency = 'USD'     -- ISO currency code used by Intl formatter
Config.CurrencySymbol = '$' -- Optional prefix symbol; if set, UI will prefix and use decimal formatting

Config.ATMModels = {
    -1126237515,
    506770882,
    -870868698,
    150237004,
    -239124254,
    -1364697528,
}

-- Radius in meters where ATM screen will be replaced with our DUI UI
Config.ATMReplaceRadius = 15.0

-- Distance in meters to allow card use / ATM interaction
Config.ATMInteractionRange = 2.0

-- Toggle automatic replacement near ATMs
Config.EnableATMTextureReplace = true

-- Enable animations when using credit card at ATM
Config.EnableATMAnimations = true

-- Animation settings
Config.AnimationSettings = {
    WalkDistance = 0.6,
    ScenarioTimeout = 3000,
    DelayBeforePinEntry = 3000,
    ShowCreditCard = true,
}

Config.DisableControls = {
    30, -- Move Left/Right
    31, -- Move Up/Down
    32, -- Move Forward/Backward
    33, -- Move Left/Right (Alternative)
    34, -- Move Forward/Backward (Alternative)
    35, -- Move Up/Down (Alternative)
}

-- Define shared animation presets to avoid duplication
local ANIM_DICT_STANDARD = "mp_common_heist"
local ANIM_NAME_STANDARD = "use_atm"

-- Helper function to create animation config for all ATM models
local function createAnimConfig(dict, anim)
    return {
        Default = dict or ANIM_DICT_STANDARD,
        [-1126237515] = dict or ANIM_DICT_STANDARD, -- prop_fleeca_atm
        [506770882] = dict or ANIM_DICT_STANDARD,   -- prop_atm_01
        [-870868698] = dict or ANIM_DICT_STANDARD,  -- prop_atm_02
        [150237004] = dict or ANIM_DICT_STANDARD,   -- prop_atm_03
        [-239124254] = dict or ANIM_DICT_STANDARD,
        [-1364697528] = dict or ANIM_DICT_STANDARD,
    }
end

Config.AnimSettings = {
    InsertCard = {
        Object = true,
        IsLocal = true,
        Male = {
            Insert = {
                Dict = createAnimConfig(ANIM_DICT_STANDARD),
                Anim = createAnimConfig(ANIM_NAME_STANDARD)
            },
            Remove = {
                Dict = createAnimConfig(ANIM_DICT_STANDARD),
                Anim = createAnimConfig(ANIM_NAME_STANDARD)
            }
        },
        Female = {
            Insert = {
                Dict = createAnimConfig(ANIM_DICT_STANDARD),
                Anim = createAnimConfig(ANIM_NAME_STANDARD)
            },
            Remove = {
                Dict = createAnimConfig(ANIM_DICT_STANDARD),
                Anim = createAnimConfig(ANIM_NAME_STANDARD)
            }
        }
    }
}

Config.Objects = {
    Card = "prop_cs_credit_card"
}

-- Define shared offset presets to avoid duplication
local CARD_OFFSET_PRESETS = {
    Standard = {
        First = vector3(0.0, 0.15, 0.85),
        Second = vector3(0.0, 0.05, 0.85)
    },
    Lower = {
        First = vector3(0.0, 0.15, 0.75),
        Second = vector3(0.0, 0.05, 0.75)
    },
    Mid = {
        First = vector3(0.0, 0.15, 0.80),
        Second = vector3(0.0, 0.05, 0.80)
    }
}

Config.Offsets = {
    CardPos = {
        Default = CARD_OFFSET_PRESETS.Standard,
        [-1126237515] = CARD_OFFSET_PRESETS.Standard, -- prop_fleeca_atm
        [506770882] = CARD_OFFSET_PRESETS.Lower,      -- prop_atm_01
        [-870868698] = CARD_OFFSET_PRESETS.Mid,       -- prop_atm_02
        [150237004] = CARD_OFFSET_PRESETS.Standard,   -- prop_atm_03
        [-239124254] = CARD_OFFSET_PRESETS.Standard,
        [-1364697528] = CARD_OFFSET_PRESETS.Standard,
    }
}

Config.EnableATMCamera = true

Config.EnableKeypad = true

-- Define shared camera presets to avoid duplication
local CAM_OFFSET_PRESETS = {
    Standard = vector3(-0.09994507, -0.4500122, 1.379971),
    SlightRight = vector3(-0.07, -0.4500122, 1.379971),
    Lower = vector3(-0.09994507, -0.4500122, 1.129971),
}

local CAM_ROT_STANDARD = vector3(-0.1, 3.739997, -0.7399989)

Config.CameraSettings = {
    FOV = 70.0,
    TransitionTime = 1000,
    HidePlayerPed = false,

    CamOffsets = {
        Default = CAM_OFFSET_PRESETS.Standard,
        [-1126237515] = CAM_OFFSET_PRESETS.Standard,  -- prop_fleeca_atm
        [506770882] = CAM_OFFSET_PRESETS.SlightRight, -- prop_atm_01
        [-870868698] = CAM_OFFSET_PRESETS.Lower,      -- prop_atm_02
        [150237004] = CAM_OFFSET_PRESETS.Standard,    -- prop_atm_03
    },

    CamRots = {
        Default = CAM_ROT_STANDARD,
        [-1126237515] = CAM_ROT_STANDARD, -- prop_fleeca_atm
        [506770882] = CAM_ROT_STANDARD,   -- prop_atm_01
        [-870868698] = CAM_ROT_STANDARD,  -- prop_atm_02
        [150237004] = CAM_ROT_STANDARD,   -- prop_atm_03
    },
}
