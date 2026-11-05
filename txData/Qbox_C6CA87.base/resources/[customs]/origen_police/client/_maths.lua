-- Math Utility Functions

-- Get the length of a table
function GetTableLength(table)
    if table == nil then
        return 0
    end
    
    local count = 0
    for _ in pairs(table) do
        count = count + 1
    end
    
    return count
end

-- Check if a point is inside a polygon
function isInside(polygon, x, y)
    local function crossProduct(x1, y1, x2, y2, x3, y3)
        return (x1 - x3) * (y2 - y3) - (x2 - x3) * (y1 - y3)
    end
    
    local signs = {}
    
    for i = 1, #polygon do
        local nextIndex = (i % #polygon) + 1
        local cross = crossProduct(
            x, y,
            polygon[i][1], polygon[i][2],
            polygon[nextIndex][1], polygon[nextIndex][2]
        )
        signs[i] = cross < 0
    end
    
    -- Check if all signs are the same
    for i = 2, #signs do
        if signs[i] ~= signs[1] then
            return false
        end
    end
    
    return true
end

-- Draw a wall between two points
function DrawWall(point1, point2, minZ, maxZ, red, green, blue, alpha)
    local v1 = vector3(point1.x, point1.y, minZ)
    local v2 = vector3(point1.x, point1.y, maxZ)
    local v3 = vector3(point2.x, point2.y, minZ)
    local v4 = vector3(point2.x, point2.y, maxZ)
    
    -- Draw the wall using multiple polygons
    DrawPoly(v1, v2, v3, red, green, blue, alpha)
    DrawPoly(v2, v4, v3, red, green, blue, alpha)
    DrawPoly(v3, v4, v2, red, green, blue, alpha)
    DrawPoly(v3, v2, v1, red, green, blue, alpha)
end

-- Draw 3D text at a world position
function Draw3DText(x, y, z, scale, text)
    local onScreen, screenX, screenY = World3dToScreen2d(x, y, z)
    local camCoords = GetGameplayCamCoords()
    local distance = GetDistanceBetweenCoords(camCoords.x, camCoords.y, camCoords.z, x, y, z, 1)
    
    local fov = GetGameplayCamFov()
    local scaleMultiplier = (1 / distance) * 2 * (1 / fov) * 100 * scale
    
    if onScreen then
        SetTextScale(0.0, scaleMultiplier)
        SetTextFont(0)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 255)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(screenX, screenY)
    end
end