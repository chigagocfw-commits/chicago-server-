-- SOUH4IL-DEV — Server Permissions Service
-- Implements independent ACE checking, Dual-Key Owner Gate, Dynamic Database Staff Roles & Hierarchy

local Config = require 'config.permissions'
local Identifiers = require 'server.identifiers'

local Permissions = {}
Permissions.StaffCache = {}

Permissions.DEFAULT_ROLE_PERMS = {
    ['owner'] = {
        god = true,
        teleport = true,
        items = true,
        vehicles = true,
        characters = true,
        jobs = true,
        arsenal = true,
        players = true,
        punishments = true,
        devtools = true,
        world = true,
        logs = true,
        staff = true,
        events = true,
    },
    ['developer'] = {
        god = false,
        teleport = true,
        items = false,
        vehicles = true,
        characters = true,
        jobs = false,
        arsenal = false,
        players = true,
        punishments = false,
        devtools = true,
        world = true,
        logs = true,
        staff = false,
        events = true,
    },
    ['admin'] = {
        god = false,
        teleport = true,
        items = true,
        vehicles = true,
        characters = true,
        jobs = true,
        arsenal = false,
        players = true,
        punishments = true,
        devtools = false,
        world = true,
        logs = true,
        staff = false,
        events = true,
    },
    ['moderator'] = {
        god = false,
        teleport = true,
        items = false,
        vehicles = true,
        characters = false,
        jobs = false,
        arsenal = false,
        players = true,
        punishments = false,
        devtools = false,
        world = false,
        logs = false,
        staff = false,
        events = false,
    },
    ['custom'] = {
        god = false,
        teleport = true,
        items = false,
        vehicles = false,
        characters = false,
        jobs = false,
        arsenal = false,
        players = true,
        punishments = false,
        devtools = false,
        world = false,
        logs = false,
        staff = false,
        events = false,
    }
}

