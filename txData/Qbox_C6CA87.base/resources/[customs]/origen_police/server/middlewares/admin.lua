local adminCache = {}
local nonAdminCache = {}

function AdminMDW(source, denyCallback, allowCallback)
    -- Check if already cached as admin
    if adminCache[source] then
        print("^2[AdminMDW] Player " .. source .. " found in admin cache^7")
        return allowCallback()
    end
    
    -- Check if already cached as non-admin
    if nonAdminCache[source] then
        print("^1[AdminMDW] Player " .. source .. " found in non-admin cache^7")
        return denyCallback(false)
    end
    
    -- Check permission through framework
    local hasPermission = Framework.Functions.HasPermission(source, "admin")
    print("^3[AdminMDW] Checking admin permission for player " .. source .. ": " .. tostring(hasPermission) .. "^7")
    
    if hasPermission then
        adminCache[source] = true
        print("^2[AdminMDW] Player " .. source .. " granted admin access^7")
        return allowCallback()
    end
    
    -- Cache as non-admin and deny
    nonAdminCache[source] = true
    print("^1[AdminMDW] Player " .. source .. " denied admin access^7")
    return denyCallback(false)
end