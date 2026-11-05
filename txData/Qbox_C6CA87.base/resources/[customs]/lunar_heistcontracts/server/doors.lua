local doors = {}

lib.callback.register("lunar_contracts:getDoors", function()
    return doors
end)

function RegisterDoors(doorConfigs)
    local startIndex = #doors
    
    for i, doorGroup in ipairs(doorConfigs) do
        local doorList
        if type(doorGroup) ~= "table" then
            doorList = { { coords = doorGroup } }
        elseif doorGroup.model or doorGroup.coords then
            doorList = { doorGroup }
        else
            doorList = doorGroup
        end
        
        local index = #doors + 1
        
        doors[index] = {
            doors = {},
            locked = true
        }
        
        for j, door in ipairs(doorList) do
            local doorHash = joaat(string.format("contracts_door_%s_%s", index, j))
            
            doors[index].doors[j] = {
                coords = door.coords,
                model = door.model,
                hash = doorHash
            }
        end
    end
    
    local controller = {}
    
    function controller.set(self, doorIndex, locked)
        if doorIndex <= 0 or doorIndex > #doorConfigs then return end
        
        local actualIndex = startIndex + doorIndex
        doors[actualIndex].locked = locked
        TriggerClientEvent("lunar_contracts:setDoorState", -1, actualIndex, locked)
    end
    
    function controller.get(self, doorIndex)
        if doorIndex <= 0 or doorIndex > #doorConfigs then return end
        
        local actualIndex = startIndex + doorIndex
        return doors[actualIndex].locked
    end
    
    function controller.setAll(self, locked)
        for i = startIndex + 1, startIndex + #doorConfigs do
            doors[i].locked = locked
        end
        
        TriggerClientEvent("lunar_contracts:setMultipleDoorState", -1, startIndex + 1, startIndex + #doorConfigs, locked)
    end
    
    return controller
end

function RegisterDoorsWithModel(coords, model)
    local doorList = {}
    for i, coord in ipairs(coords) do
        doorList[i] = { coords = coord, model = model }
    end
    return RegisterDoors(doorList)
end

function RegisterDoorWithModel(coords, model)
    local doorList = type(coords) == "table" and coords or { coords }
    local formattedList = {}
    
    for i, coord in ipairs(doorList) do
        formattedList[i] = { coords = coord, model = model }
    end
    
    local controller = RegisterDoors(formattedList)
    
    return {
        set = function(locked)
            controller:set(1, locked)
        end,
        get = function()
            return controller:get(1)
        end
    }
end

function RegisterDoor(coords)
    local doorList = { { coords = coords } }
    local controller = RegisterDoors(doorList)
    
    return {
        set = function(locked)
            controller:set(1, locked)
        end,
        get = function()
            return controller:get(1)
        end
    }
end

function GetDoorCoords(door)
    if type(door) == "vector3" or type(door) == "vector4" then
        return door.xyz or door
    end
    
    if door.coords then
        return vector3(door.coords.x, door.coords.y, door.coords.z)
    end
    
    if door.x and door.y and door.z then
        return vector3(door.x, door.y, door.z)
    end
    
    if door[1] then
        local pos1 = (type(door[1]) == "table") and (door[1].coords or door[1]) or door[1]
        local pos2 = (type(door[2]) == "table") and (door[2].coords or door[2]) or door[2]
        
        return vector3(
            (pos1.x + pos2.x) / 2,
            (pos1.y + pos2.y) / 2,
            (pos1.z + pos2.z) / 2
        )
    end
    
    return vector3(0, 0, 0)
end