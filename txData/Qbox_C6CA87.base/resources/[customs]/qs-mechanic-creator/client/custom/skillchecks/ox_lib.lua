if not Config.SkillCheck or Config.SkillCheck ~= 'ox_lib' then return end

local skillChecks = {}

skillChecks.Radial = {
    FullRepair = {
        difficulty = {'easy', 'easy', {areaSize = 60, speedMultiplier = 1}, 'medium'},
        keys = {'w', 'a', 's', 'd'}
    },
    BodyRepair = {
        difficulty = {'easy', 'easy', {areaSize = 60, speedMultiplier = 1}},
        keys = {'w', 'a', 's', 'd'}
    },
    EngineRepair = {
        difficulty = {'medium', {areaSize = 50, speedMultiplier = 1.2}, 'medium'},
        keys = {'w', 'a', 's', 'd'}
    },
    WashVehicle = {
        difficulty = {'easy', 'easy'},
        keys = {'w', 'a', 's', 'd'}
    },
    FlipVehicle = {
        difficulty = {'medium', 'medium'},
        keys = {'w', 'a', 's', 'd'}
    },
    FuelVehicle = {
        difficulty = {'easy', {areaSize = 60, speedMultiplier = 1}},
        keys = {'w', 'a', 's', 'd'}
    }
}

skillChecks.Installation = {
    General = {
        difficulty = {'easy', 'easy', 'easy', 'easy'},
        keys = {'w', 'a', 's', 'd'}
    }
}

function PerformRadialSkillCheck(checkType)
    local config = skillChecks.Radial[checkType]
    if not config then
        if Config.Debug then
            print('[qs-mechanic-creator] Warning: Radial skillcheck type not found: ' .. tostring(checkType))
        end
        return lib.skillCheck({'easy'}, {'w', 'a', 's', 'd'})
    end
    return lib.skillCheck(config.difficulty, config.keys)
end

function PerformInstallationSkillCheck()
    local config = skillChecks.Installation.General
    return lib.skillCheck(config.difficulty, config.keys)
end

function PerformSkillCheck(difficulty, keys)
    difficulty = difficulty or {'easy'}
    keys = keys or {'w', 'a', 's', 'd'}
    return lib.skillCheck(difficulty, keys)
end
