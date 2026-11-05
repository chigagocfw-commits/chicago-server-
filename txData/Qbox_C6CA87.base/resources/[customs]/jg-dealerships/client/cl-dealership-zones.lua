DealershipZones = DealershipZones or {}
DealershipZones.Client = DealershipZones.Client or {}

local zones = {}
local generatorBounds = {}
local zonePolygons = {}
local currentZoneId

local function getBounds(points, height)
  if not points or #points == 0 then
    return vec3(0, 0, 0), vec3(0, 0, 0)
  end

  height = height or 10.0

  local minX, minY, minZ = math.huge, math.huge, math.huge
  local maxX, maxY, maxZ = -math.huge, -math.huge, -math.huge

  for _, point in ipairs(points) do
    minX = math.min(minX, point.x)
    minY = math.min(minY, point.y)
    minZ = math.min(minZ, point.z)
    maxX = math.max(maxX, point.x)
    maxY = math.max(maxY, point.y)
    maxZ = math.max(maxZ, point.z)
  end

  local halfHeight = height / 2
  return vec3(minX, minY, minZ - halfHeight), vec3(maxX, maxY, maxZ + height)
end

local function isPointInsideBounds(x, y, z, min, max)
  return x >= min.x and x <= max.x
    and y >= min.y and y <= max.y
    and z >= min.z and z <= max.z
end

local function isInsideAnyGeneratorBounds(x, y, z)
  for _, bounds in pairs(generatorBounds) do
    if isPointInsideBounds(x, y, z, bounds.min, bounds.max) then
      return true
    end
  end

  return false
end

local function removeVehicleGenerators()
  for _, bounds in pairs(generatorBounds) do
    RemoveVehiclesFromGeneratorsInArea(
      bounds.min.x, bounds.min.y, bounds.min.z,
      bounds.max.x, bounds.max.y, bounds.max.z,
      1
    )
  end
end

AddEventHandler("populationPedCreating", function(x, y, z)
  if Config.RemoveGeneratorsAroundDealership and isInsideAnyGeneratorBounds(x, y, z) then
    CancelEvent()
  end
end)

CreateThread(function()
  while true do
    Wait(5000)

    if Config.RemoveGeneratorsAroundDealership and next(generatorBounds) then
      removeVehicleGenerators()
    end
  end
end)

function DealershipZones.Client.GetCurrentZone()
  return currentZoneId
end

function DealershipZones.Client.IsInZone()
  return currentZoneId ~= nil
end

local function isPointInPolygon(x, y, polygon)
  if not polygon or #polygon < 3 then return false end

  local inside = false
  local previousIndex = #polygon

  for index = 1, #polygon do
    local current = polygon[index]
    local previous = polygon[previousIndex]

    local intersects = (current.y > y) ~= (previous.y > y)
      and x < ((previous.x - current.x) * (y - current.y) / (previous.y - current.y)) + current.x

    if intersects then
      inside = not inside
    end

    previousIndex = index
  end

  return inside
end

function DealershipZones.Client.IsPointInZone(zoneId, x, y)
  local polygon = zonePolygons[zoneId]
  if not polygon then return true end
  return isPointInPolygon(x, y, polygon)
end

function DealershipZones.Client.GetZonePolygon(zoneId)
  return zonePolygons[zoneId]
end

function DealershipZones.Client.RemoveZone(zoneId)
  local zone = zones[zoneId]
  if not zone then return end

  zone:remove()
  zones[zoneId] = nil
  generatorBounds[zoneId] = nil
  zonePolygons[zoneId] = nil

  if currentZoneId == zoneId then
    currentZoneId = nil
  end
end

function DealershipZones.Client.CreateZone(location)
  local dealershipZone = location.dealership_zone
  if not dealershipZone or not dealershipZone.points or #dealershipZone.points == 0 then return end

  local points = dealershipZone.points
  local height = dealershipZone.height or 10.0

  DealershipZones.Client.RemoveZone(location.id)
  zonePolygons[location.id] = points

  if Config.RemoveGeneratorsAroundDealership then
    local min, max = getBounds(points, height)
    generatorBounds[location.id] = { min = min, max = max }

    RemoveVehiclesFromGeneratorsInArea(min.x, min.y, min.z, max.x, max.y, max.z, 1)
  end

  local adjustedPoints = {}
  for _, point in ipairs(points) do
    adjustedPoints[#adjustedPoints + 1] = vec3(point.x, point.y, point.z - Globals.InteractionZOffset)
  end

  zones[location.id] = lib.zones.poly({
    points = adjustedPoints,
    thickness = height,
    onEnter = function()
      currentZoneId = location.id
    end,
    onExit = function()
      if currentZoneId == location.id then
        currentZoneId = nil
      end
    end,
    inside = function()
      currentZoneId = location.id
    end,
  })
end

function DealershipZones.Client.RemoveAllZones()
  for zoneId in pairs(zones) do
    DealershipZones.Client.RemoveZone(zoneId)
  end
end
