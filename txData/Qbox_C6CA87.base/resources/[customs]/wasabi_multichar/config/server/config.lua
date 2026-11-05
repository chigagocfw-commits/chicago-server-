-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Framework detection: 'auto', 'esx', 'qb', 'qbx', 'custom'
-- Note: the active framework is auto-detected via resource state checks in the bridge files.
-- This value is informational only; it does not control which bridge loads.
Config.ServerRevision = "c75e2cbced08e99c33646c483421cebc"
Config.Framework = 'auto'

Config.CheckForUpdates = true -- Check for updates on resource start (recommended)

-- Logout command (return to multichar)
Config.LogoutCommand = {
    name = 'logout',
    description = 'Logout from the character',
    onlyStaff = false, -- If true, only ACE wasabi_multichar.staff can use
}

-- Add VIP slot command (ACE: wasabi_multichar.addvip)
Config.AddVIPCommand = {
    name = 'addvip',
    description = 'Add VIP slot to player (license or player id)',
}

-- If true, only ACE "wasabi_multichar.delete" can delete characters
Config.DeleteCharacterRestricted = false

-- Tebex package ID for slot purchases (0 = disabled)
Config.TebexPackageID = 0

-- Starter items granted on new character creation
Config.StarterItems = {
    enabled = false,
    items = {
        { type = 'account', name = 'money', amount = 5000 },
        { type = 'item', name = 'burger', amount = 5 },
        { type = 'item', name = 'water', amount = 5 },
    },
}

---@ignore
Modules.register('config', Config, true)
