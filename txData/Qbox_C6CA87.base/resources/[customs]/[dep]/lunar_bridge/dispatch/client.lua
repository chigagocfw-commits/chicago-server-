-- =====================================================
--  Fixed by https://discord.gg/6NCbAv2VNK Reddev Development  
--  Cleaned By Reddev Using Codex 5.5 
--  Files Provided From anon_fort
-- =====================================================

-- =====================================================
--  Fixed by Reddev Development
--  Support: https://discord.gg/MJH5zX7NSg
--  Cleaned By Reddev Using Codex 5.5
--  Files Provided From Rip_Bytecode
-- =====================================================
RegisterNetEvent('lunar_bridge:dispatch:call')
AddEventHandler('lunar_bridge:dispatch:call', function(coords, data)
    if Utils.isPolice() then
        lib.notify({
            title = data.Code,
            description = data.Message,
            position = 'top-right',
            duration = 10000,
            style = {
                width = 330,
                backgroundColor = '#0d3482',
                color = '#FFFFFF',
                padding = 20,
            },
            icon = 'shield-halved',
        })
        local blip = Utils.createBlip(coords, {
            Name = data.Title,
            Sprite = data.Sprite or 161, 
            Size = 2.0, 
            Color = 0
        })
        Citizen.SetTimeout(30000, function()
            blip.remove()
        end)
    end
end)
