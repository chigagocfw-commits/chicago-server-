



if not Config.Modules['DisableCombatRoll'] then return end

local function CombatRollThread()
    CreateThread(function()
        while Armed do
            local sleepThread = 0
            if GetIsTaskActive(cache.ped, 3) then
                TaskPlayAnim(cache.ped, "combat@aim_variations@1h", "aim_med", 8.0, -8.0, 100, 1, 0, false, false, false)
            end
            Wait(sleepThread)
        end
    end)
end

lib.onCache('weapon', function(weapon)
    Wait(5)
    if not weapon then
        Armed = false
        return
    end
    Armed = true
    CombatRollThread()
end)
