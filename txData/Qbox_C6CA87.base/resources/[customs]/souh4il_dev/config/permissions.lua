local PermissionsConfig = {}

-- Canonical Owner Rockstar License
-- Primary anchor for the Dual-Key Mandatory Gate.
PermissionsConfig.CanonicalOwnerLicense = "license:385f488fdcdc30a24c28b7a333ba9cbbffed5044"

-- Auxiliary identifiers registered for SOUH4IL (defense-in-depth correlation)
PermissionsConfig.AuxiliaryIdentifiers = {
    ['discord'] = "discord:792387618708914227",
    ['fivem'] = "fivem:20069674",
}

-- Defined SOUH4IL-DEV ACE namespaces
PermissionsConfig.ACES = {
    OWNER = "souh4il_dev.owner",
    DEVELOPER = "souh4il_dev.developer",
    ADMIN = "souh4il_dev.admin",
    MODERATOR = "souh4il_dev.mod",
    ACCESS = "souh4il_dev.access",
}

-- Staging test harness configuration (Must remain false by default)
PermissionsConfig.EnableStagingTestHarness = false
PermissionsConfig.AllowStagingOnDefaultPort = false

return PermissionsConfig

