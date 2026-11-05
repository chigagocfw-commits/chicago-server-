-- Postfix: ClearFocus + wrap CloseTuneshop (carica dopo client.lua / tunes.lua)

CreateThread(function()
    while type(CloseTuneshop) ~= 'function' do
        Wait(200)
    end

    local _close = CloseTuneshop
    CloseTuneshop = function(...)
        local ok, err = pcall(_close, ...)
        if not ok and Config and Config.Debug then
            print('^1[qs-mechanic-creator]^0 CloseTuneshop: ' .. tostring(err))
        end
        return ok
    end
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    _G.QsTuneshopFreelookActive = false
    pcall(function()
        RenderScriptCams(false, false, 0, true, true)
    end)
end)