---Initializes staff table in MySQL and loads in-memory cache
function Permissions.InitDB()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `souh4il_dev_staff` (
          `license` varchar(70) NOT NULL PRIMARY KEY,
          `name` varchar(100) NOT NULL,
          `role` varchar(50) NOT NULL DEFAULT 'moderator',
          `permissions` longtext NOT NULL,
          `granted_by` varchar(100) NOT NULL,
          `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
          `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    local rows = MySQL.query.await("SELECT * FROM `souh4il_dev_staff`")
    Permissions.StaffCache = {}

    if rows and #rows > 0 then
        for _, row in ipairs(rows) do
            local perms = {}
            if row.permissions and row.permissions ~= "" then
                local decoded = json.decode(row.permissions)
                if type(decoded) == 'table' then
                    perms = decoded
                end
            end

            -- If perms is empty table, fill from default role
            local roleKey = string.lower(row.role or 'moderator')
            if not next(perms) and Permissions.DEFAULT_ROLE_PERMS[roleKey] then
                perms = table.clone(Permissions.DEFAULT_ROLE_PERMS[roleKey])
            end

            Permissions.StaffCache[row.license] = {
                license = row.license,
                name = row.name,
                role = string.upper(row.role or 'MODERATOR'),
                permissions = perms,
                granted_by = row.granted_by or 'System',
                created_at = row.created_at,
            }

            -- Sync ACE
            ExecuteCommand(('add_principal identifier.license:%s souh4il_dev.access'):format(row.license))
            ExecuteCommand(('add_principal identifier.license:%s souh4il_dev.%s'):format(row.license, roleKey))
        end
    end

    lib.print.info(("^2[SOUH4IL-DEV] Staff permissions loaded (%d registered staff members)^0"):format(#rows or 0))
end

---Verifies whether a source possesses explicit Owner authority (Dual-Key Mandatory Gate)
---@param source number
---@return boolean isOwner
function Permissions.IsOwner(source)
    -- Gate 1: Check dedicated ACE permission
    if not IsPlayerAceAllowed(source, Config.ACES.OWNER) then
        return false
    end

    -- Gate 2: Defense-in-depth Canonical License verification
    if not Identifiers.IsCanonicalOwner(source) then
        return false
    end

    return true
end

---Validates execution rights for any permission level
---@param source number
---@param requiredPermission string
---@return boolean allowed
function Permissions.CanExecute(source, requiredPermission)
    if requiredPermission == Config.ACES.OWNER then
        return Permissions.IsOwner(source)
    end

    if Permissions.IsOwner(source) then
        return true
    end

    local lic = Identifiers.GetLicense(source)
    if lic and Permissions.StaffCache[lic] then
        return true
    end

    return IsPlayerAceAllowed(source, requiredPermission)
end

---Checks whether player is allowed to open the panel
---@param source number
---@return boolean canOpen
function Permissions.CanOpenPanel(source)
    if Permissions.IsOwner(source) then
        return true
    end

    local lic = Identifiers.GetLicense(source)
    if lic and Permissions.StaffCache[lic] then
        return true
    end

    return IsPlayerAceAllowed(source, Config.ACES.ACCESS) or IsPlayerAceAllowed(source, Config.ACES.ADMIN)
end

---Retrieves the full active permissions table for a caller
---@param source number
---@return table permissions
function Permissions.GetPermissions(source)
    if Permissions.IsOwner(source) then
        return table.clone(Permissions.DEFAULT_ROLE_PERMS.owner)
    end

    local lic = Identifiers.GetLicense(source)
    if lic and Permissions.StaffCache[lic] then
        return Permissions.StaffCache[lic].permissions or {}
    end

    -- Fallback for ACE-only admins
    if IsPlayerAceAllowed(source, Config.ACES.ADMIN) then
        return table.clone(Permissions.DEFAULT_ROLE_PERMS.admin)
    elseif IsPlayerAceAllowed(source, Config.ACES.MODERATOR) then
        return table.clone(Permissions.DEFAULT_ROLE_PERMS.moderator)
    end

    return {}
end

---Checks whether source has access to a specific functional module/tab
---@param source number
---@param moduleName string
---@return boolean allowed
function Permissions.HasModulePermission(source, moduleName)
    if Permissions.IsOwner(source) then
        return true
    end

    local perms = Permissions.GetPermissions(source)
    if perms and perms[moduleName] == true then
        return true
    end

    return false
end

---Retrieves the role hierarchy level of a staff source
---@param source number
---@return string role
function Permissions.GetStaffRole(source)
    if Permissions.IsOwner(source) then
        return "OWNER"
    end

    local lic = Identifiers.GetLicense(source)
    if lic and Permissions.StaffCache[lic] then
        return Permissions.StaffCache[lic].role or "MODERATOR"
    end

    if IsPlayerAceAllowed(source, Config.ACES.DEVELOPER) then
        return "DEVELOPER"
    elseif IsPlayerAceAllowed(source, Config.ACES.ADMIN) then
        return "ADMIN"
    elseif IsPlayerAceAllowed(source, Config.ACES.MODERATOR) then
        return "MODERATOR"
    end
    return "PLAYER"
end

---Checks whether staff member can target another player under hierarchy rules
---@param staffSource number
---@param targetSource number
---@return boolean canTarget, string? reason
function Permissions.CanTargetPlayer(staffSource, targetSource)
    if staffSource == targetSource then
        return true -- Self actions allowed
    end

    local staffRole = Permissions.GetStaffRole(staffSource)
    local targetRole = Permissions.GetStaffRole(targetSource)

    -- Hierarchy rank values
    local RANKS = {
        ['OWNER'] = 4,
        ['DEVELOPER'] = 3,
        ['ADMIN'] = 2,
        ['MODERATOR'] = 1,
        ['PLAYER'] = 0,
    }

    local staffRank = RANKS[staffRole] or 0
    local targetRank = RANKS[targetRole] or 0

    -- Staff cannot perform punitive actions on equal or higher rank
    if staffRank <= targetRank and targetRank > 0 then
        return false, "CANNOT_TARGET_EQUAL_OR_HIGHER_RANK"
    end

    return true
end

---Saves or updates a staff member with customized permissions
---@param license string
---@param name string
---@param role string
---@param permissions table
---@param granterName string
---@return boolean success, string? err
function Permissions.SaveStaff(license, name, role, permissions, granterName)
    if not license or license == "" then return false, "INVALID_LICENSE" end
    role = string.lower(role or 'moderator')
    local upperRole = string.upper(role)

    -- If permissions is empty or not provided, load default for role
    if type(permissions) ~= 'table' or not next(permissions) then
        permissions = table.clone(Permissions.DEFAULT_ROLE_PERMS[role] or Permissions.DEFAULT_ROLE_PERMS.moderator)
    end

    local jsonPerms = json.encode(permissions)

    local success, err = pcall(function()
        MySQL.query.await([[
            INSERT INTO `souh4il_dev_staff` (`license`, `name`, `role`, `permissions`, `granted_by`)
            VALUES (?, ?, ?, ?, ?)
            ON DUPLICATE KEY UPDATE
              `name` = VALUES(`name`),
              `role` = VALUES(`role`),
              `permissions` = VALUES(`permissions`),
              `granted_by` = VALUES(`granted_by`);
        ]], { license, name, upperRole, jsonPerms, granterName })
    end)

    if not success then
        lib.print.error("[SOUH4IL-DEV] Failed to save staff member: " .. tostring(err))
        return false, tostring(err)
    end

    Permissions.StaffCache[license] = {
        license = license,
        name = name,
        role = upperRole,
        permissions = permissions,
        granted_by = granterName,
    }

    ExecuteCommand(('add_principal identifier.license:%s souh4il_dev.access'):format(license))
    ExecuteCommand(('add_principal identifier.license:%s souh4il_dev.%s'):format(license, role))
    return true
end

---Removes a staff member from database and cache
---@param license string
---@return boolean success, string? err
function Permissions.RemoveStaff(license)
    if not license or license == "" then return false, "INVALID_LICENSE" end
    if license == Config.CanonicalOwnerLicense then
        return false, "CANNOT_REMOVE_CANONICAL_OWNER"
    end

    local cached = Permissions.StaffCache[license]
    local role = cached and string.lower(cached.role) or 'moderator'

    local success, err = pcall(function()
        MySQL.query.await("DELETE FROM `souh4il_dev_staff` WHERE `license` = ?", { license })
    end)

    if not success then
        lib.print.error("[SOUH4IL-DEV] Failed to delete staff member: " .. tostring(err))
        return false, tostring(err)
    end

    Permissions.StaffCache[license] = nil

    ExecuteCommand(('remove_principal identifier.license:%s souh4il_dev.access'):format(license))
    ExecuteCommand(('remove_principal identifier.license:%s souh4il_dev.%s'):format(license, role))
    return true
end

return Permissions

