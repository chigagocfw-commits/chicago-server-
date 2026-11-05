Editable = {}

local databaseTables = {
    [[
    CREATE TABLE IF NOT EXISTS lunar_contracts (
        id INT AUTO_INCREMENT PRIMARY KEY,
        data LONGTEXT,
        extra_data LONGTEXT
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]],
    [[
    CREATE TABLE IF NOT EXISTS lunar_contracts_profiles (
        identifier VARCHAR(50) PRIMARY KEY,
        username VARCHAR(255) NOT NULL UNIQUE,
        image VARCHAR(255),
        firstLogin INT,
        completedContracts INT,
        lastActive INT,
        crypto INT,
        xp INT
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
    ]]
}

MySQL.ready(function()
    for i = 1, #databaseTables do
        MySQL.query.await(databaseTables[i])
    end
end)

-- Only works if Config.overrideCrypto is true 
function Editable.getPlayerCrypto(identifier)
    -- Add your export here
end

-- Only works if Config.overrideCrypto is true 
function Editable.addPlayerCrypto(identifier, amount)
    -- Add your export here
end

-- Only works if Config.overrideCrypto is true 
function Editable.removePlayerCrypto(identifier, amount)
    -- Add your export here
end

-- Only works if Config.overrideExperience is true 
function Editable.getPlayerExperience(identifier)
    -- Add your export here
end

-- Only works if Config.overrideExperience is true 
function Editable.addPlayerExperience(identifier, amount)
    -- Add your export here
end

-- Only works if Config.overrideExperience is true 
function Editable.removePlayerExperience(identifier, amount)
    -- Add your export here
end

---@param source number
---@return boolean
function Editable.customTabletCheck(source)
    -- Replace with your own logic
    return true
end

--[[
    HEIST COMPLETION EVENT
    
    The 'lunar_contracts:heistCompleted' event is triggered when a heist is successfully completed.
    You can listen to this event in your bridge or other scripts to perform additional actions.
    
    Event Parameters:
        @param contractIndex (integer) - The index of the completed contract
        @param contractName (string) - The name of the contract (e.g., 'fleeca', 'pacific', 'house', etc.)
        @param owner (string) - The identifier of the contract owner
        @param members (table) - Array of identifiers of all members who participated
    
    Example Usage:
        AddEventHandler('lunar_contracts:heistCompleted', function(contractIndex, contractName, owner, members)
            print(('Heist "%s" completed by %s with %d members'):format(contractName, owner, #members))
            
            -- Add your custom logic here
            -- Examples:
            -- - Send Discord webhook notification
            -- - Award additional items or currency
            -- - Update custom statistics
            -- - Trigger other events in your framework
        end)
]]

AddEventHandler('lunar_contracts:heistCompleted', function(contractIndex, contractName, owner, members)
    print(('[lunar_contracts] Heist "%s" (index %d) completed | Owner: %s | Members: %d'):format(
        contractName, contractIndex, owner, #members
    ))
end)