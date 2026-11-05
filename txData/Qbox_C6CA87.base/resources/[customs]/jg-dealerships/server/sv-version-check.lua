local resourceName = "jg-dealerships"
local versionsUrl = "https://raw.githubusercontent.com/jgscripts/versions/main/" .. resourceName .. ".txt"

local function isVersionOutdated(currentVersion, latestVersion)
  local currentParts = {}
  local latestParts = {}

  for part in currentVersion:gmatch("[^.]+") do
    currentParts[#currentParts + 1] = tonumber(part)
  end

  for part in latestVersion:gmatch("[^.]+") do
    latestParts[#latestParts + 1] = tonumber(part)
  end

  for index = 1, math.max(#currentParts, #latestParts) do
    local currentPart = currentParts[index] or 0
    local latestPart = latestParts[index] or 0

    if currentPart < latestPart then
      return true
    end
  end

  return false
end

PerformHttpRequest(versionsUrl, function(statusCode, responseBody)
  if statusCode ~= 200 then
    return print("^1Unable to perform update check")
  end

  local currentVersion = GetResourceMetadata(GetCurrentResourceName(), "version", 0)
  if not currentVersion then
    return
  end

  if currentVersion == "dev" then
    return print("^3Using dev version")
  end

  local latestVersion = responseBody:match("^[^\r\n]+")
  if not latestVersion then
    return
  end

  if isVersionOutdated(currentVersion:sub(2), latestVersion:sub(2)) then
    print(("^3Update available for %s! (current: ^1%s^3, latest: ^2%s^3)"):format(resourceName, currentVersion, latestVersion))
    print("^3Release notes: discord.gg/jgscripts")
  end
end, "GET")

local function checkArtifactVersion()
  local serverVersion = GetConvar("version", "unknown")
  local artifactVersion = serverVersion:match("v%d+%.%d+%.%d+%.(%d+)")

  PerformHttpRequest("https://artifacts.jgscripts.com/check?artifact=" .. artifactVersion, function(statusCode, responseBody, _, errorData)
    if statusCode ~= 200 or errorData then
      return print("^1Could not check artifact version^0")
    end

    if not responseBody then
      return
    end

    local response = json.decode(responseBody)
    if response.status == "BROKEN" then
      print("^1WARNING: The current FXServer version you are using (artifacts version) has known issues. Please update to the latest stable artifacts: https://artifacts.jgscripts.com^0")
      print("^0Artifact version:^3", artifactVersion, "\n\n^0Known issues:^3", response.reason, "^0")
    end
  end)
end

CreateThread(function()
  checkArtifactVersion()
end)
