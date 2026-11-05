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
    ['audit_query'] = { capacity = 3.0, fillRatePerSec = 0.5 },
}

-- Return config
return Config

