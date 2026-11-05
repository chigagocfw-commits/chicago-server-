-- =====================================================
--  Fixed by https://discord.gg/6NCbAv2VNK Reddev Development  
--  Cleaned By Reddev Using Codex 5.5 
--  Files Provided From anon_fort
-- =====================================================

-- =====================================================
--  Fixed by Reddev Development
--  Support: https://discord.gg/MJH5zX7NSg
--  Cleaned By Reddev Using Codex 5.5
--  Files Provided From Rip_Bytecode
-- =====================================================
-- Prompts Main Module
-- Handles 3D prompt rendering and interaction point management

local Prompt = GetPrompt()
local currentPoint = nil

-- Configuration
local renderDistance = Config.Prompts.RenderDistance
local spriteDict = Config.Prompts.Dict or "prompt"
local spriteWidth = Config.Prompts.SpriteSize
local spriteHeight = Config.Prompts.SpriteSize * GetAspectRatio(false)
local spriteR = Config.Prompts.SpriteColor.r
local spriteG = Config.Prompts.SpriteColor.g
local spriteB = Config.Prompts.SpriteColor.b
local spriteA = Config.Prompts.SpriteColor.a or 255

-- Entity tracking
local entities = {}
local entityIdCounter = 0

--[[
    Add an entity to tracking
    @param entityData - Entity data object
    @return number - Entity ID
--]]
function AddEntity(entityData)
    entityIdCounter = entityIdCounter + 1
    entities[entityIdCounter] = entityData
    return entityIdCounter
end

--[[
    Remove an entity from tracking
    @param entityId - Entity ID to remove
--]]
function RemoveEntity(entityId)
    entities[entityId] = nil
end

-- Point alpha values for fade effect
local pointAlphas = {}

-- Visibility cache
local visibilityCache = {}

local function isFunctionReference(value)
    return type(value) == "table" and rawget(value, "__cfx_functionReference") ~= nil
end

local function isCallable(value)
    return type(value) == "function" or isFunctionReference(value)
end

local function normalizeCoords(coords)
    if not coords then
        return nil
    end

    if coords.xyz then
        coords = coords.xyz
    end

    if coords.x and coords.y and coords.z then
        return coords
    end

    return nil
end

local function resolvePointCoords(point)
    if not point then
        return nil
    end

    local coords = normalizeCoords(point.coords)

    if not coords and isCallable(point.getCoords) then
        local success, result = pcall(point.getCoords)

        if success then
            coords = normalizeCoords(result)
        end
    end

    if not coords and point.entity and DoesEntityExist(point.entity) then
        coords = GetEntityCoords(point.entity)
    end

    return normalizeCoords(coords)
end

--[[
    Check if a point has any valid interaction options
    @param point - The point to check
    @return boolean - True if point can be interacted with
--]]
local function canInteractWithPoint(point)
    -- Validate point exists and has required properties
    if not point then
        return false
    end
    
    -- Check valid flag (if it exists)
    if point.valid ~= nil and not point.valid then
        return false
    end
    
    -- Ensure options table exists
    if not point.options or type(point.options) ~= "table" then
        return false
    end
    
    -- Check if any option can be interacted with
    for _, option in ipairs(point.options) do
        if type(option) == "table" then
            local canInteract = true
            
            if isCallable(option.canInteract) then
                local success, result = pcall(option.canInteract)
                canInteract = success and result
            elseif type(option.canInteractEvent) == "string" then
                local context = {
                    args = option.args,
                    allowed = true
                }

                TriggerEvent(option.canInteractEvent, context)
                canInteract = context.allowed ~= false
            end
            
            if canInteract then
                return true
            end
        end
    end
    
    return false
end

local function getSelectableDistance(point)
    return math.max(point.distance or point.radius or 0.0, renderDistance)
end

--[[
    Update the current interaction point
    @param newPoint - The new point to set as current
--]]
local function updateCurrentPoint(newPoint)
    Prompt.hide()
    Wait(200)
    
    if not newPoint then
        return
    end
    
    Prompt.setOptions(newPoint.options)
    
    SetTimeout(200, function()
        if currentPoint == newPoint then
            Prompt.setIndex(1)
        end
    end)
    
    SetTimeout(300, function()
        if currentPoint == newPoint then
            Prompt.show()
        end
    end)
end

-- Nearby points for rendering
local textureLoaded = nil
local nearbyPoints = {}

