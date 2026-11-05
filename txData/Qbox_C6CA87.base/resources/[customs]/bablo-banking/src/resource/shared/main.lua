eventName = "bablo-banking:"
Locales = {}
Inventory = {}

if Config.Framework == "auto" then
  Trace("Detecting framework")

  if IsResourceStartedOrStarting("es_extended") then
    Config.Framework = "esx"
  elseif IsResourceStartedOrStarting("qbx_core") then
    Config.Framework = "qbox"
  elseif IsResourceStartedOrStarting("qb-core") then
    Config.Framework = "qbcore"
  end

  Trace("Detected framework: " .. Config.Framework)
end

if Config.Inventory == "auto" then
  Trace("Detecting inventory")

  if IsResourceStartedOrStarting("tgiann-inventory") then
    Config.Inventory = "tgiann-inventory"
  elseif IsResourceStartedOrStarting("qb-inventory") then
    Config.Inventory = "qb-inventory"
  elseif IsResourceStartedOrStarting("qs-inventory") then
    Config.Inventory = "qs-inventory"
  elseif IsResourceStartedOrStarting("ps-inventory") then
    Config.Inventory = "ps-inventory"
  elseif IsResourceStartedOrStarting("ox_inventory") then
    Config.Inventory = "ox_inventory"
  elseif IsResourceStartedOrStarting("origen_inventory") then
    Config.Inventory = "origen_inventory"
  elseif IsResourceStartedOrStarting("core_inventory") then
    Config.Inventory = "core_inventory"
  elseif IsResourceStartedOrStarting("codem-inventory") then
    Config.Inventory = "codem-inventory"
  end

  Trace("Detected inventory: " .. Config.Inventory)
end

if Config.Target == "auto" then
  Trace("Detecting interactions")

  if IsResourceStartedOrStarting("qb-target") then
    Config.Target = "qb-target"
  elseif IsResourceStartedOrStarting("ox_target") then
    Config.Target = "ox_target"
  else
    Config.Target = "standalone"
  end

  Trace("Detected interactions: " .. Config.Target)
end

if Config.Interaction == "auto" then
  Trace("Detecting interactions")

  if IsResourceStartedOrStarting("ox_lib") then
    Config.Interaction = "ox_lib"
  end

  Trace("Detected interactions: " .. Config.Interaction)
end

exports("GetConfig", function()
  return Config
end)

exports("GetFramework", function()
  return Config.Framework
end)
