-- Police Shapes System (Zones/Areas)
-- Stores all police-defined shapes (zones, areas, markers)
local shapes = {}

-- Load all shapes from database on resource start
CreateThread(function()
    local result = MySQL.awaitQuery("SELECT id, type, title, data, radius FROM origen_police_shapes")
    
    for i = 1, #result do
        if result[i] then
            local shapeId = result[i].id
            
            shapes[shapeId] = {
                type = result[i].type,
                title = result[i].title,
                data = json.decode(result[i].data),
                radius = result[i].radius,
                id = result[i].id
            }
        end
    end
end)

-- Update Shapes (Create/Delete)
FW_CreateCallback("origen_police:callback:UpdateShapes", function(source, callback, data)
    local success = false
    local playersToNotify = {}
    
    if data.action == "create" then
        local shape = data.shape
        
        -- Insert shape into database
        local insertId = MySQL.awaitInsert(
            "INSERT INTO origen_police_shapes (type, title, data, radius) VALUES (?, ?, ?, ?)",
            {
                shape.type,
                shape.title,
                json.encode(shape.data),
                shape.radius
            }
        )
        
        -- Store shape in memory
        shapes[insertId] = {
            type = shape.type,
            title = shape.title,
            data = shape.data,
            radius = shape.radius,
            id = insertId
        }
        
        success = insertId
        
        -- Create log entry
        CreateLog({
            type = "Shapes",
            embed = {
                title = Config.LogsTranslations.CreateShape.title,
                description = Config.LogsTranslations.CreateShape.message:format(shapes[insertId].title),
                color = 1791423
            },
            source = source
        })
        
    elseif data.action == "delete" then
        local shapeId = data.id
        
        if shapes[shapeId] then
            -- Create log entry before deletion
            CreateLog({
                type = "Shapes",
                embed = {
                    title = Config.LogsTranslations.DeleteShape.title,
                    description = Config.LogsTranslations.DeleteShape.message:format(shapes[shapeId].title),
                    color = 1791423
                },
                source = source
            })
            
            -- Delete from database
            local result = MySQL.awaitQuery(
                "DELETE FROM origen_police_shapes WHERE id = ?",
                { shapeId }
            )
            
            if result.affectedRows > 0 then
                shapes[shapeId] = nil
                success = true
            end
        end
    end
    
    -- Get all players to notify about shape changes
    local jobCategory = CanOpenTablet(source)[2]
    
    if Config.Framework == "qbcore" then
        -- Get all QBCore players on duty
        for _, job in pairs(Config.JobCategory[jobCategory]) do
            local onDutyPlayers = Framework.Functions.GetPlayersOnDuty(job.name)
            
            for i = 1, #onDutyPlayers do
                table.insert(playersToNotify, onDutyPlayers[i])
            end
        end
    elseif Config.Framework == "esx" then
        -- Get all ESX players on duty
        playersToNotify = GetPlayersInDuty(jobCategory)
    end
    
    -- Notify all on-duty players to reload shapes
    for i = 1, #playersToNotify do
        TriggerClientEvent("origen_police:client:ReloadShapes", playersToNotify[i])
    end
    
    callback(success)
end)

-- Get All Shapes
FW_CreateCallback("origen_police:callback:GetShapes", function(source, callback)
    local allShapes = {}
    
    -- Copy shapes table
    for id, shape in pairs(shapes) do
        allShapes[id] = shape
    end
    
    callback(allShapes)
end)