-- Loaded before client/modules/** — radial/tablet call getPlayerData at runtime.
-- permissions.lua overwrites these with the full implementation when it loads.

playerJob = playerJob or nil
playerLicense = playerLicense or nil

if type(setPlayerData) ~= 'function' then
    function setPlayerData(job, license)
        playerJob = job
        playerLicense = license
    end
end

if type(getPlayerData) ~= 'function' then
    function getPlayerData()
        return {
            job = playerJob,
            license = playerLicense,
        }
    end
end

if type(getPlayerJob) ~= 'function' then
    function getPlayerJob()
        return playerJob
    end
end
