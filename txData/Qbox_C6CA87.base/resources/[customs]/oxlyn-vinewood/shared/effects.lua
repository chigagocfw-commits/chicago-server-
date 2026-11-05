

VinewoodEffects = {}

-- Only image layers can be animated
function VinewoodEffects.Animated(layer)
  return layer.type == "image"
end

-- Writes x/y/z into `target` (creating it if needed) so per-frame calls can reuse one table
local function SetVec(target, x, y, z)
  target = target or {}
  target.x, target.y, target.z = x, y, z
  return target
end

local function IsFloatEffect(effect)
  return effect == "float" or effect == "floatSpin"
end

local function IsSpinEffect(effect)
  return effect == "spin" or effect == "floatSpin"
end

-- Returns position, rotation, scaleX, scaleY for a layer at time `time` (seconds).
-- `frozen`: when truthy the layer stays at its base pose (see note below).
-- `cache`: optional scratch table; its position/rotation/right/up are reused between calls
-- so animating doesn't allocate every frame. Returned vectors may BE those cached tables,
-- so copy them if you need to keep them.
function VinewoodEffects.Pose(layer, time, frozen, cache)
  if frozen or not VinewoodEffects.Animated(layer) then
    return layer.position, layer.rotation, 1, 1
  end

  local position = layer.position
  local rotation = layer.rotation
  local effect   = layer.effect
  local phase    = layer.motionPhase or 0
  local scaleX, scaleY = 1, 1

  -- Vertical bob
  if IsFloatEffect(effect) then
    local wave = math.sin(time * (layer.floatSpeed or 0.25) * math.pi * 2 + math.rad(phase))
    position = SetVec(cache and cache.position,
      position.x, position.y, position.z + wave * (layer.floatAmplitude or 0.6))
  end

  -- Continuous yaw rotation
  if IsSpinEffect(effect) then
    rotation = SetVec(cache and cache.rotation,
      rotation.x, rotation.y, (rotation.z + time * (layer.spinSpeed or 12) + phase) % 360)
  end

  -- float / spin / floatSpin only move or rotate, no scale or other motion
  if IsFloatEffect(effect) or IsSpinEffect(effect) then
    return position, rotation, scaleX, scaleY
  end

  local angle = time * (layer.motionSpeed or 0.25) * math.pi * 2 + math.rad(phase)
  local wave  = math.sin(angle)

  if effect == "pulse" or effect == "breathe" then
    local amount = layer.motionAmount or 0.15
    scaleX = 1 + amount * wave
    if effect == "breathe" then
      scaleY = 1 - amount * (0.5 + 0.5 * wave) -- shrinks vertically as it widens
    end

  elseif effect == "sway" or effect == "orbit" then
    local radius = layer.motionRadius or 1

    -- right/up axes of the layer; recomputed only when its rotation changes
    local right, up
    if cache then
      if cache.rx ~= rotation.x or cache.ry ~= rotation.y or cache.rz ~= rotation.z then
        cache.right, cache.up = VinewoodMath.basis(rotation)
        cache.rx, cache.ry, cache.rz = rotation.x, rotation.y, rotation.z
      end
      right, up = cache.right, cache.up
    else
      right, up = VinewoodMath.basis(rotation)
    end

    -- sway: side to side. orbit: circle in the layer's plane.
    local offsetRight = (effect == "sway") and (radius * wave) or (radius * math.cos(angle))
    local offsetUp    = (effect == "sway") and 0 or (radius * wave)

    position = SetVec(cache and cache.position,
      position.x + right.x * offsetRight + up.x * offsetUp,
      position.y + right.y * offsetRight + up.y * offsetUp,
      position.z + right.z * offsetRight + up.z * offsetUp)

  elseif effect == "rock" then
    -- rocks back and forth on the Y axis
    rotation = SetVec(cache and cache.rotation,
      rotation.x, rotation.y + (layer.motionAngle or 15) * wave, rotation.z)

  elseif effect == "flip" then
    -- continuous rotation on the X axis
    rotation = SetVec(cache and cache.rotation,
      (rotation.x + time * (layer.spinSpeed or 12) + phase) % 360, rotation.y, rotation.z)
  end

  return position, rotation, scaleX, scaleY
end

-- Radius that covers the layer at its furthest animated extent (for culling/selection)
function VinewoodEffects.Bounds(layer)
  local scale, extra = 1, 0

  if VinewoodEffects.Animated(layer) then
    local effect = layer.effect
    if IsFloatEffect(effect) then
      extra = layer.floatAmplitude or 0.6
    elseif effect == "sway" or effect == "orbit" then
      extra = layer.motionRadius or 1
    elseif effect == "pulse" or effect == "breathe" then
      scale = 1 + (layer.motionAmount or 0.15)
    end
  end

  return math.sqrt(layer.width * layer.width + layer.height * layer.height) * 0.5 * scale + extra
end

