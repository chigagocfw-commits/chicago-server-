return {
    doctorCallCooldown = 1, -- Time in minutes for cooldown between doctors calls
    wipeInvOnRespawn = false, -- Enable to disable removing all items from player on respawn
    depositSociety = function(society, amount)
        if GetResourceState('Renewed-Banking') == 'started' then
            pcall(function() exports['Renewed-Banking']:addAccountMoney(society, amount) end)
        elseif GetResourceState('bablo-banking') == 'started' then
            pcall(function() exports['bablo-banking']:AddSocietyMoney(society, amount) end)
        end
    end
}