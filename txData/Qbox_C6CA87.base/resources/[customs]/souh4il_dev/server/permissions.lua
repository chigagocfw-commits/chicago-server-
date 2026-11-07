-- SOUH4IL-DEV — Server Permissions Service
-- Implements independent ACE checking, Dual-Key Owner Gate, Dynamic Database Staff Roles & Hierarchy

local Config = require 'config.permissions'
local Identifiers = require 'server.identifiers'

local Permissions = {}
Permissions.StaffCache = {}

Permissions.DEFAULT_ROLE_PERMS = {
    ['owner'] = {
        -- Master Tab Visibility Toggles (16 Tabs)
        tab_dashboard = true,
        tab_god = true,
        tab_players = true,
        tab_manage = true,
        tab_teleport = true,
        tab_items = true,
        tab_vehicles = true,
        tab_characters = true,
        tab_jobs = true,
        tab_arsenal = true,
        tab_world = true,
        tab_devtools = true,
        tab_events = true,
        tab_emotes = true,
        tab_logs = true,
        tab_staff = true,
        -- Sub-permissions per Tab
        dash_metrics = true,
        self_actions = true,
        dash_self_veh = true,
        dash_self_tp = true,
        dash_self_cash = true,
        mass_actions = true,
        dash_purge_cops = true,
        dash_announce = true,
        dash_logs_feed = true,
        -- Players Tab
        view_players = true,
        players_view_money = true,
        players_btn_manage = true,
        player_heal = true,
        player_inventory = true,
        player_teleport = true,
        player_freeze = true,
        player_spectate = true,
        punish_kicks = true,
        punish_bans = true,
        -- Manage Player Tab
        manage_tp = true,
        manage_freeze = true,
        manage_money = true,
        manage_give_item = true,
        manage_inv = true,
        manage_jobs = true,
        manage_heal = true,
        player_vehicles = true,
        manage_assets = true,
        manage_properties = true,
        player_clothing = true,
        manage_skins = true,
        manage_trolls = true,
        manage_force_dance = true,
        player_pm = true,
        manage_warn_kick = true,
        manage_ban = true,
        manage_wipes = true,
        -- Teleport Tab
        world_teleport = true,
        tp_players = true,
        tp_locations = true,
        tp_bookmarks = true,
        tp_coords = true,
        -- Items & Weapons Tab
        spawn_items = true,
        items_weapons = true,
        items_give_others = true,
        items_custom_spawn = true,
        items_weapon_tint = true,
        -- God Powers Tab
        god_powers = true,
        noclip_power = true,
        admin_esp = true,
        combat_powers = true,
        veh_powers = true,
        god_self_utils = true,
        god_area_clean = true,
        -- Vehicles Tab
        spawn_vehicles = true,
        veh_manual_spawn = true,
        veh_workshop = true,
        veh_save_garage = true,
        -- Characters & Jobs Tabs
        chars_catalog = true,
        chars_custom_hash = true,
        jobs_catalog = true,
        -- Arsenal Tab
        arsenal = true,
        arsenal_give_others = true,
        arsenal_economy = true,
        -- World & DevTools & Events & Emotes & Logs & Staff
        world_control = true,
        world_announce = true,
        npc_control = true,
        world_props_cmd = true,
        world_offline_ban = true,
        devtools = true,
        devtools_clean = true,
        devtools_skins = true,
        events = true,
        events_custom = true,
        dances_emotes = true,
        emotes_target_player = true,
        emotes_target_all = true,
        logs = true,
        staff_management = true,
        -- Legacy Aliases
        god = true, teleport = true, items = true, vehicles = true, characters = true, jobs = true, players = true, punishments = true, world = true, staff = true,
    },
    ['developer'] = {
        -- Master Tab Visibility Toggles
        tab_dashboard = true,
        tab_god = true,
        tab_players = true,
        tab_manage = true,
        tab_teleport = true,
        tab_items = false,
        tab_vehicles = true,
        tab_characters = true,
        tab_jobs = false,
        tab_arsenal = false,
        tab_world = true,
        tab_devtools = true,
        tab_events = true,
        tab_emotes = true,
        tab_logs = true,
        tab_staff = false,
        -- Sub-permissions
        dash_metrics = true,
        self_actions = true,
        dash_self_veh = true,
        dash_self_tp = true,
        dash_self_cash = false,
        mass_actions = false,
        dash_purge_cops = true,
        dash_announce = false,
        dash_logs_feed = true,
        view_players = true,
        players_view_money = false,
        players_btn_manage = true,
        player_heal = false,
        player_inventory = false,
        player_teleport = true,
        player_freeze = false,
        player_spectate = true,
        punish_kicks = false,
        punish_bans = false,
        manage_tp = true,
        manage_freeze = false,
        manage_money = false,
        manage_give_item = false,
        manage_inv = false,
        manage_jobs = false,
        manage_heal = false,
        player_vehicles = true,
        manage_assets = false,
        manage_properties = false,
        player_clothing = true,
        manage_skins = true,
        manage_trolls = false,
        manage_force_dance = false,
        player_pm = true,
        manage_warn_kick = false,
        manage_ban = false,
        manage_wipes = false,
        world_teleport = true,
        tp_players = true,
        tp_locations = true,
        tp_bookmarks = true,
        tp_coords = true,
        spawn_items = false,
        items_weapons = false,
        items_give_others = false,
        items_custom_spawn = false,
        items_weapon_tint = false,
        god_powers = false,
        noclip_power = true,
        admin_esp = true,
        combat_powers = false,
        veh_powers = true,
        god_self_utils = true,
        god_area_clean = true,
        spawn_vehicles = true,
        veh_manual_spawn = true,
        veh_workshop = true,
        veh_save_garage = false,
        chars_catalog = true,
        chars_custom_hash = true,
        jobs_catalog = false,
        arsenal = false,
        arsenal_give_others = false,
        arsenal_economy = false,
        world_control = true,
        world_announce = false,
        npc_control = true,
        world_props_cmd = true,
        world_offline_ban = false,
        devtools = true,
        devtools_clean = true,
        devtools_skins = true,
        events = true,
        events_custom = true,
        dances_emotes = true,
        emotes_target_player = false,
        emotes_target_all = false,
        logs = true,
        staff_management = false,
        god = false, teleport = true, items = false, vehicles = true, characters = true, jobs = false, players = true, punishments = false, world = true, staff = false,
    },
    ['admin'] = {
        -- Master Tab Visibility Toggles
        tab_dashboard = true,
        tab_god = true,
        tab_players = true,
        tab_manage = true,
        tab_teleport = true,
        tab_items = true,
        tab_vehicles = true,
        tab_characters = true,
        tab_jobs = true,
        tab_arsenal = false,
        tab_world = true,
        tab_devtools = false,
        tab_events = true,
        tab_emotes = true,
        tab_logs = true,
        tab_staff = false,
        -- Sub-permissions
        dash_metrics = true,
        self_actions = true,
        dash_self_veh = true,
        dash_self_tp = true,
        dash_self_cash = false,
        mass_actions = true,
        dash_purge_cops = true,
        dash_announce = true,
        dash_logs_feed = true,
        view_players = true,
        players_view_money = true,
        players_btn_manage = true,
        player_heal = true,
        player_inventory = true,
        player_teleport = true,
        player_freeze = true,
        player_spectate = true,
        punish_kicks = true,
        punish_bans = true,
        manage_tp = true,
        manage_freeze = true,
        manage_money = false,
        manage_give_item = true,
        manage_inv = true,
        manage_jobs = true,
        manage_heal = true,
        player_vehicles = true,
        manage_assets = true,
        manage_properties = true,
        player_clothing = true,
        manage_skins = true,
        manage_trolls = false,
        manage_force_dance = true,
        player_pm = true,
        manage_warn_kick = true,
        manage_ban = true,
        manage_wipes = false,
        world_teleport = true,
        tp_players = true,
        tp_locations = true,
        tp_bookmarks = true,
        tp_coords = true,
        spawn_items = true,
        items_weapons = true,
        items_give_others = true,
        items_custom_spawn = true,
        items_weapon_tint = false,
        god_powers = false,
        noclip_power = true,
        admin_esp = true,
        combat_powers = false,
        veh_powers = true,
        god_self_utils = true,
        god_area_clean = true,
        spawn_vehicles = true,
        veh_manual_spawn = true,
        veh_workshop = true,
        veh_save_garage = false,
        chars_catalog = true,
        chars_custom_hash = false,
        jobs_catalog = true,
        arsenal = false,
        arsenal_give_others = false,
        arsenal_economy = false,
        world_control = true,
        world_announce = true,
        npc_control = true,
        world_props_cmd = false,
        world_offline_ban = true,
        devtools = false,
        devtools_clean = false,
        devtools_skins = false,
        events = true,
        events_custom = true,
        dances_emotes = true,
        emotes_target_player = true,
        emotes_target_all = false,
        logs = true,
        staff_management = false,
        god = false, teleport = true, items = true, vehicles = true, characters = true, jobs = true, players = true, punishments = true, world = true, staff = false,
    },
    ['moderator'] = {
        -- Master Tab Visibility Toggles
        tab_dashboard = true,
        tab_god = true,
        tab_players = true,
        tab_manage = true,
        tab_teleport = true,
        tab_items = false,
        tab_vehicles = true,
        tab_characters = false,
        tab_jobs = false,
        tab_arsenal = false,
        tab_world = false,
        tab_devtools = false,
        tab_events = false,
        tab_emotes = true,
        tab_logs = false,
        tab_staff = false,
        -- Sub-permissions
        dash_metrics = true,
        self_actions = true,
        dash_self_veh = true,
        dash_self_tp = true,
        dash_self_cash = false,
        mass_actions = false,
        dash_purge_cops = false,
        dash_announce = false,
        dash_logs_feed = false,
        view_players = true,
        players_view_money = false,
        players_btn_manage = true,
        player_heal = true,
        player_inventory = false,
        player_teleport = true,
        player_freeze = true,
        player_spectate = true,
        punish_kicks = true,
        punish_bans = false,
        manage_tp = true,
        manage_freeze = true,
        manage_money = false,
        manage_give_item = false,
        manage_inv = false,
        manage_jobs = false,
        manage_heal = true,
        player_vehicles = false,
        manage_assets = false,
        manage_properties = false,
        player_clothing = true,
        manage_skins = false,
        manage_trolls = false,
        manage_force_dance = false,
        player_pm = true,
        manage_warn_kick = true,
        manage_ban = false,
        manage_wipes = false,
        world_teleport = false,
        tp_players = true,
        tp_locations = true,
        tp_bookmarks = false,
        tp_coords = false,
        spawn_items = false,
        items_weapons = false,
        items_give_others = false,
        items_custom_spawn = false,
        items_weapon_tint = false,
        god_powers = false,
        noclip_power = true,
        admin_esp = true,
        combat_powers = false,
        veh_powers = false,
        god_self_utils = true,
        god_area_clean = false,
        spawn_vehicles = true,
        veh_manual_spawn = false,
        veh_workshop = false,
        veh_save_garage = false,
        chars_catalog = false,
        chars_custom_hash = false,
        jobs_catalog = false,
        arsenal = false,
        arsenal_give_others = false,
        arsenal_economy = false,
        world_control = false,
        world_announce = false,
        npc_control = false,
        world_props_cmd = false,
        world_offline_ban = false,
        devtools = false,
        devtools_clean = false,
        devtools_skins = false,
        events = false,
        events_custom = false,
        dances_emotes = true,
        emotes_target_player = false,
        emotes_target_all = false,
        logs = false,
        staff_management = false,
        god = false, teleport = true, items = false, vehicles = true, characters = false, jobs = false, players = true, punishments = false, world = false, staff = false,
    },
    ['custom'] = {
        tab_dashboard = true,
        tab_god = false,
        tab_players = true,
        tab_manage = false,
        tab_teleport = true,
        tab_items = false,
        tab_vehicles = false,
        tab_characters = false,
        tab_jobs = false,
        tab_arsenal = false,
        tab_world = false,
        tab_devtools = false,
        tab_events = false,
        tab_emotes = false,
        tab_logs = false,
        tab_staff = false,
        dash_metrics = true,
        self_actions = false,
        dash_self_veh = false,
        dash_self_tp = false,
        dash_self_cash = false,
        mass_actions = false,
        dash_purge_cops = false,
        dash_announce = false,
        dash_logs_feed = false,
        view_players = true,
        players_view_money = false,
        players_btn_manage = false,
        player_heal = false,
        player_inventory = false,
        player_teleport = true,
        player_freeze = false,
        player_spectate = false,
        punish_kicks = false,
        punish_bans = false,
        manage_tp = false,
        manage_freeze = false,
        manage_money = false,
        manage_give_item = false,
        manage_inv = false,
        manage_jobs = false,
        manage_heal = false,
        player_vehicles = false,
        manage_assets = false,
        manage_properties = false,
        player_clothing = false,
        manage_skins = false,
        manage_trolls = false,
        manage_force_dance = false,
        player_pm = false,
        manage_warn_kick = false,
        manage_ban = false,
        manage_wipes = false,
        world_teleport = false,
        tp_players = true,
        tp_locations = true,
        tp_bookmarks = false,
        tp_coords = false,
        spawn_items = false,
        items_weapons = false,
        items_give_others = false,
        items_custom_spawn = false,
        items_weapon_tint = false,
        god_powers = false,
        noclip_power = false,
        admin_esp = false,
        combat_powers = false,
        veh_powers = false,
        god_self_utils = false,
        god_area_clean = false,
        spawn_vehicles = false,
        veh_manual_spawn = false,
        veh_workshop = false,
        veh_save_garage = false,
        chars_catalog = false,
        chars_custom_hash = false,
        jobs_catalog = false,
        arsenal = false,
        arsenal_give_others = false,
        arsenal_economy = false,
        world_control = false,
        world_announce = false,
        npc_control = false,
        world_props_cmd = false,
        world_offline_ban = false,
        devtools = false,
        devtools_clean = false,
        devtools_skins = false,
        events = false,
        events_custom = false,
        dances_emotes = false,
        emotes_target_player = false,
        emotes_target_all = false,
        logs = false,
        staff_management = false,
        god = false, teleport = true, items = false, vehicles = false, characters = false, jobs = false, players = true, punishments = false, world = false, staff = false,
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
            ExecuteCommand(('add_ace identifier.license:%s souh4il_dev.access allow'):format(row.license))
            ExecuteCommand(('add_ace identifier.license:%s souh4il_dev.%s allow'):format(row.license, roleKey))
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
        -- Base panel access
        if requiredPermission == Config.ACES.ACCESS then
            return true
        end

        local staffRole = string.upper(Permissions.StaffCache[lic].role or "MODERATOR")
        if requiredPermission == Config.ACES.ADMIN then
            return staffRole == "OWNER" or staffRole == "ADMIN"
        elseif requiredPermission == Config.ACES.DEVELOPER then
            return staffRole == "OWNER" or staffRole == "DEVELOPER"
        elseif requiredPermission == Config.ACES.MODERATOR then
            return staffRole == "OWNER" or staffRole == "ADMIN" or staffRole == "DEVELOPER" or staffRole == "MODERATOR"
        end

        -- Module/Action permission check
        return Permissions.HasModulePermission(source, requiredPermission)
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
    if not perms then return false end

    -- Direct granular check
    if perms[moduleName] == true then
        return true
    end

    -- Explicit security isolation: Money and Wipes NEVER inherit from generic broad permissions!
    if moduleName == 'manage_money' then
        return perms.manage_money == true or perms.dash_self_cash == true or perms.arsenal_economy == true
    elseif moduleName == 'manage_wipes' then
        return perms.manage_wipes == true
    end

    -- Legacy & Granular Tab-Specific mapping fallbacks
    if moduleName == 'player_teleport' then
        return perms.manage_tp == true or perms.tp_players == true or perms.teleport == true or perms.players == true
    elseif moduleName == 'player_heal' then
        return perms.manage_heal == true or perms.players == true
    elseif moduleName == 'player_freeze' then
        return perms.manage_freeze == true or perms.players == true
    elseif moduleName == 'player_spectate' or moduleName == 'view_players' or moduleName == 'player_pm' then
        return perms.players == true or perms.players_btn_manage == true
    elseif moduleName == 'player_inventory' then
        return perms.manage_inv == true or perms.items == true
    elseif moduleName == 'spawn_items' then
        return perms.manage_give_item == true or perms.items_weapons == true or perms.items_custom_spawn == true or perms.items == true
    elseif moduleName == 'spawn_vehicles' then
        return perms.veh_manual_spawn == true or perms.veh_workshop == true or perms.veh_save_garage == true or perms.vehicles == true
    elseif moduleName == 'player_vehicles' then
        return perms.vehicles == true
    elseif moduleName == 'manage_assets' or moduleName == 'manage_properties' then
        local lic = Identifiers.GetLicense(source)
        local role = (lic and Permissions.StaffCache[lic] and Permissions.StaffCache[lic].role) or "MODERATOR"
        return (perms.vehicles == true or perms.characters == true or perms.manage_assets == true or perms.veh_save_garage == true) and (role == "OWNER" or role == "ADMIN")
    elseif moduleName == 'manage_skins' or moduleName == 'player_clothing' then
        return perms.chars_catalog == true or perms.chars_custom_hash == true or perms.devtools_skins == true or perms.characters == true or perms.manage_skins == true
    elseif moduleName == 'manage_jobs' then
        return perms.jobs_catalog == true or perms.jobs == true
    elseif moduleName == 'manage_trolls' then
        return perms.manage_force_dance == true or perms.emotes_target_player == true or perms.emotes_target_all == true or perms.god == true
    elseif moduleName == 'punish_bans' then
        if perms.manage_ban == true or perms.world_offline_ban == true then
            return true
        end
        local lic = Identifiers.GetLicense(source)
        local role = (lic and Permissions.StaffCache[lic] and Permissions.StaffCache[lic].role) or "MODERATOR"
        return perms.punishments == true and role ~= "MODERATOR"
    elseif moduleName == 'punish_kicks' then
        return perms.manage_warn_kick == true or perms.punishments == true
    elseif moduleName == 'world_teleport' then
        return perms.dash_self_tp == true or perms.tp_locations == true or perms.tp_bookmarks == true or perms.tp_coords == true or perms.teleport == true
    elseif moduleName == 'world_control' then
        return perms.world_announce == true or perms.dash_announce == true or perms.world == true or perms.world_control == true
    elseif moduleName == 'npc_control' then
        return perms.dash_purge_cops == true or perms.world == true or perms.world_control == true
    elseif moduleName == 'god_powers' or moduleName == 'noclip_power' or moduleName == 'admin_esp' or moduleName == 'combat_powers' or moduleName == 'veh_powers' then
        return perms.god == true or perms.god_powers == true
    elseif moduleName == 'self_actions' then
        return perms.dash_self_veh == true or perms.god_self_utils == true or perms.player_heal == true or perms.god_powers == true
    elseif moduleName == 'mass_actions' then
        return perms.god_area_clean == true or perms.emotes_target_all == true or perms.dash_announce == true
    elseif moduleName == 'devtools' then
        return perms.devtools_clean == true or perms.devtools_skins == true or perms.world_props_cmd == true
    elseif moduleName == 'events' then
        return perms.events_custom == true
    elseif moduleName == 'logs' then
        return perms.dash_logs_feed == true
    elseif moduleName == 'dances_emotes' then
        return perms.dances_emotes == true or perms.manage_force_dance == true or perms.emotes_target_player == true or perms.emotes_target_all == true or perms.manage_skins == true or perms.characters == true
    elseif moduleName == 'staff_management' then
        return perms.staff == true
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

    ExecuteCommand(('add_ace identifier.license:%s souh4il_dev.access allow'):format(license))
    ExecuteCommand(('add_ace identifier.license:%s souh4il_dev.%s allow'):format(license, role))
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

    ExecuteCommand(('remove_ace identifier.license:%s souh4il_dev.access allow'):format(license))
    ExecuteCommand(('remove_ace identifier.license:%s souh4il_dev.%s allow'):format(license, role))
    return true
end

return Permissions

