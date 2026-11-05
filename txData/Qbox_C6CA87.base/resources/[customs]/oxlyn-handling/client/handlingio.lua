

HandlingIO = {}

-- Per-field multiplier learned at runtime when the game stores a value scaled differently
local scaleFactors = {}
-- Fields that failed read-back verification and are no longer written
local blockedFields = {}

local DEFAULT_CLASS = "CHandlingData"

local function getClass(field)
  return field.cls or DEFAULT_CLASS
end

-- Tolerance compare: 0.5% relative + 1e-5 absolute
local function approxEqual(a, b)
  local tolerance = 1.0e-5 + 0.005 * math.max(math.abs(a), math.abs(b))
  return math.abs(a - b) <= tolerance
end

function HandlingIO.read(vehicle, field)
  local ok, result = pcall(function()
    local class = getClass(field)

    if field.type == "vector" then
      local v = GetVehicleHandlingVector(vehicle, class, field.name)
      return { x = v.x, y = v.y, z = v.z }
    elseif field.type == "int" then
      return GetVehicleHandlingInt(vehicle, class, field.name)
    end

    return GetVehicleHandlingFloat(vehicle, class, field.name)
  end)

  if not ok then
    return nil
  end

  if field.type ~= "vector" and type(result) ~= "number" then
    return nil
  end

  return result
end

local function setFloat(vehicle, field, value)
  pcall(SetVehicleHandlingFloat, vehicle, getClass(field), field.name, value + 0.0)
end

local function setVector(vehicle, field, v)
  pcall(SetVehicleHandlingVector, vehicle, getClass(field), field.name,
    vector3(v.x + 0.0, v.y + 0.0, v.z + 0.0))
end

local function writeInt(vehicle, field, value)
  local name = field.name
  local intValue = math.floor((tonumber(value) or 0) + 0.5)

  pcall(SetVehicleHandlingInt, vehicle, getClass(field), name, intValue)

  local readBack = HandlingIO.read(vehicle, field)
  if readBack ~= nil and readBack ~= intValue then
    blockedFields[name] = true
    return false
  end

  return true
end

local function writeVector(vehicle, field, value)
  local name = field.name

  if not (type(value) == "table" and value.x) then
    return false
  end

  local previous = HandlingIO.read(vehicle, field)
  setVector(vehicle, field, value)

  local readBack = HandlingIO.read(vehicle, field)
  if not readBack then
    return true
  end

  if approxEqual(readBack.x, value.x)
    and approxEqual(readBack.y, value.y)
    and approxEqual(readBack.z, value.z) then
    return true
  end

  -- Verification failed: block the field and restore the old value
  blockedFields[name] = true
  if previous then
    setVector(vehicle, field, previous)
  end
  return false
end

local function writeFloat(vehicle, field, value)
  local name = field.name
  local target = (tonumber(value) or 0.0) + 0.0
  local previous = HandlingIO.read(vehicle, field)

  local scaled = target * (scaleFactors[name] or 1.0)
  setFloat(vehicle, field, scaled)

  local readBack = HandlingIO.read(vehicle, field)
  if readBack == nil or approxEqual(readBack, target) then
    return true
  end

  -- Value didn't stick as expected: try to learn a scale factor and retry
  if target ~= 0 and readBack ~= 0 and scaled ~= 0 then
    local ratio = readBack / scaled
    setFloat(vehicle, field, target / ratio)

    readBack = HandlingIO.read(vehicle, field)
    if readBack ~= nil and approxEqual(readBack, target) then
      scaleFactors[name] = 1.0 / ratio
      return true
    end
  end

  -- Give up: block the field and restore the old value
  blockedFields[name] = true
  if previous then
    setFloat(vehicle, field, previous)
  end
  return false
end

function HandlingIO.write(vehicle, field, value)
  if blockedFields[field.name] then
    return false
  end

  if field.type == "int" then
    return writeInt(vehicle, field, value)
  elseif field.type == "vector" then
    return writeVector(vehicle, field, value)
  end

  return writeFloat(vehicle, field, value)
end

function HandlingIO.writeSet(vehicle, values)
  for key, value in pairs(values or {}) do
    local field = HandlingFieldMap[key]
    if field then
      HandlingIO.write(vehicle, field, value)
    end
  end
end

function HandlingIO.isWritable(fieldName)
  return not blockedFields[fieldName]
end

