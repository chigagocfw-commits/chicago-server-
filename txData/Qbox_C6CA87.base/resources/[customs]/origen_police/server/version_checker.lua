if not Config.CheckVersions then
  return
end

CreateThread(function()
  Wait(5000)

  local function toNumber(str)
    return tonumber(str)
  end

  local resourceName = GetCurrentResourceName()
  if resourceName ~= "origen_police" then
    while true do
      print("^1[Origen Police] - The resource name is not correct, please change it to \"origen_police\".^0")
      Wait(1000)
    end
  end

  local currentVersion = GetResourceMetadata(resourceName, "version", 0)
  local url = "https://raw.githubusercontent.com/ElOrigenCompanyES/ScriptsVersions/master/" .. resourceName .. ".txt"

  PerformHttpRequest(url, function(errorCode, responseData, responseHeaders)
    if not responseData then
      print("^1The version check failed, GitHub may be down.^0")
      return
    end

    -- The substring is likely to remove BOM or other non-json characters from the file
    local remoteInfo = json.decode(responseData:sub(1, -2))
    
    local remoteVersionNumber = toNumber(remoteInfo.version:gsub("%.", ""))
    local currentVersionNumber = toNumber(currentVersion:gsub("%.", ""))

    if remoteVersionNumber > currentVersionNumber then
      local separator = "^9"
      local separatorLength = 26 + (#resourceName * 2)
      for i = 1, separatorLength do
        separator = separator .. "-"
      end
      separator = separator .. "^0"

      print(separator)
      print([[
^3[Origen Police] - New update available now!^0
Current Version: ^1]] .. currentVersion .. [[
^0.
New Version: ^2]] .. remoteInfo.version .. "^0.")

      if remoteInfo.updates then
        for _, updateText in ipairs(remoteInfo.updates) do
          print("^2   - " .. updateText .. "^0")
        end
      else
        print("^2No news available^0")
      end

      print([[

^5Download it now on your keymaster.fivem.net^0.]])
      print(separator)
    end
  end, "GET", "", { ["Content-Type"] = "application/json" })
end)