

-- Vinewood math helpers (cleaned from decompiled output)
-- Vectors are plain tables { x, y, z }. Rotations are { x = pitch, y = roll, z = yaw } in degrees.

VinewoodMath = {}
local M = VinewoodMath

---------------------------------------------------------------------
-- Basic vector ops
---------------------------------------------------------------------
function M.add(a, b)
    return { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
end

function M.sub(a, b)
    return { x = a.x - b.x, y = a.y - b.y, z = a.z - b.z }
end

function M.mul(v, s)
    return { x = v.x * s, y = v.y * s, z = v.z * s }
end

function M.dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function M.cross(a, b)
    return {
        x = a.y * b.z - a.z * b.y,
        y = a.z * b.x - a.x * b.z,
        z = a.x * b.y - a.y * b.x,
    }
end

function M.length(v)
    return math.sqrt(M.dot(v, v))
end

-- Unit vector; returns (0,0,0) for near-zero input
function M.normal(v)
    local len = M.length(v)
    if len > 1.0E-6 then
        return M.mul(v, 1 / len)
    end
    return { x = 0, y = 0, z = 0 }
end

-- Squared distance between two points
function M.distance2(a, b)
    local dx, dy, dz = a.x - b.x, a.y - b.y, a.z - b.z
    return dx * dx + dy * dy + dz * dz
end

function M.clamp(value, min, max)
    return math.max(min, math.min(max, value))
end

-- Deep copy of tables (non-tables returned as-is)
function M.copy(v)
    if type(v) ~= "table" then return v end

    local out = {}
    for k, val in pairs(v) do
        out[k] = M.copy(val)
    end
    return out
end

---------------------------------------------------------------------
-- Rotation
---------------------------------------------------------------------
-- Rotate vector `v` by Euler angles `rot` (degrees):
-- first about Y (roll), then X (pitch), then Z (yaw).
function M.rotate(v, rot)
    local rx, ry, rz = math.rad(rot.x), math.rad(rot.y), math.rad(rot.z)
    local cx, sx = math.cos(rx), math.sin(rx)
    local cy, sy = math.cos(ry), math.sin(ry)
    local cz, sz = math.cos(rz), math.sin(rz)

    -- roll (around Y)
    local x1 = cy * v.x + sy * v.z
    local z1 = -sy * v.x + cy * v.z

    -- pitch (around X)
    local y2 = cx * v.y - sx * z1
    local z2 = sx * v.y + cx * z1

    -- yaw (around Z)
    return {
        x = cz * x1 - sz * y2,
        y = sz * x1 + cz * y2,
        z = z2,
    }
end

-- Local "right" and "up" axes of a layer with rotation `rot`
function M.basis(rot)
    local right = M.rotate({ x = 1, y = 0, z = 0 }, rot)
    local up    = M.rotate({ x = 0, y = 0, z = 1 }, rot)
    return right, up
end

-- World-space corners of a rectangular layer, in order:
-- top-left, top-right, bottom-right, bottom-left.
--   out   : optional table of 4 tables to fill (avoids allocations)
--   cache : optional table remembering the last rotation and its axes
function M.corners(layer, out, cache)
    out   = out or { {}, {}, {}, {} }
    cache = cache or {}

    local rot = layer.rotation

    -- recompute axes only if the rotation changed
    if not (cache.x == rot.x and cache.y == rot.y and cache.z == rot.z) then
        local rx, ry, rz = math.rad(rot.x), math.rad(rot.y), math.rad(rot.z)
        local cx, sx = math.cos(rx), math.sin(rx)
        local cy, sy = math.cos(ry), math.sin(ry)
        local cz, sz = math.cos(rz), math.sin(rz)

        -- right axis
        cache.rx = cz * cy - sz * sx * sy
        cache.ry = sz * cy + cz * sx * sy
        cache.rz = -cx * sy

        -- up axis
        cache.ux = cz * sy + sz * sx * cy
        cache.uy = sz * sy - cz * sx * cy
        cache.uz = cx * cy

        cache.x, cache.y, cache.z = rot.x, rot.y, rot.z
    end

    local hw, hh = layer.width * 0.5, layer.height * 0.5

    -- half-extent vectors along right (r) and up (u)
    local rx, ry, rz = cache.rx * hw, cache.ry * hw, cache.rz * hw
    local ux, uy, uz = cache.ux * hh, cache.uy * hh, cache.uz * hh

    local px, py, pz = layer.position.x, layer.position.y, layer.position.z

    local c1, c2, c3, c4 = out[1], out[2], out[3], out[4]

    c1.x, c1.y, c1.z = px - rx + ux, py - ry + uy, pz - rz + uz   -- top-left
    c2.x, c2.y, c2.z = px + rx + ux, py + ry + uy, pz + rz + uz   -- top-right
    c3.x, c3.y, c3.z = px + rx - ux, py + ry - uy, pz + rz - uz   -- bottom-right
    c4.x, c4.y, c4.z = px - rx - ux, py - ry - uy, pz - rz - uz   -- bottom-left

    return out
end

---------------------------------------------------------------------
-- Camera
---------------------------------------------------------------------
-- GTA camera rotation (pitch in x, yaw in z) -> forward, right, up
function M.cameraBasis(rot)
    local pitch = math.rad(rot.x)
    local yaw   = math.rad(rot.z)

    local forward = {
        x = -math.sin(yaw) * math.cos(pitch),
        y = math.cos(yaw) * math.cos(pitch),
        z = math.sin(pitch),
    }
    local right = {
        x = math.cos(yaw),
        y = math.sin(yaw),
        z = 0,
    }
    local up = M.cross(right, forward)

    return forward, right, up
end

-- Direction of the ray through screen point (nx, ny) in [0..1] x [0..1]
--   rot    : camera rotation, fov in degrees (vertical), aspect = width / height
function M.ray(rot, fov, aspect, nx, ny)
    local forward, right, up = M.cameraBasis(rot)
    local t = math.tan(math.rad(fov) * 0.5)

    return M.normal(
        M.add(
            forward,
            M.add(
                M.mul(right, (nx * 2 - 1) * t * aspect),
                M.mul(up, (1 - ny * 2) * t)
            )
        )
    )
end

---------------------------------------------------------------------
-- Picking
---------------------------------------------------------------------
-- Intersect a ray with a rectangular layer.
-- Returns the distance along the ray, or nil if missed / parallel / behind origin.
function M.hitLayer(origin, dir, layer)
    local right, up = M.basis(layer.rotation)
    local normal = M.cross(right, up)

    local denom = M.dot(dir, normal)
    if math.abs(denom) < 1.0E-5 then
        return nil
    end

    local t = M.dot(M.sub(layer.position, origin), normal) / denom
    if t < 0 then
        return nil
    end

    -- hit point relative to the layer centre
    local local_ = M.sub(M.add(origin, M.mul(dir, t)), layer.position)

    if math.abs(M.dot(local_, right)) <= layer.width / 2
        and math.abs(M.dot(local_, up)) <= layer.height / 2 then
        return t
    end

    return nil
end

