Config = Config or {}

-- Core panel metadata
Config.PanelName = "SOUH4IL-DEV"
Config.Community = "CHICAGO ROLEPLAY"
Config.Version = "1.0.0"

-- General execution settings
Config.Debug = false
Config.Locale = "en"

-- Rate limiting thresholds (capacity = max burst tokens, fillRatePerSec = continuous tokens regenerated per sec)
Config.RateLimits = {
    ['ping'] = { capacity = 10.0, fillRatePerSec = 2.0 },
    ['security_check'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['audit_query'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['quick_action'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['weather_control'] = { capacity = 3.0, fillRatePerSec = 0.5 },
    ['get_players'] = { capacity = 10.0, fillRatePerSec = 2.0 },
    ['player_action'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['ban_player'] = { capacity = 3.0, fillRatePerSec = 0.5 },
    ['kick_player'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['give_item'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['give_money'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['vehicle_action'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['set_job'] = { capacity = 3.0, fillRatePerSec = 0.5 },
    ['clear_inventory'] = { capacity = 2.0, fillRatePerSec = 0.2 },
    ['broadcast'] = { capacity = 2.0, fillRatePerSec = 0.1 },
    ['set_time'] = { capacity = 3.0, fillRatePerSec = 0.5 },
    ['set_plate'] = { capacity = 3.0, fillRatePerSec = 0.5 },
    ['get_catalog'] = { capacity = 10.0, fillRatePerSec = 2.0 },
    ['set_traffic'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['arsenal'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['staff_action'] = { capacity = 5.0, fillRatePerSec = 1.0 },
    ['get_staff'] = { capacity = 10.0, fillRatePerSec = 2.0 },
    ['event_action'] = { capacity = 5.0, fillRatePerSec = 1.0 },
}

-- Return config
return Config

