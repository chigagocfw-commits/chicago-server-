-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------

-- Welcome screen: camera in the skyline shown before character selection. Player must press Enter to continue.
-- If nil, uses the first PreviewLocations startCam. Set to vector3(x,y,z) to override (e.g. skyline view).
Config.ClientRevision = "c75e2cbced08e99c33646c483421cebc"
Config.WelcomeCam = vector3(-1720.7660, -1180.8932, 27.7457)

-- When true (default): focus the first character as soon as multichar opens, if any exist.
-- When false: keep the cinematic idle for FirstOpenIntroDelay ms, then focus the first character.
-- If the player has no characters, the cinematic idle always continues (no slot focus).
Config.AutoFocusFirstCharacter = true

-- Only used when AutoFocusFirstCharacter is false and the player has at least one character (ms).
Config.FirstOpenIntroDelay = 4000

-- Examples: '#29b181' (default green), '#3b82f6' (blue), '#a855f7' (purple). Set to nil for default green.
Config.UIColor = '#29b181'

-- Nationalities available for character creation. Add or edit entries to match your server.
Config.Nationalities = {
    'American',
    'British',
    'Canadian',
    'Mexican',
    'German',
    'French',
    'Italian',
    'Spanish',
    'Japanese',
    'Chinese',
    'Korean',
    'Brazilian',
    'Australian',
    'Russian',
    'Indian',
    'Other'
}

-- Stat fields to display on character selection
-- key: The database column/data key to fetch
-- label: Display label in UI
-- icon: FontAwesome icon class
-- format: 'currency', 'phone', 'date', 'text'
Config.StatFields = {
    { key = 'birthdate', label = 'BIRTHDAY', icon = 'fa-solid fa-cake-candles', format = 'date' },
    { key = 'jobLabel', label = 'JOB', icon = 'fa-solid fa-briefcase', format = 'text' },
    { key = 'cash', label = 'CASH', icon = 'fa-solid fa-dollar-sign', format = 'currency' },
    { key = 'bank', label = 'BANK', icon = 'fa-solid fa-building-columns', format = 'currency' },
    { key = 'phone', label = 'PHONE NUMBER', icon = 'fa-solid fa-phone', format = 'phone' },
}

-- Webstore link for purchasing additional character slots (leave empty to disable)
Config.WebstoreLink = ''
Config.PurchaseUrl = '' -- Alias for WebstoreLink, used by NUI

---@ignore
Modules.register('config', Config, true)
