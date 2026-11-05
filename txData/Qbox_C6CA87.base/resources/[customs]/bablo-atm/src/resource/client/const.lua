MODELS = {
    fleeca = "prop_fleeca_atm",
    one = "prop_atm_01",
    two = "prop_atm_02",
    three = "prop_atm_03",
}

VARIANTS = {
    [MODELS.fleeca] = {
        uiType = "fleeca",
        txd = "prop_fleeca_atm",
        tx = "prop_fleeca_atm",
        res = { x = 1024, y = 1024 },
    },
    [MODELS.one] = {
        uiType = "one",
        txd = "prop_atm_01",
        tx = "prop_cashpoint_screen",
        res = { x = 512, y = 512 },
    },
    [MODELS.two] = {
        uiType = "two",
        txd = "prop_atm_02",
        tx = "prop_cashpoint_screen",
        res = { x = 512, y = 512 },
    },
    [MODELS.three] = {
        uiType = "three",
        txd = "prop_atm_03",
        tx = "prop_cashpoint_screen",
        res = { x = 512, y = 512 },
    },
}
