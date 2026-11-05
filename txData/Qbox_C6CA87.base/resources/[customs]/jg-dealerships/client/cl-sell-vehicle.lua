SellVehicle = SellVehicle or {}
SellVehicle.Client = SellVehicle.Client or {}

function SellVehicle.Client.Request(dealershipId)
  local vehicle = cache.vehicle
  if not vehicle then
    Framework.Client.Notify(Locale.notInVehicle, "error")
    return false
  end

  local plate = Framework.Client.GetPlate(vehicle)
  if not plate then return false end

  local model = GetEntityArchetypeName(vehicle)
  DebugPrint(("Trying to sell vehicle with plate: %s and model: %s"):format(plate, model), "debug")

  local vehicleValue = lib.callback.await(
    "jg-dealerships:server:sell-vehicle-get-value",
    false,
    dealershipId,
    plate,
    model
  )

  if not vehicleValue then return false end

  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "sell-vehicle-to-dealer",
    dealershipId = dealershipId,
    plate = plate,
    value = vehicleValue,
    config = Config,
    locale = Locale,
  })

  return true
end

local function sellVehicle(dealershipId)
  local vehicle = cache.vehicle
  if not vehicle then return false end

  local plate = Framework.Client.GetPlate(vehicle)
  if not plate then return false end

  local model = GetEntityArchetypeName(vehicle)
  local saleAccepted = lib.callback.await(
    "jg-dealerships:server:sell-vehicle",
    2500,
    dealershipId,
    plate,
    model
  )

  if not saleAccepted then return false end

  DoScreenFadeOut(500)
  Wait(500)

  for seat = -1, 5 do
    local ped = GetPedInVehicleSeat(vehicle, seat)
    if ped then
      TaskLeaveVehicle(ped, vehicle, 0)
    end
  end

  Framework.Client.VehicleRemoveKeys(plate, vehicle, "vehicleSale")
  SetVehicleDoorsLocked(vehicle, 2)
  Wait(1500)
  TriggerEvent("jg-dealerships:client:sell-vehicle:config", vehicle, plate)
  DoScreenFadeIn(500)

  return true
end

RegisterNUICallback("sell-vehicle-price-accepted", function(dealershipId, callback)
  callback(sellVehicle(dealershipId))
end)

RegisterNetEvent("jg-dealerships:client:sell-vehicle", function(dealershipId)
  SellVehicle.Client.Request(dealershipId)
end)
