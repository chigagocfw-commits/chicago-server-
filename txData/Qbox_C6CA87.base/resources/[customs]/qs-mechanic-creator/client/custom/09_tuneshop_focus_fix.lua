-- Tuneshop in MLO: vietato focus world (SetFocus* = camera sotto mappa). Solo script cam sul veicolo.

_G.QsTuneshopSuppressFocusPos = _G.QsTuneshopSuppressFocusPos or false

local _SetFocusPosAndVel = SetFocusPosAndVel
local _SetFocusEntity = SetFocusEntity
local _ClearFocus = ClearFocus

function SetFocusPosAndVel(x, y, z, vx, vy, vz)
    if _G.QsTuneshopSuppressFocusPos then
        return
    end
    return _SetFocusPosAndVel(x, y, z, vx, vy, vz)
end

function SetFocusEntity(entity)
    if _G.QsTuneshopSuppressFocusPos then
        return
    end
    return _SetFocusEntity(entity)
end

function ClearFocus()
    if _G.QsTuneshopSuppressFocusPos then
        return
    end
    return _ClearFocus()
end

CreateThread(function()
    while not OpenTuneShop do
        Wait(300)
    end
    local _open = OpenTuneShop
    OpenTuneShop = function(...)
        _G.QsTuneshopSuppressFocusPos = true
        return _open(...)
    end
    while type(CloseTuneshop) ~= 'function' do
        Wait(200)
    end
    local _close = CloseTuneshop
    CloseTuneshop = function(...)
        _G.QsTuneshopSuppressFocusPos = false
        _G.QsTuneshopFreelookActive = false
        _G.QsTuneshopScriptCam = nil
        local result = _close(...)
        pcall(_ClearFocus)
        return result
    end
end)
