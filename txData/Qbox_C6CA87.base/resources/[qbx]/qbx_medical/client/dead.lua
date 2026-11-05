local config = require 'config.client'
local sharedConfig = require 'config.shared'
local WEAPONS = exports.qbx_core:GetWeapons()
local allowRespawn = true
local plyState = LocalPlayer.state

local function playDeadAnimation()
    local deadAnimDict = 'dead'
    local playerData = QBX.PlayerData
    local metadata = playerData and playerData.metadata
    local deadAnim = metadata and metadata.ishandcuffed and 'dead_f' or 'dead_a'

    local deadVehAnimDict = 'veh@low@front_ps@idle_duck'
    local deadVehAnim = 'sit'

    if cache.vehicle then
        if not IsEntityPlayingAnim(cache.ped, deadVehAnimDict, deadVehAnim, 3) then
            lib.playAnim(cache.ped, deadVehAnimDict, deadVehAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
        end
    elseif not IsEntityPlayingAnim(cache.ped, deadAnimDict, deadAnim, 3) then
        lib.playAnim(cache.ped, deadAnimDict, deadAnim, 8.0, 1.0, -1, 1, 0, false, false, false)
    end
end

exports('PlayDeadAnimation', playDeadAnimation)

---put player in death animation and make invincible
function OnDeath(attacker, weapon)
    SetDeathState(sharedConfig.deathState.DEAD)
    WaitForPlayerToStopMoving()

    CreateThread(function()
        while DeathState == sharedConfig.deathState.DEAD do
            DisableControls()
            SetCurrentPedWeapon(cache.ped, `WEAPON_UNARMED`, true)
            Wait(0)
        end
    end)
    plyState.invBusy = true

    lib.requestAnimDict('dead')
    lib.requestAnimDict('veh@low@front_ps@idle_duck')
    ResurrectPlayer()
    playDeadAnimation()
    SetEntityInvincible(cache.ped, true)
    SetEntityHealth(cache.ped, GetEntityMaxHealth(cache.ped))
    -- Establish the downed pose before other resources handle the death.
    TriggerEvent('qbx_medical:client:onPlayerDied', attacker, weapon)
    TriggerServerEvent('qbx_medical:server:onPlayerDied', attacker, weapon)
    TriggerServerEvent('InteractSound_SV:PlayOnSource', 'demo', 0.1)
    allowRespawn = true
    CheckForRespawn()
end

exports('KillPlayer', OnDeath)

local isRespawning = false
local function respawn()
    if isRespawning then return end
    isRespawning = true
    local success = lib.callback.await('qbx_medical:server:respawn')
    if success then
        if QBX.PlayerData.metadata.ishandcuffed then
            TriggerEvent('police:client:GetCuffed', -1)
        end
        TriggerEvent('police:client:DeEscort')
        plyState.invBusy = false
    end
    isRespawning = false
end

---Allow player to respawn
function CheckForRespawn()
    allowRespawn = true
    RespawnHoldTime = 5
    local holdTimer = 0

    -- Smooth frame-level detection for holding [E]
    CreateThread(function()
        while DeathState == sharedConfig.deathState.DEAD do
            if allowRespawn and not isRespawning then
                local isEPressed = IsControlPressed(0, 38) or IsDisabledControlPressed(0, 38)
                if isEPressed then
                    holdTimer = holdTimer + (GetFrameTime() * 1000)
                    RespawnHoldTime = math.max(0, math.ceil((5000 - holdTimer) / 1000))
                    if holdTimer >= 5000 then
                        respawn()
                        Wait(1000)
                        holdTimer = 0
                        RespawnHoldTime = 5
                    end
                else
                    holdTimer = 0
                    RespawnHoldTime = 5
                end
            else
                holdTimer = 0
                RespawnHoldTime = 5
            end
            Wait(0)
        end
    end)

    -- Timer countdown for auto-respawn
    CreateThread(function()
        while DeathState == sharedConfig.deathState.DEAD do
            Wait(1000)
            if DeathTime > 0 then
                DeathTime -= 1
            elseif allowRespawn and not isRespawning then
                respawn()
                Wait(3000)
            end
        end
    end)
end

function AllowRespawn()
    allowRespawn = true
end

exports('AllowRespawn', AllowRespawn)

exports('DisableRespawn', function()
    allowRespawn = false
end)

---log the death of a player along with the attacker and the weapon used.
---@param victim number ped
---@param attacker number ped
---@param weapon string weapon hash
local function logDeath(victim, attacker, weapon)
    local playerId = NetworkGetPlayerIndexFromPed(victim)
    local playerName = (' %s (%d)'):format(GetPlayerName(playerId), GetPlayerServerId(playerId)) or locale('info.self_death')
    local killerId = NetworkGetPlayerIndexFromPed(attacker)
    local killerName = killerId ~= -1 and ('%s (%d)'):format(GetPlayerName(killerId), GetPlayerServerId(killerId)) or locale('info.self_death')
    local weaponLabel = WEAPONS[weapon]?.label or 'Unknown'
    local weaponName = WEAPONS[weapon]?.name or 'Unknown'
    local message = locale('logs.death_log_message', killerName, playerName, weaponLabel, weaponName)

    lib.callback.await('qbx_medical:server:log', false, 'logDeath', message)
end

---when player is killed by another player, set last stand mode, or if already in last stand mode, set player to dead mode.
---@param event string
---@param data table
AddEventHandler('gameEventTriggered', function(event, data)
    if event ~= 'CEventNetworkEntityDamage' then return end
    if not plyState.isLoggedIn then return end
    local victim, attacker, victimDied, weapon = data[1], data[2], data[4], data[7]
    if not IsEntityAPed(victim) or not victimDied or NetworkGetPlayerIndexFromPed(victim) ~= cache.playerId or not IsEntityDead(cache.ped) then return end
    if DeathState == sharedConfig.deathState.ALIVE then
        StartLastStand(attacker, weapon)
    elseif DeathState == sharedConfig.deathState.LAST_STAND then
        EndLastStand()
        logDeath(victim, attacker, weapon)
        DeathTime = config.deathTime
        OnDeath(attacker, weapon)
    end
end)

function DisableControls()
    DisableAllControlActions(0)
    EnableControlAction(0, 1, true)
    EnableControlAction(0, 2, true)
    EnableControlAction(0, 245, true)
    EnableControlAction(0, 38, true)
    EnableControlAction(0, 0, true)
    EnableControlAction(0, 322, true)
    EnableControlAction(0, 288, true)
    EnableControlAction(0, 213, true)
    EnableControlAction(0, 249, true)
    EnableControlAction(0, 46, true)
    EnableControlAction(0, 47, true)
end
