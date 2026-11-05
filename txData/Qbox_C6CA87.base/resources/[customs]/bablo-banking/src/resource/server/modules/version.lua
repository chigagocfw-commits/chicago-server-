Citizen.CreateThread(function()
  local resourceName = GetCurrentResourceName()
  local currentVersion = GetResourceMetadata(resourceName, "version", 0)

  local function versionNumber(version)
    if type(version) ~= "string" then
      return nil
    end

    local parts = {}

    for part in version:gmatch("%d+") do
      parts[#parts + 1] = tonumber(part)
    end

    if #parts == 0 then
      return nil
    end

    return (parts[1] or 0) * 1000000 + (parts[2] or 0) * 1000 + (parts[3] or 0)
  end

  Citizen.Wait(5000)
  print(("[%s] - Checking for updates..."):format(resourceName))

  PerformHttpRequest(
    "https://raw.githubusercontent.com/TheRealBablo/version/master/" .. resourceName .. ".json",
    function(_, response)
      if not response then
        print("^1Unable to check version.^0")
        return
      end

      local ok, versionData = pcall(json.decode, response)
      if not ok or type(versionData) ~= "table" then
        ok, versionData = pcall(json.decode, response:sub(1, -2))
      end

      if not versionData or not versionData.version then
        print("^1Invalid version data received.^0")
        return
      end

      local latestVersion = versionNumber(versionData.version)
      local installedVersion = versionNumber(currentVersion)

      if not latestVersion or not installedVersion then
        print(("^3[%s] - Skipping update comparison; invalid version data. Current: %s Latest: %s^0"):format(
          resourceName,
          tostring(currentVersion),
          tostring(versionData.version)
        ))
        return
      end

      if latestVersion > installedVersion then
        local divider = ("^%d"):format(math.random(1, 9))

        for _ = 1, 26 + #resourceName do
          divider = divider .. "="
        end

        local patchNotes = table.concat(versionData.descriptions, "\n")
        divider = divider .. "^0"

        print(divider)
        print(([[
^2[%s] - New update available!^0
Current Version: ^5%s^0.
New Version: ^5%s^0.
Patch Notes:
^5%s^0

^5Download it now on your portal.cfx.re/assets/granted-assets^0.]]):format(resourceName, currentVersion, versionData.version, patchNotes))
        print(divider)
      else
        print(("^2[%s] - You are using the latest version.^0"):format(resourceName))
      end
    end,
    "GET"
  )
end)
