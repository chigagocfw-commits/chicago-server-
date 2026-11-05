

VinewoodPermissions = {}

local cachedFramework, cachedEsx, cachedQbCore

-- Server console log (operational, not debug)
local function Log(message, color)
  print(("%s[%s]^7 %s"):format(color or "^3", GetCurrentResourceName(), message))
end

local function IsStarted(resourceName)
  return GetResourceState(resourceName) == "started"
end

-- Reads Config each call so permission changes apply without a restart
local function GetSettings()
  local perm   = type(Config.Permissions) == "table" and Config.Permissions or {}
  local groups = type(perm.Groups) == "table" and perm.Groups or {}

  local ace = "oxlyn.vinewood"
  if type(perm.Ace) == "string" and perm.Ace ~= "" then
    ace = perm.Ace
  elseif type(Config.Ace) == "string" then
    ace = Config.Ace
  end

  -- Config.ESXGroups wins over Config.Permissions.Groups.esx
  local esx = (type(Config.ESXGroups) == "table" and Config.ESXGroups)
           or (type(groups.esx) == "table" and groups.esx)
           or { admin = true, superadmin = true }

  return {
    ace    = ace,
    custom = type(perm.Custom) == "function" and perm.Custom or nil,
    esx    = esx,
    qbcore = (type(groups.qbcore) == "table" and groups.qbcore) or { admin = true, god = true },
    qbox   = (type(groups.qbox) == "table" and groups.qbox) or { admin = true, god = true },
  }
end

-- Accepts { admin = true } or { "admin" } style tables, returns a plain list of names
local function ToList(set)
  local list = {}
  for key, value in pairs(set) do
    if type(key) == "string" and value == true then
      list[#list + 1] = key
    elseif type(key) == "number" and type(value) == "string" then
      list[#list + 1] = value
    end
  end
  return list
end

local function GetFramework()
  if cachedFramework then return cachedFramework end

  local configured = type(Config.Framework) == "string" and Config.Framework:lower() or "auto"

  if configured == "esx" or configured == "qbcore" or configured == "qbox" or configured == "standalone" then
    cachedFramework = configured
  elseif IsStarted("qbx_core") then
    cachedFramework = "qbox"
  elseif IsStarted("qb-core") then
    cachedFramework = "qbcore"
  elseif IsStarted("es_extended") then
    cachedFramework = "esx"
  else
    cachedFramework = "standalone"
  end

  return cachedFramework
end

-- FIXED: the original shared one cache variable between ESX and QB-Core objects
local function GetEsx()
  if cachedEsx then return cachedEsx end
  local ok, shared = pcall(function() return exports.es_extended:getSharedObject() end)
  if ok and shared then cachedEsx = shared end
  return cachedEsx
end

local function GetQbCore()
  if cachedQbCore then return cachedQbCore end
  local ok, core = pcall(function() return exports["qb-core"]:GetCoreObject() end)
  if ok and core then cachedQbCore = core end
  return cachedQbCore
end

local function HasEsxGroup(src, groups)
  if not IsStarted("es_extended") then return false end

  local esx = GetEsx()
  if not esx then return false end

  local allowedGroups = ToList(groups)
  if #allowedGroups == 0 then return false end

  -- FIXED: removed the "has any string group" shortcut that let every player through
  local ok, allowed = pcall(function()
    local xPlayer = esx.GetPlayerFromId(src)
    local group = xPlayer and xPlayer.getGroup and xPlayer.getGroup()
    for _, name in ipairs(allowedGroups) do
      if name == group then return true end
    end
    return false
  end)

  return ok and allowed == true
end

local function HasQbCoreGroup(src, groups)
  if not IsStarted("qb-core") then return false end

  local core = GetQbCore()
  if not (core and core.Functions and core.Functions.HasPermission) then return false end

  for _, name in ipairs(ToList(groups)) do
    local ok, allowed = pcall(core.Functions.HasPermission, src, name)
    if ok and allowed then return true end
  end
  return false
end

local function HasQboxGroup(src, groups)
  for _, name in ipairs(ToList(groups)) do
    if IsPlayerAceAllowed(src, "group." .. name) then return true end

    if IsStarted("qbx_core") then
      local ok, allowed = pcall(function() return exports.qbx_core:HasPermission(src, name) end)
      if ok and allowed then return true end
    end
  end
  return false
end

function VinewoodPermissions.Framework()
  return GetFramework()
end

-- Order: custom callback -> ACE -> framework groups
function VinewoodPermissions.Allowed(src)
  if type(src) ~= "number" or src <= 0 then return false end

  local settings = GetSettings()

  if settings.custom then
    local ok, result = pcall(settings.custom, src)
    if ok and result == true then return true end
    if not ok then
      Log("Config.Permissions.Custom failed: " .. tostring(result))
    end
  end

  if IsPlayerAceAllowed(src, settings.ace) then return true end

  local framework = GetFramework()
  if framework == "esx" then
    return HasEsxGroup(src, settings.esx)
  elseif framework == "qbcore" then
    return HasQbCoreGroup(src, settings.qbcore)
  elseif framework == "qbox" then
    return HasQboxGroup(src, settings.qbox)
  end

  return false
end

-- Startup info line (delayed so other resources have started and framework detection is accurate)
CreateThread(function()
  Wait(1000)
  Log(("Permissions: framework %s, ACE %s"):format(GetFramework(), GetSettings().ace), "^2")
end)

