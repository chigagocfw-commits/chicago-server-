local sharedConfig = require 'config.shared'

local ox_inventory = exports.ox_inventory
local MAX_MUGSHOT_LENGTH = 512 * 1024
local FALLBACK_MUGSHOT = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg=='

-- Base64 decoding lookup table
local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
local b64lookup = {}
for i = 1, #b64chars do
    b64lookup[b64chars:sub(i, i)] = i - 1
end

---Decode a Base64 string into binary data
---@param data string
---@return string|nil
local function decodeBase64(data)
    if type(data) ~= 'string' or #data == 0 then return nil end
    local clean = data:gsub('%s+', '')
    local len = #clean
    if len % 4 ~= 0 then return nil end

    local out = {}
    local outLen = 0

    for i = 1, len, 4 do
        local c1 = clean:sub(i, i)
        local c2 = clean:sub(i + 1, i + 1)
        local c3 = clean:sub(i + 2, i + 2)
        local c4 = clean:sub(i + 3, i + 3)

        local b1 = b64lookup[c1]
        local b2 = b64lookup[c2]
        if not b1 or not b2 then return nil end

        local b3 = (c3 ~= '=') and b64lookup[c3] or 0
        local b4 = (c4 ~= '=') and b64lookup[c4] or 0
        if (c3 ~= '=' and not b64lookup[c3]) or (c4 ~= '=' and not b64lookup[c4]) then
            return nil
        end

        local n = (b1 << 18) | (b2 << 12) | (b3 << 6) | b4
        outLen = outLen + 1
        out[outLen] = string.char((n >> 16) & 0xFF)

        if c3 ~= '=' then
            outLen = outLen + 1
            out[outLen] = string.char((n >> 8) & 0xFF)
        end
        if c4 ~= '=' then
            outLen = outLen + 1
            out[outLen] = string.char(n & 0xFF)
        end
    end

    return table.concat(out)
end

---Validate PNG binary data: signature, IHDR chunk, and dimensions <= 1024x1024
---@param bin string
---@return boolean
local function isValidPngData(bin)
    if type(bin) ~= 'string' or #bin < 33 then return false end

    -- PNG signature: 137 80 78 71 13 10 26 10
    if bin:sub(1, 8) ~= '\137PNG\r\n\026\n' then return false end

    -- IHDR length must be 13 (bytes 9-12)
    local len = string.unpack('>I4', bin, 9)
    if len ~= 13 then return false end

    -- Chunk type must be 'IHDR' (bytes 13-16)
    if bin:sub(13, 16) ~= 'IHDR' then return false end

    -- Width and height (bytes 17-20 and 21-24)
    local width, height = string.unpack('>I4>I4', bin, 17)
    if not width or not height or width <= 0 or height <= 0 then return false end

    -- Strict dimension and pixel caps to defeat decompression bombs
    if width > 1024 or height > 1024 or (width * height) > (1024 * 1024) then
        return false
    end

    return true
end

---Validate a mugshot data URI
---@param mugShot any
---@return boolean
local function isValidMugShot(mugShot)
    if type(mugShot) ~= 'string' or #mugShot > MAX_MUGSHOT_LENGTH then
        return false
    end

    local b64data = mugShot:match('^data:image/png;base64,(.+)$')
    if not b64data then
        -- Also check generic image base64 prefix
        b64data = mugShot:match('^data:image/[%w.+-]+;base64,(.+)$')
    end
    if not b64data or #b64data == 0 then return false end

    local bin = decodeBase64(b64data)
    if not bin then return false end

    return isValidPngData(bin)
end

