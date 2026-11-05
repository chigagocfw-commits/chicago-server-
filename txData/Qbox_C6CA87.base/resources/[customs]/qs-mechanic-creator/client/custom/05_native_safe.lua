-- Guard native che crashano con nil (decompilato leak) — carica prima dei modules

local _SetFocusPosAndVel = SetFocusPosAndVel
function SetFocusPosAndVel(x, y, z, vx, vy, vz)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return end
    vx = tonumber(vx) or 0.0
    vy = tonumber(vy) or 0.0
    vz = tonumber(vz) or 0.0
    return _SetFocusPosAndVel(x, y, z, vx, vy, vz)
end

local _SetEntityCoordsNoOffset = SetEntityCoordsNoOffset
function SetEntityCoordsNoOffset(entity, x, y, z, a, b, c)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not x or not y or not z then return end
    if not entity or entity == 0 then return end
    return _SetEntityCoordsNoOffset(entity, x, y, z, a, b, c)
end

local _SetEntityHeading = SetEntityHeading
function SetEntityHeading(entity, heading)
    heading = tonumber(heading)
    if not heading or not entity or entity == 0 then return end
    return _SetEntityHeading(entity, heading)
end

local _SetCamCoord = SetCamCoord
function SetCamCoord(cam, x, y, z)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not cam or not x or not y or not z then return end
    if not DoesCamExist(cam) then return end
    return _SetCamCoord(cam, x, y, z)
end

local _PointCamAtEntity = PointCamAtEntity
function PointCamAtEntity(cam, entity, ox, oy, oz, offset)
    if not cam or not entity or entity == 0 or not DoesEntityExist(entity) then return end
    if not DoesCamExist(cam) then return end
    ox, oy, oz = tonumber(ox) or 0.0, tonumber(oy) or 0.0, tonumber(oz) or 0.0
    return _PointCamAtEntity(cam, entity, ox, oy, oz, offset == true)
end

local _PointCamAtCoord = PointCamAtCoord
function PointCamAtCoord(cam, x, y, z)
    x, y, z = tonumber(x), tonumber(y), tonumber(z)
    if not cam or not x or not y or not z then return end
    if not DoesCamExist(cam) then return end
    return _PointCamAtCoord(cam, x, y, z)
end
