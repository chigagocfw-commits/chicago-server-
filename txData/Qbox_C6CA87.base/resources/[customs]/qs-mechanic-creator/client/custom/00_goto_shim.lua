-- Fallback se permissions.lua non carica (goto Lua 5.4)
if type(canUseTuneshop) ~= 'function' then
    function canUseTuneshop(_shop)
        if Config.MechanicsOnlyTuneshop then
            if type(isMechanicEmployee) == 'function' then
                return isMechanicEmployee(_shop)
            end
            return false
        end
        return true
    end
end

if type(hasShopAccess) ~= 'function' then
    function hasShopAccess(shop)
        if not shop then return false end
        if not Config.MechanicsOnlyTuneshop then return true end
        if type(isMechanicEmployee) == 'function' then
            return isMechanicEmployee(shop)
        end
        return false
    end
end
