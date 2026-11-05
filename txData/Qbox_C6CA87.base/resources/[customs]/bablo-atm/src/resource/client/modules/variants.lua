IKeypadVariant = {}

function IKeypadVariant.new()
    return setmetatable({
        keypadOffset = vector3(0.0, 0.0, 0.0),
        buttons = {},
    }, { __index = IKeypadVariant })
end

local KeypadButton = {}
KeypadButton.__index = KeypadButton

function KeypadButton.new(offset)
    return setmetatable({
        offset = offset,
    }, KeypadButton)
end

local ATMVariant = {}
ATMVariant.__index = ATMVariant

function ATMVariant.new(model, interactionSpotOffset, buttons, hardwareTexture, softwareTexture, uiType, res)
    return setmetatable({
        model = model,
        interactionSpotOffset = interactionSpotOffset,
        buttons = buttons,
        hardwareTexture = hardwareTexture,
        softwareTexture = softwareTexture,
        uiType = uiType,
        res = res,
    }, ATMVariant)
end

local function texture(dictionary, name, width, height)
    return { dictionary, name, { width, height } }
end

local fleecaButtons = {
    l1 = KeypadButton.new(vector3(-0.306, 0.1, 1.23)),
    l2 = KeypadButton.new(vector3(-0.306, 0.095, 1.17)),
    l3 = KeypadButton.new(vector3(-0.306, 0.09, 1.11)),
    l4 = KeypadButton.new(vector3(-0.306, 0.08, 1.06)),
    r1 = KeypadButton.new(vector3(0.065, 0.1, 1.23)),
    r2 = KeypadButton.new(vector3(0.065, 0.095, 1.17)),
    r3 = KeypadButton.new(vector3(0.064, 0.085, 1.11)),
    r4 = KeypadButton.new(vector3(0.063, 0.07, 1.055)),
    n1 = KeypadButton.new(vector3(-0.173, 0.0, 0.88)),
    n2 = KeypadButton.new(vector3(-0.145, 0.0, 0.88)),
    n3 = KeypadButton.new(vector3(-0.122, 0.0, 0.88)),
    n4 = KeypadButton.new(vector3(-0.173, -0.04, 0.87)),
    n5 = KeypadButton.new(vector3(-0.145, -0.04, 0.87)),
    n6 = KeypadButton.new(vector3(-0.122, -0.04, 0.87)),
    n7 = KeypadButton.new(vector3(-0.173, -0.075, 0.865)),
    n8 = KeypadButton.new(vector3(-0.145, -0.075, 0.865)),
    n9 = KeypadButton.new(vector3(-0.122, -0.075, 0.865)),
    n0 = KeypadButton.new(vector3(-0.145, -0.12, 0.865)),
    del = KeypadButton.new(vector3(-0.182, -0.12, 0.865)),
    enter = KeypadButton.new(vector3(-0.108, -0.12, 0.865)),
}

local variants = {
    fleeca = ATMVariant.new(
        506770882,
        -1.0,
        fleecaButtons,
        texture("prop_fleeca_atm", "prop_fleece_atm", 512, 512),
        texture("prop_fleeca_atm", "prop_fleece_emis", 1024, 1024),
        "fleeca",
        { x = 1024, y = 1024 }
    ),
    one = ATMVariant.new(
        -870868698,
        -1.0,
        {},
        texture("prop_atm_01", "prop_atm_01", 512, 512),
        texture("prop_atm_01", "prop_cashpoint_screen", 512, 512),
        "one",
        { x = 512, y = 512 }
    ),
    two = ATMVariant.new(
        -1126237515,
        -1.0,
        {},
        texture("prop_atm_02", "prop_atm_02", 512, 512),
        texture("prop_atm_02", "prop_cashpoint_screen", 512, 512),
        "two",
        { x = 512, y = 512 }
    ),
    three = ATMVariant.new(
        -1364697528,
        -1.0,
        {},
        texture("prop_atm_03", "prop_atm_03", 512, 512),
        texture("prop_atm_03", "prop_cashpoint_screen", 512, 512),
        "three",
        { x = 512, y = 512 }
    ),
}

Variants = {}

function Variants.new()
    return setmetatable({
        keypad = IKeypadVariant.new(),
        hardwareTexture = {},
        softwareTexture = {},
    }, { __index = Variants })
end

function GetATMVariant(variantId)
    return variants[variantId]
end

function GetAllATMVariants()
    return variants
end
