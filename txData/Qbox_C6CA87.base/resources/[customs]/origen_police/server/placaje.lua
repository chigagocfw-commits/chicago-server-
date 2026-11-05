-- Server-side tackle action handler
RegisterServerAction(
    "origen_police:placaje_sv",
    function(targetPlayerId)
        -- Validate target player exists
        if not targetPlayerId then
            return
        end
        
        -- Validate source player exists
        if not source then
            return
        end
        
        -- Trigger client-side tackle event on target player
        -- Parameters: target receives event, attacker's source ID
        TriggerClientEvent("origen_police:placaje_cl", targetPlayerId, source)
    end,
    "placaje",  -- Action name/identifier
    200,        -- Cooldown in milliseconds
    1,          -- Range in meters
    Config.Actions.AllowAllJobsTackle  -- Permission setting
)