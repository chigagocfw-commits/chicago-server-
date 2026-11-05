-- SOUH4IL-DEV — Server Permissions Service
-- Implements independent ACE checking, Dual-Key Owner Gate, and hierarchy protection

local Config = require 'config.permissions'
local Identifiers = require 'server.identifiers'

local Permissions = {}

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

    return IsPlayerAceAllowed(source, requiredPermission)
end

---Retrieves the role hierarchy level of a staff source
---@param source number
---@return string role
function Permissions.GetStaffRole(source)
    if Permissions.IsOwner(source) then
        return "OWNER"
    elseif IsPlayerAceAllowed(source, Config.ACES.DEVELOPER) then
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

return Permissions

