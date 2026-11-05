Interactions = Interactions or {}
Interactions.Client = Interactions.Client or {}
Interactions.Client.Point = Interactions.Client.Point or {}

local CONTROL_ESC = 200
local CONTROL_ENTER = 201
local CONTROL_SCROLL_DOWN = 181
local CONTROL_SCROLL_UP = 180
local CONTROL_W = 32
local CONTROL_S = 33
local CONTROL_A = 34
local CONTROL_D = 35
local CONTROL_R = 250
local CONTROL_F = 251

local disabledFineTuneControls = { 30, 31, 44, 22, 23, 140 }
local isCreatingPoint = false
local pointRadius = 2.0
local radiusBlip

local function moveRelativeToPlayer(coords, direction, amount)
  local heading = math.rad(GetEntityHeading(cache.ped))
  local offsetX, offsetY, offsetZ = 0.0, 0.0, 0.0

  if direction == "forward" then
    offsetX = -math.sin(heading) * amount
    offsetY = math.cos(heading) * amount
  elseif direction == "back" then
    offsetX = math.sin(heading) * amount
    offsetY = -math.cos(heading) * amount
  elseif direction == "left" then
    offsetX = -math.cos(heading) * amount
    offsetY = -math.sin(heading) * amount
  elseif direction == "right" then
    offsetX = math.cos(heading) * amount
    offsetY = math.sin(heading) * amount
  elseif direction == "up" then
    offsetZ = amount
  elseif direction == "down" then
    offsetZ = -amount
  end

  return vec3(coords.x + offsetX, coords.y + offsetY, coords.z + offsetZ)
end

function Interactions.Client.Point.DrawVisualization(x, y, z, radius, red, green, blue, alpha, height)
  height = height or 3.0
  local segments = 32

  for index = 1, segments do
    local previousAngle = (index - 1) * ((2 * math.pi) / segments)
    local currentAngle = index * ((2 * math.pi) / segments)

    local previousX = x + (math.cos(previousAngle) * radius)
    local previousY = y + (math.sin(previousAngle) * radius)
    local currentX = x + (math.cos(currentAngle) * radius)
    local currentY = y + (math.sin(currentAngle) * radius)

    DrawPoly(x, y, z, previousX, previousY, z, currentX, currentY, z, red, green, blue, alpha)
    DrawPoly(x, y, z, currentX, currentY, z, previousX, previousY, z, red, green, blue, alpha)
    DrawPoly(x, y, z + height, previousX, previousY, z + height, currentX, currentY, z + height, red, green, blue, alpha)
    DrawPoly(x, y, z + height, currentX, currentY, z + height, previousX, previousY, z + height, red, green, blue, alpha)
    DrawPoly(previousX, previousY, z, currentX, currentY, z, previousX, previousY, z + height, red, green, blue, alpha)
    DrawPoly(currentX, currentY, z, currentX, currentY, z + height, previousX, previousY, z + height, red, green, blue, alpha)
  end
end

