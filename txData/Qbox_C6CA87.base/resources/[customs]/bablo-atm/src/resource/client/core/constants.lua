Constants = Constants or {}

Constants.Models = Constants.Models or {
    fleeca = GetHashKey("prop_fleeca_atm"),
    one = GetHashKey("prop_atm_01"),
    two = GetHashKey("prop_atm_02"),
    three = GetHashKey("prop_atm_03"),
}

Constants.ATMModels = (Config and Config.ATMModels) or {
    Constants.Models.fleeca,
    506770882,
    -870868698,
    150237004,
    -239124254,
    -1364697528,
}

Constants.DUI = {
    RUNTIME_TXD_NAME = "bablo_atm_dui",
    RUNTIME_TX_NAME = "atm_screen",
    LOAD_TEXTURE_DISTANCE = 10.0,
}

Constants.Distances = {
    ATM_REPLACE_RADIUS = (Config and Config.ATMReplaceRadius) or 6.0,
    INTERACTION_RANGE = (Config and Config.ATMInteractionRange) or 2.0,
}
