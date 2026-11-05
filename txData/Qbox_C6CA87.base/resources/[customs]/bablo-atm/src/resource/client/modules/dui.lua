local function drawTexturedPoly(a, b, c, texture, uvA, uvB, uvC)
    DrawTexturedPoly(
        a.x, a.y, a.z,
        b.x, b.y, b.z,
        c.x, c.y, c.z,
        255, 255, 255, 255,
        texture.dictionary,
        texture.texture,
        uvA[1], uvA[2], 0.0,
        uvB[1], uvB[2], 0.0,
        uvC[1], uvC[2], 0.0
    )
end

function DrawRectangle(texture, points, widthScale, heightScale, doubleSided)
    local topLeft = points.topLeft
    local bottomLeft = points.bottomLeft
    local bottomRight = points.bottomRight
    local topRight = points.topRight

    widthScale = widthScale or 1.0
    heightScale = heightScale or 1.0
    doubleSided = doubleSided or false

    if doubleSided then
        drawTexturedPoly(bottomLeft, topLeft, bottomRight, texture, { 0.0, heightScale }, { 0.0, 0.0 }, { widthScale, heightScale })
        drawTexturedPoly(topLeft, topRight, bottomRight, texture, { 0.0, 0.0 }, { widthScale, 0.0 }, { widthScale, heightScale })
    end

    drawTexturedPoly(topLeft, bottomLeft, bottomRight, texture, { 0.0, 0.0 }, { 0.0, heightScale }, { widthScale, heightScale })
    drawTexturedPoly(topRight, topLeft, bottomRight, texture, { widthScale, 0.0 }, { 0.0, 0.0 }, { widthScale, heightScale })
end

DUI = DUI or {}
DUI.__index = DUI

function DUI.new(_, options)
    options = options or {}

    return setmetatable({
        object = nil,
        handle = nil,
        points = nil,
        txd = nil,
        txn = nil,
        txdName = options.txdName or "bablo_atm_dui",
        txnName = options.txName or "atm_screen",
    }, DUI)
end

function DUI:Draw()
    if not self.object or type(self.points) ~= "table" then
        return
    end

    DrawRectangle({
        dictionary = self.txdName,
        texture = self.txnName,
    }, self.points, nil, nil, false)
end

function DUI:CreateRuntimeTexture()
    if not self.handle then
        Error("Cannot create runtime texture: DUI handle is nil")
        return false
    end

    Debug("Creating runtime texture for DUI handle: " .. tostring(self.handle))

    self.txdName = ("bablo_atm_%s"):format(self.handle)
    self.txnName = ("atm_screen_%s"):format(self.handle)
    self.txd = CreateRuntimeTxd(self.txdName)

    if not self.txd then
        Error("Failed to create runtime TXD")
        return false
    end

    local duiHandle = GetDuiHandle(self.handle)
    if not duiHandle or duiHandle == "" then
        Error("Failed to get DUI handle or handle is empty")
        return false
    end

    local ok, texture = pcall(function()
        return CreateRuntimeTextureFromDuiHandle(self.txd, self.txnName, duiHandle)
    end)

    if not ok then
        Error("CreateRuntimeTextureFromDuiHandle failed: " .. tostring(texture))
        return false
    end

    self.txn = texture
    if not self.txn then
        Error("Failed to create runtime texture from DUI handle")
        return false
    end

    Debug("Successfully created runtime texture: " .. tostring(self.txn))
    return true
end

function DUI:Create(url, resolution)
    if not url or not resolution then
        return false
    end

    self.handle = CreateDui(url, resolution.x, resolution.y)
    if not self.handle then
        Error("Failed to create DUI handle")
        return false
    end

    return true
end

function DUI:Destroy()
    if self.handle then
        DestroyDui(self.handle)
        self.handle = nil
    end

    self.txd = nil
    self.txn = nil
end

function DUI:SendMessage(action, data)
    if not self.handle then
        return
    end

    SendDuiMessage(self.handle, json.encode({
        action = action,
        data = data,
    }))
end

function DUI:SetPoints(entity, variant)
    if not DoesEntityExist(entity) or not variant then
        return false
    end

    local entityCoords = GetEntityCoords(entity)
    local forwardVector = GetEntityForwardVector(entity)
    local upVector = vector3(0.0, 0.0, 1.0)
    local rightVector = vector3(forwardVector.y, forwardVector.x, 0.0)

    local width = 0.4
    local height = 0.25
    local forwardOffset = 0.22
    local verticalOffset = 1.05

    if variant.uiType == "fleeca" or variant.uiType == "two" then
        width = 0.38
        height = 0.24
        forwardOffset = 0.2
        verticalOffset = 1.02
    elseif variant.uiType == "three" then
        width = 0.36
        height = 0.22
        forwardOffset = 0.18
        verticalOffset = 1.0
    end

    local center = entityCoords + (forwardVector * forwardOffset) + (upVector * verticalOffset)
    local halfWidth = width / 2
    local halfHeight = height / 2

    self.points = {
        topLeft = center + (upVector * halfHeight) - (rightVector * halfWidth),
        topRight = center + (upVector * halfHeight) + (rightVector * halfWidth),
        bottomLeft = center - (upVector * halfHeight) - (rightVector * halfWidth),
        bottomRight = center - (upVector * halfHeight) + (rightVector * halfWidth),
    }
    self.object = entity

    return true
end

function DUI:IsValid()
    return self.handle ~= nil and self.object ~= nil and DoesEntityExist(self.object)
end

function DUI:GetCursor()
    if not self.handle then
        return 0, 0
    end

    return GetControlNormal(0, 239), GetControlNormal(0, 240)
end

function DUI:GetDebugInfo()
    if not self:IsValid() or not self.points then
        return nil
    end

    local atmCoords = GetEntityCoords(self.object)
    local atmModel = GetEntityModel(self.object)
    local cursorX, cursorY = self:GetCursor()
    local _, topLeftX, topLeftY = GetScreenCoordFromWorldCoord(
        self.points.topLeft.x,
        self.points.topLeft.y,
        self.points.topLeft.z
    )
    local _, bottomRightX, bottomRightY = GetScreenCoordFromWorldCoord(
        self.points.bottomRight.x,
        self.points.bottomRight.y,
        self.points.bottomRight.z
    )

    return {
        atmModel = atmModel,
        atmCoords = atmCoords,
        cursorX = cursorX,
        cursorY = cursorY,
        screenBounds = {
            topLeft = {
                x = topLeftX or 0,
                y = topLeftY or 0,
            },
            bottomRight = {
                x = bottomRightX or 0,
                y = bottomRightY or 0,
            },
        },
        worldBounds = {
            topLeft = self.points.topLeft,
            bottomRight = self.points.bottomRight,
        },
    }
end
