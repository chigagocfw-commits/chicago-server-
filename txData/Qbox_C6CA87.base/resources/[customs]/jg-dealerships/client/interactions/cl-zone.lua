Interactions = Interactions or {}
Interactions.Client = Interactions.Client or {}
Interactions.Client.Zone = Interactions.Client.Zone or {}

local CONTROL_SPACE = 22
local CONTROL_BACKSPACE = 194
local CONTROL_ESCAPE = 200
local CONTROL_ENTER = 201
local CONTROL_SCROLL_UP = 241
local CONTROL_SCROLL_DOWN = 242

local DEFAULT_ZONE_HEIGHT = 10.0
local MIN_ZONE_HEIGHT = 1.0
local ZONE_HEIGHT_STEP = 0.5

local creatorActive = false
local creatorZoneHeight = DEFAULT_ZONE_HEIGHT
local creatorPoints = {}

local function getGroundZ(x, y, z)
  local foundGround, groundZ = GetGroundZFor_3dCoord(x, y, z, false)
  if foundGround then
    return groundZ
  end

  local rayHandle = StartShapeTestRay(x, y, z + 10.0, x, y, z - 100.0, 1, 0, 0)
  local _, hit, hitCoords = GetShapeTestResult(rayHandle)

  if hit then
    return hitCoords.z
  end

  return z
end

