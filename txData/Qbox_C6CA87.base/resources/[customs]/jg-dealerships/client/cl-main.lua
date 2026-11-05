Utils = Utils or {}
Utils.Client = Utils.Client or {}

DoScreenFadeIn(0)

function Utils.Client.SetVehicleColourNew(vehicle, color)
  if not vehicle then return false end

  if type(color) == "table" then
    SetVehicleModColor_1(vehicle, 1, 0, 0)
    SetVehicleCustomPrimaryColour(vehicle, color.r, color.g, color.b)
    SetVehicleModColor_2(vehicle, 1, 0)
    SetVehicleCustomSecondaryColour(vehicle, color.r, color.g, color.b)
  elseif type(color) == "number" then
    ClearVehicleCustomPrimaryColour(vehicle)
    ClearVehicleCustomSecondaryColour(vehicle)
    SetVehicleColours(vehicle, color, color)
  end

  SetVehicleExtraColours(vehicle, 0, nil)
  SetVehicleDirtLevel(vehicle, 0.0)
  return true
end

function Utils.Client.GetPolygonCenter(points)
  local totalX, totalY, totalZ = 0, 0, 0

  for _, point in ipairs(points) do
    totalX = totalX + point.x
    totalY = totalY + point.y
    totalZ = totalZ + point.z
  end

  return vec3(totalX / #points, totalY / #points, totalZ / #points)
end

function Utils.Client.DrawMarkerOnFrame(markerType, coords, scale, color, rotation, direction, bobUpAndDown, faceCamera, rotate, drawOnEnts)
  rotation = rotation or vec3(0, 0, 0)
  direction = direction or vec3(0, 0, 0)
  bobUpAndDown = bobUpAndDown or false
  faceCamera = faceCamera or false
  rotate = rotate or false
  drawOnEnts = drawOnEnts or false

  local scaleX, scaleY, scaleZ

  if type(scale) == "table" then
    scaleX = scale.x or scale[1] or 1.0
    scaleY = scale.y or scale[2] or 1.0
    scaleZ = scale.z or scale[3] or 1.0
  else
    scaleX = scale + 0.0
    scaleY = scale + 0.0
    scaleZ = scale + 0.0
  end

  DrawMarker(
    markerType,
    coords.x, coords.y, coords.z,
    direction.x, direction.y, direction.z,
    rotation.x, rotation.y, rotation.z,
    scaleX, scaleY, scaleZ,
    color.r, color.g, color.b,
    math.floor(255 * (color.a or 1)),
    bobUpAndDown,
    faceCamera,
    2,
    rotate,
    nil,
    nil,
    drawOnEnts
  )
end

function Utils.Client.ConvertToVec3(coords)
  return vector3(coords.x, coords.y, coords.z)
end

function Utils.Client.ConvertToVec4(coords)
  return vector4(coords.x, coords.y, coords.z, coords.w)
end

function Utils.Client.ConvertSpawnCoordsToVec4(coords)
  if not coords then return {} end

  if coords.x then
    return { vector4(coords.x, coords.y, coords.z, coords.w) }
  end

  local convertedCoords = {}

  for index, coord in ipairs(coords) do
    convertedCoords[index] = vector4(coord.x, coord.y, coord.z, coord.w)
  end

  return convertedCoords
end

function Utils.Client.FindAvailableSpawnCoords(spawnCoords)
  if type(spawnCoords) == "table" and type(spawnCoords) ~= "vector4" and type(spawnCoords) ~= "vector3" then
    for _, coords in pairs(spawnCoords) do
      if not lib.getClosestVehicle(coords.xyz, 2.5) then
        return coords
      end
    end

    return Utils.Client.FindAvailableSpawnCoords(spawnCoords[1])
  end

  local attempts = 1
  local coords = spawnCoords.xyzw

  while attempts <= 10 do
    if not lib.getClosestVehicle(coords.xyz, 2.5) then
      return coords
    end

    local nextX, nextY = coords.x, coords.y
    local heading = coords.w

    if (heading >= 0 and heading <= 45) or (heading >= 315 and heading <= 360) then
      nextY = nextY + 5
    elseif heading >= 46 and heading <= 135 then
      nextX = nextX - 5
    elseif heading >= 136 and heading <= 225 then
      nextY = nextY - 5
    elseif heading >= 226 and heading <= 314 then
      nextX = nextX + 5
    end

    coords = vector4(nextX, nextY, coords.z, heading)
    attempts = attempts + 1
  end

  return coords
end

function GetVehicleTypeFromClass(vehicleClass)
  if vehicleClass == 14 then return "sea" end
  if vehicleClass == 15 or vehicleClass == 16 then return "air" end
  return "car"
end

function PlayTabletAnim()
  local animDict = "amb@code_human_in_bus_passenger_idles@female@tablet@base"
  local animName = "base"
  local tabletModel = -1585232418
  local tabletBone = 60309
  local tabletOffset = vector3(0.03, 0.002, -0.0)
  local tabletRotation = vector3(10.0, 160.0, 0.0)

  Citizen.CreateThread(function()
    lib.requestAnimDict(animDict)
    lib.requestModel(tabletModel)

    local ped = cache.ped
    Globals.HoldingTablet = CreateObject(tabletModel, 0.0, 0.0, 0.0, true, true, false)
    local boneIndex = GetPedBoneIndex(ped, tabletBone)

    SetCurrentPedWeapon(ped, -1569615261, true)
    AttachEntityToEntity(
      Globals.HoldingTablet,
      ped,
      boneIndex,
      tabletOffset.x, tabletOffset.y, tabletOffset.z,
      tabletRotation.x, tabletRotation.y, tabletRotation.z,
      true,
      false,
      false,
      false,
      2,
      true
    )

    SetModelAsNoLongerNeeded(tabletModel)

    if not IsEntityPlayingAnim(ped, animDict, animName, 3) then
      TaskPlayAnim(ped, animDict, animName, 3.0, 3.0, -1, 49, 0, false, false, false)
    end

    RemoveAnimDict(animDict)
  end)
end

function StopTabletAnim()
  if not Globals.HoldingTablet then return end

  ClearPedTasks(cache.ped)
  DetachEntity(Globals.HoldingTablet, true, false)
  DeleteEntity(Globals.HoldingTablet)
  Globals.HoldingTablet = nil
end

function GetPlayerBalances()
  return lib.callback.await("jg-dealerships:server:get-player-balances", false) or {}
end

RegisterNUICallback("get-player-balances", function(_, callback)
  callback(GetPlayerBalances())
end)

RegisterNUICallback("close", function(_, callback)
  SetNuiFocus(false, false)
  StopTabletAnim()
  callback(true)
end)

RegisterNUICallback("get-nearby-players", function(data, callback)
  local players = lib.callback.await(
    "jg-dealerships:server:get-nearby-players",
    false,
    data.dealershipId,
    data.includeSelf
  )

  callback(players or {})
end)
