-- Dopo load stream/ytyp, forza re-sync carlift (carlift.lua cachea i nomi modello all'avvio)
CreateThread(function()
    for _ = 1, 15 do
        Wait(1000)
        local pole = Config.CarliftModels and Config.CarliftModels.pole or 'qs-carlift'
        if IsModelValid(joaat(pole)) then
            TriggerServerEvent('qs-mechanic-creator:server:getMechanicShopsForceSync')
            return
        end
    end
end)
