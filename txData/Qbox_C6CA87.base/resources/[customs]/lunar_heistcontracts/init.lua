local lib = lib

-- Check locale
lib.locale()

-- Check dependency
local ok, err = lib.checkDependency("lunar_bridge", "1.3.7")
if not ok then
    Wait(5000)
    error(err)
end

-- Initialize lunar_bridge exports
if IsDuplicityVersion() then
    LR = exports.lunar_bridge.getObject()
    Utils = LR.Utils
    Dispatch = LR.Dispatch
    Utils.checkVersion(GetCurrentResourceName())
else
    LR = exports.lunar_bridge.getObject()
    Utils = LR.Utils
end
