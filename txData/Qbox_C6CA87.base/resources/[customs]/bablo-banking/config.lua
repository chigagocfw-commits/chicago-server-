Config = {}

Config.DEBUG = false
Config.Logs = false

--[[
    Framework - The framework that the script will use. See what frameworks are available in the 'frameworks' folder.
    auto: This will automatically detect the framework.
]]
Config.Framework = 'qbox'

--[[
    qb-inventory, ox_inventory, qs-inventory, ps-inventory, core_inventory, codem-inventory, origen_inventory, tgiann-inventory
]]
Config.Inventory = 'ox_inventory'

--[[
    Target - The target that the script will use. See what targets are available in the 'interactions' folder.

    auto: This will automatically detect the target.
]]
Config.Target = 'ox_target'

--[[
    Interaction - The interaction that the script will use. See what interactions are available in the 'interactions' folder.
    auto: This will automatically detect the interaction.
]]
Config.Interaction = 'ox_lib'

--[[
    BankingInteraction - How players interact with the bank
    "ped": Spawns a banker ped at each location, use target to interact (current behavior)
    "zone": Creates a zone at each location, press E to open bank when inside the zone (no ped)
]]
Config.BankingInteraction = 'ped'

--[[
    ZoneRadius - The radius of the zone when using "zone" interaction type
    Only used when Config.BankingInteraction = 'zone'
]]
Config.ZoneRadius = 3.0

--[[
    Societies
    - Flexible and backward-compatible. If external is present (e.g., esx_society), we mirror balances and permissions.
    - If not, falls back to inbuilt.
    Jobs entries:
      AccountNumber: Unique account identifier for the society (must be unique in DB)
      Label: Human-readable label
      Access: Who can access; supports grade names (e.g., "boss"), or minimum numeric grade (e.g., 3)
]]
Config.Societies = {
    Enabled = true,
    Jobs = {
        ['police'] = {
            AccountNumber = "BPOLICE",
            Label = "Police Department",
            Access = { "boss", }
        },
        -- ['ambulance'] = { AccountNumber = "BEMS", Label = "Medical Services", Access = { "boss", 3 } },
        ['mechanic'] = { AccountNumber = "BMECH", Label = "Mechanic", Access = { 2 } },
    }
}

--[[
    Locale - The locale file that the script will use. See what locales are available in the 'locales' folder.
    See the documentation for more information on how to add own translation.
]]
Config.Locale = 'en-US'

--[[
    Currency pattern used by the web UI. Use '_' as number placeholder.
    Examples:
    "_$"  => 1000$
    "$_"  => $1000
    "_ $" => 1000 $
    "€_"  => €1000
]]
Config.Currency = '_$'

Config.AccountNumberPrefix = 'BXXXXXXXXX' --  X is a random character Any other character will be a prefix
Config.CreditCardItemName = 'bcreditcard' -- Inventory item name to give when creating a card

--[[
    OnlyOwnerCanUseCard - Prevents stolen cards from being used
    If true, only the player who created the card can use it (checked by identifier)
    If false, anyone holding the card item can use it
]]
Config.OnlyOwnerCanUseCard = false

--[[
    How many months to keep transaction history in the database.
    Old transactions older than this will be periodically purged.
    Minimum enforced is 1 month. Default: 1
]]
Config.TransactionRetentionMonths = 1

Config.BankerModels = { 'cs_bankman', 'u_m_m_bankman' };
Config.Bankers = {
    vector4(246.6369171142578, 223.6190948486328, 106.28675079345705, 160.35716247558597),
    vector4(314.3701477050781, -279.2083129882813, 54.17079162597656, 337.72509765625),
    vector4(149.5858917236328, -1040.674072265625, 29.37408638000488, 346.3494567871094),
    vector4(-112.6785888671875, 6469.8955078125, 31.6267147064209, 150.00439453125),
    vector4(-2962.50390625, 482.86056518555, 15.703105926514, 85.736671447754),
    vector4(-351.26281738281, -49.8844871521, 49.042568206787, 340.47848510742),
    vector4(-1212.7178955078, -330.80752563477, 37.787010192871, 31.451089859009),
    vector4(1175.3859863281, 2706.8723144531, 38.094032287598, 175.59910583496),
}

--[[
    Blip configuration for bank locations.
    - Enabled: set to false to hide blips
    - Sprite, Display, Scale, Colour: standard GTA blip settings
    - ShortRange: false to make blips visible at long range
    - Name: explicit name string. If nil and NameKey is set, uses translation key
    - NameKey: key in Locales to translate (e.g., 'BANK_BLIP_NAME')
]]
Config.Blip = {
    Enabled = true,
    Sprite = 108,
    Display = 4,
    Scale = 0.9,
    Colour = 3,
    ShortRange = true,
    NameKey = 'BANK_BLIP_NAME',
}