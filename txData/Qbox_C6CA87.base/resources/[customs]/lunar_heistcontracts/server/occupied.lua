local occupiedSpots = {}

-- Check if a spot is occupied
lib.callback.register("lunar_contracts:isSpotOccupied", function(source, spotId)
    if occupiedSpots[spotId] then
        return true
    end
    
    for _, playerId in pairs(occupiedSpots) do
        if source == playerId then
            return true
        end
    end
    
    occupiedSpots[spotId] = source
    
    SetTimeout(90000, function()
        if occupiedSpots[spotId] == source then
            occupiedSpots[spotId] = nil
        end
    end)
    
    return false
end)

-- Free an occupied spot
RegisterNetEvent("lunar_contracts:freeOccupiedSpot")
AddEventHandler("lunar_contracts:freeOccupiedSpot", function(spotId)
    local source = source
    if occupiedSpots[spotId] == source then
        occupiedSpots[spotId] = nil
    end
end)

-- Clean up on player drop
AddEventHandler("playerDropped", function()
    local source = source
    for spotId, playerId in pairs(occupiedSpots) do
        if source == playerId then
            occupiedSpots[spotId] = nil
            return
        end
    end
end)