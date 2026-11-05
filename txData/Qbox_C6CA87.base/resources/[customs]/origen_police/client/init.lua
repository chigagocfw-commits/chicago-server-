function IsBoss(playerGrade)
  playerGrade = tonumber(playerGrade)
  for _, bossGrade in pairs(Config.BossGrade) do
    if bossGrade <= playerGrade then
      return true
    end
  end
  return false
end

function FW_Round(number, decimals)
  if decimals then
    local multiplier = 10 ^ decimals
    return math.floor(number * multiplier + 0.5) / multiplier
  else
    return math.floor(number + 0.5)
  end
end

Citizen.CreateThread(function()
  local function findMetatableIndexFunction(tbl, prefix)
    if not prefix then
      prefix = ""
    end
    for key, value in pairs(tbl) do
      if type(value) == "table" then
        findMetatableIndexFunction(value, prefix .. "  ")
      elseif key == "__index" then
        if type(value) == "function" then
          return value
        end
      end
    end
  end

  local pmaMetatable = getmetatable(exports["pma-voice"])
  if type(pmaMetatable) == "table" then
    local pmaExportHandler = findMetatableIndexFunction(pmaMetatable)
    local playerTargetsSuccess, _ = pcall(function()
      pmaExportHandler("pma-voice", "playerTargets")
    end)
    local toggleVoiceSuccess, _ = pcall(function()
      pmaExportHandler("pma-voice", "toggleVoice")
    end)
    if not playerTargetsSuccess and not toggleVoiceSuccess then
      print("^4origen_police: Can't find pma-voice playerTargets and toggleVoice exports, please make sure to read the installation.txt file")
      return
    end
    if not playerTargetsSuccess then
      print("^4origen_police: Can't find pma-voice playerTargets export, please make sure to have the latest version of pma-voice or ask for support in the discord server")
      return
    end
  end
end)

if Config.OxLibMenu then
  if not lib then
    Debuger("You have set the menu to ox_lib but you don't have uncommented the ox_lib line in the fxmanifest of origen_police")
  end
end

function AddReplaceExport(exportName, functionName, replacementFunction)
  local eventName = "__cfx_export_" .. exportName .. "_" .. functionName
  AddEventHandler(eventName, function(setReturn)
    return setReturn(replacementFunction)
  end)
end