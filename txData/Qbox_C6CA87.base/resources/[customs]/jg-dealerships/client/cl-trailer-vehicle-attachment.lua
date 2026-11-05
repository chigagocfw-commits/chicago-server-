TrailerAttachment = TrailerAttachment or {}
TrailerAttachment.Client = TrailerAttachment.Client or {}

local REFERENCE_MODEL = "adder"

local VEHICLE_SIZE_LIMITS = {
  SMALL = { width = 2.3, length = 5.0, height = 2.3 },
  MEDIUM = { width = 2.3, length = 7.1, height = 2.3 }
}

local SMALL_VEHICLE_SLOTS = {
  { x = 0.0, y = -5.1, z = 1.1, heading = 0.0, pitch = 5.0 },
  { x = 0.0, y = -0.2, z = 1.2, heading = 0.0, pitch = -3.0 },
  { x = 0.0, y = 4.7, z = 1.1, heading = 0.0, pitch = 0.0 },
  { x = 0.0, y = -5.2, z = 3.3, heading = 0.0, pitch = 0.0 },
  { x = 0.0, y = -0.1, z = 3.1, heading = 0.0, pitch = -5.0 },
  { x = 0.0, y = 4.8, z = 3.0, heading = 0.0, pitch = 3.0 }
}

local MEDIUM_VEHICLE_SLOTS = {
  { x = 0.0, y = -3.5, z = 1.1, heading = 0.0, pitch = 3.0 },
  { x = 0.0, y = 3.5, z = 1.1, heading = 0.0, pitch = 0.0 },
  { x = 0.0, y = -3.5, z = 3.2, heading = 0.0, pitch = -2.0 },
  { x = 0.0, y = 3.5, z = 3.0, heading = 0.0, pitch = 2.0 }
}

local referenceModelMinZ

local function getModelDimensions(model)
  local modelHash = type(model) == "string" and joaat(model) or model
  return GetModelDimensions(modelHash)
end

local function getReferenceModelMinZ()
  if referenceModelMinZ == nil then
    local modelHash = joaat(REFERENCE_MODEL)
    lib.requestModel(modelHash, 10000)
    local minDimensions = getModelDimensions(REFERENCE_MODEL)
    referenceModelMinZ = minDimensions.z
    SetModelAsNoLongerNeeded(modelHash)
  end

  return referenceModelMinZ
end

local function getVehicleDimensions(model)
  local modelHash = joaat(model)
  if not IsModelInCdimage(modelHash) then
    return nil
  end

  lib.requestModel(modelHash, 10000)
  local minDimensions, maxDimensions = getModelDimensions(model)
  SetModelAsNoLongerNeeded(modelHash)

  return {
    width = maxDimensions.x - minDimensions.x,
    length = maxDimensions.y - minDimensions.y,
    height = maxDimensions.z - minDimensions.z
  }
end

function TrailerAttachment.Client.GetVehicleSizeCategory(model)
  local dimensions = getVehicleDimensions(model)
  if not dimensions then
    return nil
  end

  local small = VEHICLE_SIZE_LIMITS.SMALL
  if dimensions.width <= small.width and dimensions.length <= small.length and dimensions.height <= small.height then
    return "small"
  end

  local medium = VEHICLE_SIZE_LIMITS.MEDIUM
  if dimensions.width <= medium.width and dimensions.length <= medium.length and dimensions.height <= medium.height then
    return "medium"
  end

  return "large"
end

function TrailerAttachment.Client.GetVehicleConfiguration(model)
  local sizeCategory = TrailerAttachment.Client.GetVehicleSizeCategory(model)
  if not sizeCategory or sizeCategory == "large" then
    return nil
  end

  return sizeCategory == "small" and "standard" or "large"
end

function TrailerAttachment.Client.IsVehicleTooLarge(model)
  return TrailerAttachment.Client.GetVehicleSizeCategory(model) == "large"
end

function TrailerAttachment.Client.RequiresContainer(model)
  return TrailerAttachment.Client.GetVehicleSizeCategory(model) == "large"
end

