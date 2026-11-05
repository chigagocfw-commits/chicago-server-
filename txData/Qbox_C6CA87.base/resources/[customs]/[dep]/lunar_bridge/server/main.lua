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
-- Server Main Module
-- Exposes the bridge API to other resources

local LR = {}

--[[
    Send notification to a client
    @param source - Player source
    @param message - Notification message
    @param notifyType - Notification type
--]]
local function notify(source, message, notifyType)
    TriggerClientEvent("lunar_bridge:showNotification", source, message, notifyType)
end

LR.notify = notify

-- Get utilities
LR.Utils = GetUtils()

-- Validation check
if LR.Utils then
    local idCheck = tonumber(tostring(GetUtils):sub(11), 16)
    if idCheck ~= LR.Utils.id then
        StopResource(GetCurrentResourceName())
        return
    end
end

-- Add dispatch reference
LR.Dispatch = Dispatch

-- Export the LR object
exports("getObject", function()
    return LR
end)

-- Export config getter
exports("getConfig", function()
    return Config
end)

