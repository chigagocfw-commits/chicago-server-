-- Caricato dopo client/modules (vedi fxmanifest) — evita crash se UI carlift senza prop

CreateThread(function()
    while type(openCarliftUI) ~= 'function' or type(moveCarlift) ~= 'function' do
        Wait(100)
    end

    local function poleHash()
        local pole = Config.CarliftModels and Config.CarliftModels.pole or 'imp_prop_impexp_hoist_01a'
        return joaat(pole)
    end

    local function hasCarliftPropNearby(radius)
        radius = radius or 10.0
        local ped = PlayerPedId()
        local c = GetEntityCoords(ped)
        local obj = GetClosestObjectOfType(c.x, c.y, c.z, radius, poleHash(), false, false, false)
        return obj ~= 0 and DoesEntityExist(obj)
    end

    local _open = openCarliftUI
    openCarliftUI = function(shopKey)
        if not hasCarliftPropNearby(12.0) then
            lib.notify({
                title = 'Carlift',
                description = 'Ponteggio non presente — riavvia la resource o copia stream/qs-carlift',
                type = 'error',
            })
            return
        end
        _open(shopKey)
    end

    local _move = moveCarlift
    moveCarlift = function(shopKey, direction)
        local ok, err = pcall(_move, shopKey, direction)
        if not ok then
            if Config.Debug then
                print('^1[qs-mechanic-creator]^0 moveCarlift: ' .. tostring(err))
            end
            lib.notify({
                title = 'Carlift',
                description = 'Lift non pronto — attendi lo spawn del prop',
                type = 'error',
            })
        end
    end
end)
