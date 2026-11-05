if not Config.SkillCheck or Config.SkillCheck ~= 'standalone' then return end

local skillChecks = {}

skillChecks.Radial = {
    FullRepair = {
        difficulty = 'medium',
        duration = 10000,
        stages = 4
    },
    BodyRepair = {
        difficulty = 'easy',
        duration = 8000,
        stages = 3
    },
    EngineRepair = {
        difficulty = 'hard',
        duration = 12000,
        stages = 3
    },
    WashVehicle = {
        difficulty = 'easy',
        duration = 5000,
        stages = 2
    },
    FlipVehicle = {
        difficulty = 'medium',
        duration = 7000,
        stages = 2
    },
    FuelVehicle = {
        difficulty = 'easy',
        duration = 6000,
        stages = 2
    }
}

skillChecks.Installation = {
    General = {
        difficulty = 'medium',
        duration = 8000,
        stages = 4
    }
}

function PerformRadialSkillCheck(checkType)
    local config = skillChecks.Radial[checkType]
    if not config then
        if Config.Debug then
            print('[qs-mechanic-creator] Warning: Radial skillcheck type not found: ' .. tostring(checkType))
        end
        config = {difficulty = 'easy', duration = 5000, stages = 1}
    end

    if lib and lib.progressBar then
        local success = lib.progressBar({
            duration = config.duration,
            label = 'Working...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            }
        })
        return success
    end

    if Config.Debug then
        print('[qs-mechanic-creator] WARNING: Using fallback skillcheck! Configure your skillcheck system in client/custom/skillchecks/standalone.lua')
    end
    return true
end

function PerformInstallationSkillCheck()
    local config = skillChecks.Installation.General

    if lib and lib.progressBar then
        local success = lib.progressBar({
            duration = config.duration,
            label = 'Installing...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            }
        })
        return success
    end

    if Config.Debug then
        print('[qs-mechanic-creator] WARNING: Using fallback skillcheck! Configure your skillcheck system in client/custom/skillchecks/standalone.lua')
    end
    return true
end

function PerformSkillCheck(difficulty, keys)
    local calculatedDuration = 5000

    if type(difficulty) == 'table' then
        calculatedDuration = #difficulty * 2000
    elseif type(difficulty) == 'number' then
        calculatedDuration = difficulty
    end

    if lib and lib.progressBar then
        local success = lib.progressBar({
            duration = calculatedDuration,
            label = 'Working...',
            useWhileDead = false,
            canCancel = true,
            disable = {
                car = true,
                move = true,
                combat = true
            }
        })
        return success
    end

    if Config.Debug then
        print('[qs-mechanic-creator] WARNING: Using fallback skillcheck! Configure your skillcheck system in client/custom/skillchecks/standalone.lua')
    end
    return true
end
