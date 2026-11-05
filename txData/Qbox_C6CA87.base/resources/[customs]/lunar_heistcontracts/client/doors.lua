local doorSets = {}

local function addDoorSet(doorSet)
    for _, door in ipairs(doorSet.doors) do
        if not door.coords then goto continue end
        AddDoorToSystem(door.hash, door.model, door.coords.x, door.coords.y, door.coords.z, false, false, false)
        DoorSystemSetDoorState(door.hash, 4, false, false)
        DoorSystemSetDoorState(door.hash, doorSet.locked and 1 or 0, false, false)
        ::continue::
    end
    table.insert(doorSets, doorSet)
end

lib.callback("lunar_contracts:getDoors", false, function(doors)
    for _, doorSet in ipairs(doors) do
        addDoorSet(doorSet)
    end
end)

RegisterNetEvent("lunar_contracts:setDoorState", function(doorSetIndex, locked)
    local doorSet = doorSets[doorSetIndex]
    
    for _, door in ipairs(doorSet.doors) do
        DoorSystemSetDoorState(door.hash, locked and 1 or 0, false, false)
    end
    
    doorSet.locked = locked
end)

local doorZones = {}

RegisterNetEvent("lunar_contracts:setMultipleDoorState", function(startIndex, endIndex, locked)
    for i = startIndex, endIndex do
        local doorSet = doorSets[i]
        
        for _, door in ipairs(doorSet.doors) do
            DoorSystemSetDoorState(door.hash, locked and 1 or 0, false, false)
            
            if door.model == -1549164937 or door.model == -1710290106 then
                if not locked then
                    doorZones[i] = lib.zones.sphere({
                        coords = door.coords,
                        radius = 25.0,
                        onEnter = function()
                            DoorSystemSetDoorState(door.hash, 0, false, false)
                        end
                    })
                else
                    if doorZones[i] then
                        doorZones[i].remove()
                        doorZones[i] = nil
                    end
                end
            end
        end
        
        doorSet.locked = locked
    end
end)

function GetDoorCoords(doorData)
    if doorData.coords then
        return doorData.coords
    end
    
    local pos1, pos2
    if doorData[1].x then
        pos1 = doorData[1]
        pos2 = doorData[2]
    else
        pos1 = doorData[1].coords
        pos2 = doorData[2].coords
    end
    
    return vector3((pos1.x + pos2.x) / 2, (pos1.y + pos2.y) / 2, (pos1.z + pos2.z) / 2)
end