local function fillDeck(smallCount, mediumCount)
  local loadedSmall, loadedMedium = 0, 0

  if mediumCount >= 2 then
    loadedMedium = 2
    mediumCount = mediumCount - 2
  elseif mediumCount == 1 then
    loadedMedium = 1
    mediumCount = 0

    if smallCount >= 1 then
      loadedSmall = 1
      smallCount = smallCount - 1
    end
  else
    loadedSmall = math.min(smallCount, 3)
    smallCount = smallCount - loadedSmall
  end

  return loadedSmall, loadedMedium, smallCount, mediumCount
end

local function canAddToDeck(smallCount, mediumCount)
  if mediumCount >= 2 then
    return false, false
  end

  if mediumCount == 1 and smallCount >= 1 then
    return false, false
  end

  if mediumCount == 1 then
    return true, false
  end

  if smallCount >= 3 then
    return false, false
  end

  if smallCount == 2 then
    return true, false
  end

  return true, true
end

function TrailerAttachment.Client.CalculateTrailerCapacity(vehicleList)
  local remainingSmall, remainingMedium = 0, 0

  for _, vehicleData in ipairs(vehicleList) do
    local sizeCategory = TrailerAttachment.Client.GetVehicleSizeCategory(vehicleData.model)

    if sizeCategory == "small" then
      remainingSmall = remainingSmall + vehicleData.quantity
    elseif sizeCategory == "medium" then
      remainingMedium = remainingMedium + vehicleData.quantity
    end
  end

  local bottomSmall, bottomMedium
  bottomSmall, bottomMedium, remainingSmall, remainingMedium = fillDeck(remainingSmall, remainingMedium)

  local topSmall, topMedium
  topSmall, topMedium, remainingSmall, remainingMedium = fillDeck(remainingSmall, remainingMedium)

  local bottomCanAddSmall, bottomCanAddMedium = canAddToDeck(bottomSmall, bottomMedium)
  local topCanAddSmall, topCanAddMedium = canAddToDeck(topSmall, topMedium)

  return {
    bottomDeck = {
      small = bottomSmall,
      medium = bottomMedium
    },
    topDeck = {
      small = topSmall,
      medium = topMedium
    },
    canAddSmall = bottomCanAddSmall or topCanAddSmall,
    canAddMedium = bottomCanAddMedium or topCanAddMedium,
    overflow = remainingSmall > 0 or remainingMedium > 0
  }
end

local function spawnVehicle(model, coords)
  local modelHash = joaat(model)
  if not IsModelInCdimage(modelHash) then
    return nil
  end

  lib.requestModel(modelHash, 10000)
  local vehicle = CreateVehicle(modelHash, coords.x, coords.y, coords.z, coords.w, true, false)
  SetModelAsNoLongerNeeded(modelHash)

  if not vehicle or vehicle == 0 then
    return nil
  end

  return vehicle
end

local function attachVehicleToTrailer(vehicle, trailer, slot, model)
  DetachEntity(vehicle, false, false)

  local referenceMinZ = getReferenceModelMinZ()
  local vehicleMinDimensions = getModelDimensions(model)
  local adjustedZ = slot.z + (referenceMinZ - vehicleMinDimensions.z)

  AttachEntityToEntity(
    vehicle,
    trailer,
    0,
    slot.x,
    slot.y,
    adjustedZ,
    slot.pitch or 0.0,
    0.0,
    slot.heading,
    false,
    false,
    true,
    false,
    2,
    true
  )

  FreezeEntityPosition(vehicle, true)
  SetEntityInvincible(vehicle, true)
  SetVehicleDoorsLocked(vehicle, 2)
end

local function deleteVehicles(vehicles)
  for _, vehicle in pairs(vehicles) do
    if vehicle and DoesEntityExist(vehicle) then
      DetachEntity(vehicle, false, false)
      DeleteEntity(vehicle)
    end
  end
end

