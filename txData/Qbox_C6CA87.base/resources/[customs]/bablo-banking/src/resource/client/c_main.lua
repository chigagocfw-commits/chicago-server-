Citizen.CreateThread(function()
  Main:Init()
end)

RegisterNetEvent(eventName .. "client:sendNotify", function(message)
  Framework:Notify(message)
end)

exports("GetLocales", function()
  if Locales and Config and Config.Locale and Locales[Config.Locale] then
    return Locales[Config.Locale]
  end

  return Locales["en-US"]
end)