-- Thread: Find closest interaction point
CreateThread(function()
    while true do
        -- Ensure texture is loaded
        if not textureLoaded then
            textureLoaded = lib.requestStreamedTextureDict(spriteDict)
        end
        
        local closest = { dist = math.huge }
        
        -- Check lib.points
        for _, point in pairs(lib.points.getAllPoints()) do
            if point.options and point.dist and point.dist < getSelectableDistance(point) then
                if point.dist < closest.dist then
                    if canInteractWithPoint(point) then
                        closest.point = point
                        closest.dist = point.dist
                    end
                end
            end
        end
        
        -- Check tracked entities
        for _, entity in pairs(entities) do
            local dist = entity.dist
            local radius = getSelectableDistance(entity)
            
            if dist and dist < radius then
                if dist < closest.dist then
                    if canInteractWithPoint(entity) then
                        closest.point = entity
                        closest.dist = dist
                    end
                end
            end
        end
        
        -- Update current point if changed
        if currentPoint ~= closest.point then
            updateCurrentPoint(closest.point)
        end
        
        currentPoint = closest.point
        
        -- Update options if we have a current point
        if currentPoint then
            Prompt.updateOptions()
        end
        
        -- Adjust wait time based on nearby points
        Wait(#nearbyPoints == 0 and 1000 or 100)
    end
end)

-- Thread: Update point distances
CreateThread(function()
    while true do
        table.wipe(nearbyPoints)
        
        local playerCoords = GetEntityCoords(cache.ped)
        
        -- Update lib.points distances
        for _, point in pairs(lib.points.getAllPoints()) do
            local pointCoords = resolvePointCoords(point)

            if pointCoords then
                point.dist = #(playerCoords - pointCoords)
                
                if point.options and point.dist < renderDistance * 2 then
                    table.insert(nearbyPoints, point)
                    
                    if not pointAlphas[point] then
                        pointAlphas[point] = 0
                    end
                    
                    visibilityCache[point] = canInteractWithPoint(point)
                else
                    pointAlphas[point] = nil
                    visibilityCache[point] = nil
                end
            else
                point.dist = math.huge
                pointAlphas[point] = nil
                visibilityCache[point] = nil
            end
        end
        
        -- Update entity distances
        for entityId, entity in pairs(entities) do
            if not entity or entity.valid == false or not entity.entity or not DoesEntityExist(entity.entity) then
                if entity then
                    pointAlphas[entity] = nil
                    visibilityCache[entity] = nil
                end

                RemoveEntity(entityId)
            else
                local entityCoords = resolvePointCoords(entity)

                if entityCoords then
                    entity.dist = #(playerCoords - entityCoords)
                    
                    if entity.dist < renderDistance * 2 then
                        table.insert(nearbyPoints, entity)
                        
                        if not pointAlphas[entity] then
                            pointAlphas[entity] = 0
                        end
                        
                        visibilityCache[entity] = canInteractWithPoint(entity)
                    else
                        pointAlphas[entity] = nil
                        visibilityCache[entity] = nil
                    end
                else
                    entity.dist = math.huge
                    pointAlphas[entity] = nil
                    visibilityCache[entity] = nil
                end
            end
        end
        
        -- Sort by distance
        table.sort(nearbyPoints, function(a, b)
            return (a.dist or math.huge) < (b.dist or math.huge)
        end)
        
        Wait(300)
    end
end)

-- Thread: Update point alpha values
CreateThread(function()
    while true do
        if #nearbyPoints == 0 then
            Wait(200)
        end
        
        for i = 1, #nearbyPoints do
            local point = nearbyPoints[i]
            local isVisible = visibilityCache[point]
            local alpha = pointAlphas[point] or 0
            
            if isVisible and point.dist <= renderDistance then
                -- Fade in
                if alpha < spriteA then
                    pointAlphas[point] = alpha + 30
                end
            else
                -- Fade out
                if alpha > 0 then
                    pointAlphas[point] = alpha - 30
                end
            end
            
            -- Clamp values
            if pointAlphas[point] < 0 then
                pointAlphas[point] = 0
            end
            
            if pointAlphas[point] > spriteA then
                pointAlphas[point] = spriteA
            end
        end
        
        Wait(20)
    end
end)

-- Thread: Render prompts
CreateThread(function()
    while true do
        if #nearbyPoints == 0 then
            Wait(200)
        end
        
        -- Render up to 32 nearby points
        local renderCount = math.min(#nearbyPoints, 32)
        
        for i = 1, renderCount do
            local point = nearbyPoints[i]
            local coords = resolvePointCoords(point)

            if coords then
                SetDrawOrigin(coords.x, coords.y, coords.z)
                
                if point == currentPoint then
                    -- Draw full prompt UI for current point
                    Prompt.draw()
                else
                    -- Draw sprite for other points
                    local alpha = pointAlphas[point] or 0

                    if alpha > 0 then
                        DrawSprite(
                            spriteDict,
                            "point",
                            0.0, 0.0,
                            spriteWidth, spriteHeight,
                            0.0,
                            spriteR, spriteG, spriteB,
                            alpha
                        )
                    end
                end
            end
        end
        
        if currentPoint and (
            IsControlJustPressed(0, 38)
            or IsDisabledControlJustPressed(0, 38)
            or IsControlJustReleased(0, 38)
            or IsDisabledControlJustReleased(0, 38)
        ) then
            Prompt.setOptions(currentPoint.options or {})
            Prompt.updateOptions()
            Prompt.selectCurrentOption()
        end

        ClearDrawOrigin()
        Wait(0)
    end
end)