local function addCreatorPoint()
  local playerPed = PlayerPedId()
  local playerCoords = GetEntityCoords(playerPed)
  local groundZ = getGroundZ(playerCoords.x, playerCoords.y, playerCoords.z)
  local point = {
    x = playerCoords.x,
    y = playerCoords.y,
    z = groundZ + Globals.InteractionZOffset
  }

  table.insert(creatorPoints, point)
  DebugPrint(("^2[Zone Creator]^7 Point %d added at %.2f, %.2f, %.2f"):format(#creatorPoints, point.x, point.y, point.z))
end

local function removeCreatorPoint()
  if #creatorPoints > 0 then
    table.remove(creatorPoints)
    DebugPrint(("^2[Zone Creator]^7 Point removed. Total points: %d"):format(#creatorPoints))
  else
    DebugPrint("^1[Zone Creator]^7 No points to remove!")
  end
end

local function finishCreator()
  if #creatorPoints < 3 then
    Framework.Client.Notify(("Need at least 3 points to complete zone! (Currently have %d)"):format(#creatorPoints), "error", 5000)
    return nil
  end

  creatorActive = false
  return {
    points = creatorPoints,
    zoneHeight = creatorZoneHeight
  }
end

local function drawVerticalLine(x, y, z, height, red, green, blue, alpha)
  DrawLine(x, y, z, x, y, z + height, red, green, blue, alpha)
end

local function drawCreatorVisualization()
  if #creatorPoints == 0 then
    return
  end

  local basePoints = {}

  for _, point in ipairs(creatorPoints) do
    basePoints[#basePoints + 1] = {
      x = point.x,
      y = point.y,
      z = point.z - Globals.InteractionZOffset
    }
  end

  for _, point in ipairs(basePoints) do
    drawVerticalLine(point.x, point.y, point.z, creatorZoneHeight, 255, 0, 0, 255)
  end

  if #basePoints >= 2 then
    Interactions.Client.Zone.DrawVisualization(basePoints, creatorZoneHeight, 255, 0, 0, 80)
  end
end

function Interactions.Client.Zone.DrawVisualization(points, height, red, green, blue, alpha)
  if not points or #points == 0 then
    return
  end

  height = height or 5.0
  red = red or 255
  green = green or 0
  blue = blue or 0
  alpha = alpha or 80

  if #points == 2 then
    local firstPoint = points[1]
    local secondPoint = points[2]

    DrawLine(firstPoint.x, firstPoint.y, firstPoint.z, secondPoint.x, secondPoint.y, secondPoint.z, red, green, blue, 200)
    DrawLine(firstPoint.x, firstPoint.y, firstPoint.z + height, secondPoint.x, secondPoint.y, secondPoint.z + height, red, green, blue, 200)

    DrawPoly(firstPoint.x, firstPoint.y, firstPoint.z, secondPoint.x, secondPoint.y, secondPoint.z, firstPoint.x, firstPoint.y, firstPoint.z + height, red, green, blue, alpha)
    DrawPoly(firstPoint.x, firstPoint.y, firstPoint.z, firstPoint.x, firstPoint.y, firstPoint.z + height, secondPoint.x, secondPoint.y, secondPoint.z, red, green, blue, alpha)
    DrawPoly(secondPoint.x, secondPoint.y, secondPoint.z, secondPoint.x, secondPoint.y, secondPoint.z + height, firstPoint.x, firstPoint.y, firstPoint.z + height, red, green, blue, alpha)
    DrawPoly(secondPoint.x, secondPoint.y, secondPoint.z, firstPoint.x, firstPoint.y, firstPoint.z + height, secondPoint.x, secondPoint.y, secondPoint.z + height, red, green, blue, alpha)
    return
  end

  for index = 2, #points - 1 do
    local firstPoint = points[1]
    local secondPoint = points[index]
    local thirdPoint = points[index + 1]

    DrawPoly(firstPoint.x, firstPoint.y, firstPoint.z, secondPoint.x, secondPoint.y, secondPoint.z, thirdPoint.x, thirdPoint.y, thirdPoint.z, red, green, blue, alpha)
    DrawPoly(firstPoint.x, firstPoint.y, firstPoint.z, thirdPoint.x, thirdPoint.y, thirdPoint.z, secondPoint.x, secondPoint.y, secondPoint.z, red, green, blue, alpha)
    DrawPoly(firstPoint.x, firstPoint.y, firstPoint.z + height, secondPoint.x, secondPoint.y, secondPoint.z + height, thirdPoint.x, thirdPoint.y, thirdPoint.z + height, red, green, blue, alpha)
    DrawPoly(firstPoint.x, firstPoint.y, firstPoint.z + height, thirdPoint.x, thirdPoint.y, thirdPoint.z + height, secondPoint.x, secondPoint.y, secondPoint.z + height, red, green, blue, alpha)
  end

  for index = 1, #points do
    local currentPoint = points[index]
    local nextPoint = points[index == #points and 1 or index + 1]

    DrawLine(currentPoint.x, currentPoint.y, currentPoint.z, nextPoint.x, nextPoint.y, nextPoint.z, red, green, blue, 200)
    DrawLine(currentPoint.x, currentPoint.y, currentPoint.z + height, nextPoint.x, nextPoint.y, nextPoint.z + height, red, green, blue, 200)

    DrawPoly(currentPoint.x, currentPoint.y, currentPoint.z, nextPoint.x, nextPoint.y, nextPoint.z, currentPoint.x, currentPoint.y, currentPoint.z + height, red, green, blue, alpha)
    DrawPoly(currentPoint.x, currentPoint.y, currentPoint.z, currentPoint.x, currentPoint.y, currentPoint.z + height, nextPoint.x, nextPoint.y, nextPoint.z, red, green, blue, alpha)
    DrawPoly(nextPoint.x, nextPoint.y, nextPoint.z, nextPoint.x, nextPoint.y, nextPoint.z + height, currentPoint.x, currentPoint.y, currentPoint.z + height, red, green, blue, alpha)
    DrawPoly(nextPoint.x, nextPoint.y, nextPoint.z, currentPoint.x, currentPoint.y, currentPoint.z + height, nextPoint.x, nextPoint.y, nextPoint.z + height, red, green, blue, alpha)
  end
end

function Interactions.Client.Zone.StartCreator()
  local resultPromise = promise.new()

  if creatorActive then
    return false
  end

  creatorActive = true
  creatorZoneHeight = DEFAULT_ZONE_HEIGHT
  creatorPoints = {}

  Interactions.Client.InstrPrmt.Show("Walk to each point and add it to create a zone", {
    { key = "Space", desc = "Add Point" },
    { key = "Backspace", desc = "Remove Last" },
    { key = "Scroll", desc = "Adjust Height" },
    { key = "Enter", desc = "Complete Zone" },
    { key = "Esc", desc = "Cancel" }
  })

  CreateThread(function()
    while creatorActive do
      SetPauseMenuActive(false)
      DisableControlAction(0, CONTROL_SPACE, true)

      drawCreatorVisualization()

      local playerPed = PlayerPedId()
      local playerCoords = GetEntityCoords(playerPed)
      local groundZ = getGroundZ(playerCoords.x, playerCoords.y, playerCoords.z)
      drawVerticalLine(playerCoords.x, playerCoords.y, groundZ, creatorZoneHeight, 0, 255, 0, 200)

      if IsDisabledControlJustReleased(0, CONTROL_SPACE) then
        addCreatorPoint()
      end

      if IsControlJustReleased(0, CONTROL_BACKSPACE) then
        removeCreatorPoint()
      end

      if IsDisabledControlJustReleased(0, CONTROL_SCROLL_UP) then
        creatorZoneHeight = creatorZoneHeight + ZONE_HEIGHT_STEP
      end

      if IsDisabledControlJustReleased(0, CONTROL_SCROLL_DOWN) then
        creatorZoneHeight = math.max(MIN_ZONE_HEIGHT, creatorZoneHeight - ZONE_HEIGHT_STEP)
      end

      if IsControlJustReleased(0, CONTROL_ENTER) then
        local result = finishCreator()
        if result then
          Interactions.Client.InstrPrmt.Hide()
          resultPromise:resolve(result)
        end
      end

      if IsControlJustReleased(1, CONTROL_ESCAPE) or IsControlJustReleased(0, CONTROL_ESCAPE) then
        DebugPrint("^1[Zone Creator]^7 Cancelled!")
        Interactions.Client.InstrPrmt.Hide()
        resultPromise:resolve(false)

        CreateThread(function()
          Wait(100)
          creatorActive = false
        end)
      end

      Wait(0)
    end
  end)

  return Citizen.Await(resultPromise)
end

RegisterNUICallback("interactions-zone-creator", function(_, callback)
  SetNuiFocus(false, false)

  local result = Interactions.Client.Zone.StartCreator()
  if result then
    callback({
      coords = result.points,
      zoneHeight = result.zoneHeight
    })
  else
    callback(false)
  end

  SetNuiFocus(true, true)
end)

function Interactions.Client.Zone.Create(points, label, key, onInteract, canInteract, zoneHeight)
  local totalX, totalY, totalZ = 0, 0, 0

  for _, point in ipairs(points) do
    totalX = totalX + point.x
    totalY = totalY + point.y
    totalZ = totalZ + point.z
  end

  local center = vec3(totalX / #points, totalY / #points, totalZ / #points)
  return Interactions.Client.Handler.AddPointInteraction(center, 10.0, label, key, onInteract, points, canInteract)
end

function Interactions.Client.Zone.Remove(zone)
  if zone then
    Interactions.Client.Handler.RemovePointInteraction(zone)
  end
end
