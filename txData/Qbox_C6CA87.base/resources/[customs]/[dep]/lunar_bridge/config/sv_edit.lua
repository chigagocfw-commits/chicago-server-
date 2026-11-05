-- =====================================================
--  Fixed by Reddev Development
--  Support: https://discord.gg/MJH5zX7NSg
--  Cleaned By Reddev Using Codex 5.5
--  Files Provided From Rip_Bytecode
-- =====================================================
---@type 'discord' | 'custom'
Config.Logging = 'discord'

-- You can ignore this if you use discord logging, preconfigured for fivemanage
---@param player Player
---@param resourceName string
---@param message string
function CustomLogging(player, resourceName, message)
    exports.fmsdk:LogMessage("info", message, {
        playerSource = player.source
    })
end