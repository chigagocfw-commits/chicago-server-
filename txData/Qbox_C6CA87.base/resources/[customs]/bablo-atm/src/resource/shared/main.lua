local function isResourceStartedOrStarting(resourceName)
    local state = GetResourceState(resourceName)
    return state == "started" or state == "starting"
end

function IsResourceStartedOrStarting(resourceName)
    return isResourceStartedOrStarting(resourceName)
end

local function waitForResource(resourceName, timeout)
    local deadline = GetGameTimer() + (timeout or 10000)

    while GetGameTimer() < deadline do
        local state = GetResourceState(resourceName)

        if state == "started" then
            return true
        end

        if state == "missing" or state == "unknown" then
            return false
        end

        Wait(200)
    end

    return false
end

local function detectFramework()
    if Config.Framework ~= "auto" then
        return
    end

    if isResourceStartedOrStarting("es_extended") then
        Config.Framework = "esx"
    elseif isResourceStartedOrStarting("qbx_core") then
        Config.Framework = "qbox"
    elseif isResourceStartedOrStarting("qb-core") then
        Config.Framework = "qbcore"
    end
end

CreateThread(function()
    local bankingResource = Config.BankingResource or "bablo-banking"

    if waitForResource(bankingResource, 8000) then
        local ok, framework = pcall(function()
            local banking = exports[bankingResource]
            return banking and banking.GetFramework and banking:GetFramework()
        end)

        if ok and framework then
            Config.Framework = framework
            Debug("[bablo-atm] Configured framework from banking:", framework)
            return
        end
    end

    Debug("[bablo-atm] Falling back to auto framework detection")
    detectFramework()
end)

detectFramework()