---Capture mugshot and update ox_inventory slot metadata
---@param src number
---@param itemName string
---@return table|nil updatedMetadata
local function newMetaDataLicense(src, itemName)
    local ok, inventoryItems = pcall(function()
        return ox_inventory:Search(src, 1, itemName)
    end)
    if not ok or not inventoryItems then return nil end

    local _, inventoryItem = next(inventoryItems)
    if not inventoryItem then return nil end

    local mugShot = nil
    local cbOk, cbRes = pcall(function()
        return lib.callback.await('um-idcard:client:callBack:getMugShot', src)
    end)
    if cbOk and isValidMugShot(cbRes) then
        mugShot = cbRes
    else
        mugShot = FALLBACK_MUGSHOT
    end

    local slotItem = ox_inventory:GetSlot(src, inventoryItem.slot)
    if not slotItem or slotItem.name ~= itemName then return nil end

    local metadata = slotItem.metadata or {}
    metadata.mugShot = mugShot

    pcall(function()
        ox_inventory:SetMetadata(src, slotItem.slot, metadata)
    end)

    return metadata
end

---Check if target is a nearby player in the same routing bucket (<= 3.0m)
---@param src number
---@param target number
---@return boolean
local function isNearbyPlayer(src, target)
    if math.type(target) ~= 'integer' or target <= 0 or target == src or not GetPlayerName(target) then return false end
    if GetPlayerRoutingBucket(src) ~= GetPlayerRoutingBucket(target) then return false end

    local playerPed = GetPlayerPed(src)
    local targetPed = GetPlayerPed(target)
    if playerPed <= 0 or targetPed <= 0 then return false end

    return #(GetEntityCoords(playerPed) - GetEntityCoords(targetPed)) <= 3.0
end

---Send ID card data for viewing
---@param src number
---@param item string
---@param metadata table
local function sendData(src, item, metadata)
    if type(src) ~= 'number' or not GetPlayerName(src) then return end
    if type(item) ~= 'string' or not sharedConfig.licenses[item] then return end
    metadata = type(metadata) == 'table' and metadata or {}

    -- If mugshot is missing or invalid, generate it immediately and update metadata
    if not isValidMugShot(metadata.mugShot) then
        local updated = newMetaDataLicense(src, item)
        if updated then
            metadata = updated
        else
            metadata.mugShot = FALLBACK_MUGSHOT
        end
    end

    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    -- Authoritative card owner identity: preserve stored metadata if present; fallback to caller only for legacy cards
    local citizenid = metadata.citizenid or player.PlayerData.citizenid
    local firstname = metadata.firstname or player.PlayerData.charinfo.firstname
    local lastname  = metadata.lastname  or player.PlayerData.charinfo.lastname
    local birthdate = metadata.birthdate or player.PlayerData.charinfo.birthdate
    local nationality = metadata.nationality or player.PlayerData.charinfo.nationality

    local rawSex = metadata.sex
    local sex = 'Male'
    if rawSex == 'F' or rawSex == 'Female' or rawSex == 1 then
        sex = 'Female'
    elseif rawSex == 'M' or rawSex == 'Male' or rawSex == 0 then
        sex = 'Male'
    elseif player.PlayerData.charinfo.gender == 1 then
        sex = 'Female'
    end

    local payload = {
        citizenid = citizenid,
        firstname = firstname,
        lastname = lastname,
        birthdate = birthdate,
        sex = sex,
        nationality = nationality,
        cardtype = item,
        mugShot = metadata.mugShot or FALLBACK_MUGSHOT,
        badge = metadata.badge,
    }

    lib.callback('um-idcard:client:callBack:getClosestPlayer', src, function(target)
        if not GetPlayerName(src) then return end

        target = tonumber(target)
        if target and isNearbyPlayer(src, target) then
            TriggerClientEvent('um-idcard:client:notifyOx', src, {
                title = 'You showed your idcard',
                desc = 'You are showing your ID Card to the closest player',
                icon = 'id-card',
                iconColor = 'green'
            })
            -- Display to both the recipient and the sender so sender sees what is shown
            TriggerClientEvent('um-idcard:client:sendData', target, payload)
            TriggerClientEvent('um-idcard:client:sendData', src, payload)
        else
            -- Self view
            TriggerClientEvent('um-idcard:client:sendData', src, payload)
        end
    end)

    TriggerClientEvent('um-idcard:client:startAnim', src, item)
end

AddEventHandler('um-idcard:server:sendData', sendData)

for k, _ in pairs(sharedConfig.licenses) do
    CreateRegisterItem(k)
end