function TrailerAttachment.Client.AttachVehicles(trailer, model, count)
  if not trailer or not DoesEntityExist(trailer) then
    return false, nil, nil
  end

  local sizeCategory = TrailerAttachment.Client.GetVehicleSizeCategory(model)
  if not sizeCategory or sizeCategory == "large" then
    return false, nil, nil
  end

  local slots = sizeCategory == "small" and SMALL_VEHICLE_SLOTS or MEDIUM_VEHICLE_SLOTS
  local maxCount = sizeCategory == "small" and 6 or 4
  local spawnCount = count and math.min(count, maxCount) or maxCount
  local trailerCoords = GetEntityCoords(trailer)
  local spawnCoords = vector4(trailerCoords.x, trailerCoords.y, trailerCoords.z, GetEntityHeading(trailer))

  getReferenceModelMinZ()

  local attachedVehicles = {}

  for index = 1, spawnCount do
    local vehicle = spawnVehicle(model, spawnCoords)

    if not vehicle then
      deleteVehicles(attachedVehicles)
      return false, nil, nil
    end

    attachVehicleToTrailer(vehicle, trailer, slots[index], model)
    attachedVehicles[index] = vehicle
    Wait(50)
  end

  return true, attachedVehicles, sizeCategory
end

function TrailerAttachment.Client.AttachMixedVehicles(trailer, vehicleList)
  if not trailer or not DoesEntityExist(trailer) then
    return false, nil
  end

  local capacity = TrailerAttachment.Client.CalculateTrailerCapacity(vehicleList)
  if capacity.overflow then
    return false, nil
  end

  local trailerCoords = GetEntityCoords(trailer)
  local spawnCoords = vector4(trailerCoords.x, trailerCoords.y, trailerCoords.z, GetEntityHeading(trailer))

  getReferenceModelMinZ()

  local flatVehicles = {}
  for _, vehicleData in ipairs(vehicleList) do
    for _ = 1, vehicleData.quantity do
      local sizeCategory = TrailerAttachment.Client.GetVehicleSizeCategory(vehicleData.model)
      if sizeCategory and sizeCategory ~= "large" then
        flatVehicles[#flatVehicles + 1] = {
          model = vehicleData.model,
          size = sizeCategory
        }
      end
    end
  end

  local hasMediumVehicle = false
  for _, vehicleData in ipairs(flatVehicles) do
    if vehicleData.size == "medium" then
      hasMediumVehicle = true
      break
    end
  end

  local slots = hasMediumVehicle and MEDIUM_VEHICLE_SLOTS or SMALL_VEHICLE_SLOTS
  local maxCount = hasMediumVehicle and 4 or 6
  local attachedVehicles = {}

  for index = 1, math.min(#flatVehicles, maxCount) do
    local vehicleData = flatVehicles[index]
    local vehicle = spawnVehicle(vehicleData.model, spawnCoords)

    if not vehicle then
      deleteVehicles(attachedVehicles)
      return false, nil
    end

    attachVehicleToTrailer(vehicle, trailer, slots[index], vehicleData.model)
    attachedVehicles[#attachedVehicles + 1] = vehicle
    Wait(50)
  end

  return true, attachedVehicles
end

function TrailerAttachment.Client.AttachAdditionalVehicles(trailer, vehicleList, startSlot, _, useMediumSlots)
  if not trailer or not DoesEntityExist(trailer) then
    return false, nil
  end

  local trailerCoords = GetEntityCoords(trailer)
  local spawnCoords = vector4(trailerCoords.x, trailerCoords.y, trailerCoords.z, GetEntityHeading(trailer))

  getReferenceModelMinZ()

  local attachedVehicles = {}
  local flatVehicles = {}

  for _, vehicleData in ipairs(vehicleList) do
    for _ = 1, vehicleData.quantity do
      local sizeCategory = TrailerAttachment.Client.GetVehicleSizeCategory(vehicleData.model)
      if sizeCategory and sizeCategory ~= "large" then
        flatVehicles[#flatVehicles + 1] = {
          model = vehicleData.model,
          size = sizeCategory
        }
      end
    end
  end

  local slots = useMediumSlots and MEDIUM_VEHICLE_SLOTS or SMALL_VEHICLE_SLOTS
  local maxCount = useMediumSlots and 4 or 6
  local slotIndex = startSlot

  for _, vehicleData in ipairs(flatVehicles) do
    if slotIndex > maxCount then
      break
    end

    local vehicle = spawnVehicle(vehicleData.model, spawnCoords)

    if not vehicle then
      deleteVehicles(attachedVehicles)
      return false, nil
    end

    attachVehicleToTrailer(vehicle, trailer, slots[slotIndex], vehicleData.model)
    attachedVehicles[#attachedVehicles + 1] = vehicle
    slotIndex = slotIndex + 1
    Wait(50)
  end

  return true, attachedVehicles
end