function Interactions.Client.Point.StartCreator()
  local promiseResult = promise.new()
  isCreatingPoint = true
  pointRadius = 2.0

  if radiusBlip then
    RemoveBlip(radiusBlip)
    radiusBlip = nil
  end

  local stage = 1
  local moveSpeed = 0.05
  local pointCoords

  Interactions.Client.InstrPrmt.Show("Walk to where you want to place the point", {
    { key = "Enter", desc = "Place Point" },
    { key = "Esc", desc = "Cancel" },
  })

  CreateThread(function()
    while isCreatingPoint do
      DisableControlAction(0, CONTROL_ESC, true)

      if IsDisabledControlJustReleased(0, CONTROL_ESC) then
        if radiusBlip then
          RemoveBlip(radiusBlip)
          radiusBlip = nil
        end

        Interactions.Client.InstrPrmt.Hide()
        promiseResult:resolve(false)
        isCreatingPoint = false
        break
      end

      if stage == 1 then
        if IsControlJustReleased(0, CONTROL_ENTER) then
          local aheadCoords = GetOffsetFromEntityInWorldCoords(cache.ped, 0.0, 3.0, 0.0)
          local foundGround, groundZ = GetGroundZFor_3dCoord(aheadCoords.x, aheadCoords.y, aheadCoords.z + 2.0, false)
          local z = foundGround and groundZ or aheadCoords.z

          pointCoords = vec3(aheadCoords.x, aheadCoords.y, z + Globals.InteractionZOffset)
          stage = 2

          Interactions.Client.InstrPrmt.Show("Fine-tune the point position and radius", {
            { key = "R", desc = "Up" },
            { key = "F", desc = "Down" },
            { key = "Scroll", desc = "Radius" },
            { key = "Enter", desc = "Confirm" },
            { key = "Esc", desc = "Cancel" },
          }, "Move")
        end
      else
        for _, control in ipairs(disabledFineTuneControls) do
          DisableControlAction(0, control, true)
        end

        if IsDisabledControlPressed(0, CONTROL_W) then
          pointCoords = moveRelativeToPlayer(pointCoords, "forward", moveSpeed)
        end
        if IsDisabledControlPressed(0, CONTROL_S) then
          pointCoords = moveRelativeToPlayer(pointCoords, "back", moveSpeed)
        end
        if IsDisabledControlPressed(0, CONTROL_A) then
          pointCoords = moveRelativeToPlayer(pointCoords, "left", moveSpeed)
        end
        if IsDisabledControlPressed(0, CONTROL_D) then
          pointCoords = moveRelativeToPlayer(pointCoords, "right", moveSpeed)
        end
        if IsDisabledControlPressed(0, CONTROL_R) then
          pointCoords = moveRelativeToPlayer(pointCoords, "up", moveSpeed)
        end
        if IsDisabledControlPressed(0, CONTROL_F) then
          pointCoords = moveRelativeToPlayer(pointCoords, "down", moveSpeed)
        end

        if IsControlJustReleased(0, CONTROL_SCROLL_UP) then
          pointRadius = pointRadius + 0.5
        elseif IsControlJustReleased(0, CONTROL_SCROLL_DOWN) then
          pointRadius = math.max(0.5, pointRadius - 0.5)
        end

        if not radiusBlip then
          radiusBlip = AddBlipForRadius(pointCoords.x, pointCoords.y, pointCoords.z, pointRadius)
          SetBlipColour(radiusBlip, 1)
          SetBlipAlpha(radiusBlip, 128)
          SetBlipSprite(radiusBlip, 9)
        else
          SetBlipCoords(radiusBlip, pointCoords.x, pointCoords.y, pointCoords.z)
          SetBlipScale(radiusBlip, pointRadius / 5.0)
        end

        local visualZ = pointCoords.z - Globals.InteractionZOffset
        Interactions.Client.Point.DrawVisualization(pointCoords.x, pointCoords.y, visualZ, pointRadius, 255, 0, 0, 80, 3.0)

        if IsControlJustReleased(0, CONTROL_ENTER) then
          if radiusBlip then
            RemoveBlip(radiusBlip)
            radiusBlip = nil
          end

          Interactions.Client.InstrPrmt.Hide()
          promiseResult:resolve({
            coords = {
              x = pointCoords.x,
              y = pointCoords.y,
              z = pointCoords.z,
            },
            radius = pointRadius,
          })
          isCreatingPoint = false
        end
      end

      Wait(0)
    end
  end)

  return Citizen.Await(promiseResult)
end

RegisterNUICallback("interactions-point-creator", function(_, callback)
  SetNuiFocus(false, false)
  callback(Interactions.Client.Point.StartCreator())
  SetNuiFocus(true, true)
end)

function Interactions.Client.Point.Create(coords, radius, label, key, onInteract, canInteract)
  return Interactions.Client.Handler.AddPointInteraction(
    vec3(coords.x, coords.y, coords.z),
    radius,
    label,
    key,
    onInteract,
    nil,
    canInteract
  )
end

function Interactions.Client.Point.Remove(point)
  if not point then return end
  Interactions.Client.Handler.RemovePointInteraction(point)
end
