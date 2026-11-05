local leaderboardData = {}

lib.callback("lunar_contracts:getLeaderboard", 1000, function(data)
    leaderboardData = data
end)

RegisterNetEvent("lunar_contracts:updateLeaderboard", function(data)
    leaderboardData = data
end)

RegisterNetEvent("lunar_contracts:updateProfile", function(profileData)
    for i, entry in ipairs(leaderboardData) do
        if entry.identifier == profileData.identifier then
            leaderboardData[i] = profileData
            break
        end
    end
end)

RegisterNUICallback("getLeaderboard", function(_, cb)
    for _, entry in ipairs(leaderboardData) do
        if not entry.image then
            entry.image = Config.defaultProfile.image
        end
    end
    cb(leaderboardData)
end)