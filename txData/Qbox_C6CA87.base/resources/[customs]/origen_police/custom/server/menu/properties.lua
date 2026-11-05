local ApartmentStructure = {
    ["qbx_properties"] = {
        func = function(citizenid)
            -- Query properties owned by this citizen
            local properties = MySQL.awaitQuery('SELECT property_name, coords FROM properties WHERE owner = ?', {citizenid})
            local result = {}
            if properties then
                for _, property in pairs(properties) do
                    table.insert(result, { 
                        data = property.property_name,
                        label = property.property_name 
                    })
                end
            end
            return result
        end
    },
    ["qs-housing"] = {
        table = "player_houses",
        label = "house",
        identifier = "owner"
    },
    ["origen_housing"] = {
        func = function(citizenid)
            local houses = exports.origen_housing:getOwnedHouses(citizenid)
            local result = {}
            if houses then
                for _, houseID in pairs(houses) do
                    local house = exports['origen_housing']:getHouse(houseID)
                    if type(house) == 'table' then
                        table.insert(result, { label = house.name })
                    end
                end
            end
            return result
        end
    },
    ["esx_property"] = {
        func = function(citizenid)
            local houses = exports['esx_property']:GetPlayerProperties(citizenid)
            local result = {}
            if houses then
                for _, house in pairs(houses) do
                    table.insert(result, { label = prop.Name or prop.label })
                end
            end
            return result
        end
    },
    ["default"] = {
        ["qbcore"] = {
            func = function(citizenid)
                -- Check if qbx_properties is available
                if GetResourceState('qbx_properties') == 'started' then
                    -- Use qbx_properties if available
                    local properties = MySQL.awaitQuery('SELECT property_name FROM properties WHERE owner = ?', {citizenid})
                    local result = {}
                    if properties then
                        for _, property in pairs(properties) do
                            table.insert(result, { 
                                data = property.property_name,
                                label = property.property_name 
                            })
                        end
                    end
                    return result
                else
                    -- Return empty array if no housing system is configured
                    return {}
                end
            end
        },
        ["esx"] = {
            table = "users",
            label = "last_property",
            identifier = "identifier"
        }
    }
}

-- DON'T TOUCH ANYTHING BELOW THIS LINE UNLESS YOU KNOW WHAT YOU'RE DOING
-- NO SUPPORT WILL BE PROVIDED FOR CHANGES MADE BELOW THIS LINE

ApartmentStructure = ParseScriptStructure(ApartmentStructure, Config.HousingSystem, 1)

function GetCitizenProperties(citizenid)
    return GetDataFromStructure(ApartmentStructure, true, 300, 1, citizenid, {})
end