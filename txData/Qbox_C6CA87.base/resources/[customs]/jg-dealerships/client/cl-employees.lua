Employees = Employees or {}
Employees.Client = Employees.Client or {}

RegisterNetEvent("jg-dealerships:client:show-confirm-employment", function(data)
  SetNuiFocus(true, true)
  SendNUIMessage({
    type = "showConfirmEmployment",
    data = data,
    config = Config,
    locale = Locale,
  })
end)

RegisterNUICallback("accept-hire-request", function(data, callback)
  TriggerServerEvent("jg-dealerships:server:hire-employee", data)
  callback(true)
end)

RegisterNUICallback("deny-hire-request", function(data, callback)
  TriggerServerEvent(
    "jg-dealerships:server:employee-hire-rejected",
    data.requesterId,
    data.playerName
  )

  callback(true)
end)

RegisterNetEvent("jg-dealerships:client:employee-hire-response", function(data)
  SendNUIMessage({
    type = "employee-hire-response",
    data = data,
  })
end)

RegisterNUICallback("request-hire-employee", function(data, callback)
  TriggerServerEvent("jg-dealerships:server:request-hire-employee", data)
  callback(true)
end)

RegisterNUICallback("fire-employee", function(data, callback)
  TriggerServerEvent("jg-dealerships:server:fire-employee", data.identifier, data.dealershipId)
  callback(true)
end)

RegisterNUICallback("update-employee-role", function(data, callback)
  TriggerServerEvent(
    "jg-dealerships:server:update-employee-role",
    data.identifier,
    data.dealershipId,
    data.newRole
  )

  callback(true)
end)
