-- This file is dedicated in the ban functions related that are executed when the server detects a strange behavior from a player.
function BanPlayer(source, reason)
    -- Make sure to add the ban logic here
    local playerName = GetPlayerName(source)
    if playerName then
        print("Player " .. playerName .. "(" .. source .. ") has been kicked. Reason: " .. reason)
    else
        print("Player (ID: " .. source .. ") has been kicked. Reason: " .. reason)
    end
    DropPlayer(source, "You have been kicked from the server. Reason: " .. reason)
end