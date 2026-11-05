Main = {}
Main.peds = {}

if GetCurrentResourceName() ~= "bablo-banking" then
  error("Resource name must be 'bablo-banking'")
  return
end

function Main:createPed(options, onCreated)
  local model = options and options.model
  local coords = options and options.coords

  if not model or not coords then
    Trace("^1createPed missing model or coords^0")
    return nil
  end

  local modelHash = type(model) == "number" and model or GetHashKey(model)
  RequestModel(modelHash)

  local timeout = GetGameTimer() + 10000
  while not HasModelLoaded(modelHash) and timeout > GetGameTimer() do
    Wait(0)
  end

  if not HasModelLoaded(modelHash) then
    Trace("^1Failed to load model: " .. tostring(model) .. "^0")
    return nil
  end

  local ped = CreatePed(0, modelHash, coords.x, coords.y, coords.z, 0.0, false, false)
  SetModelAsNoLongerNeeded(modelHash)

  if type(onCreated) == "function" then
    onCreated(ped)
  end

  return ped
end

function Main:Init()
  Trace("Banking module initialized")

  playerCache.watch("ped", function()
    return PlayerPedId()
  end, {
    interval = 1000,
    onChange = function(ped)
      LocalPlayer.state.ped = ped
    end
  })

  if (Config.BankingInteraction or "ped") == "zone" then
    self:InitZoneInteraction()
  else
    self:InitPedInteraction()
  end
end

function Main:InitPedInteraction()
  for index, bankerCoords in pairs(Config.Bankers) do
    self:createPed({
      model = Config.BankerModels[math.random(1, #Config.BankerModels)],
      coords = bankerCoords.xyz - vector3(0.0, 0.0, 0.97)
    }, function(ped)
      SetEntityHeading(ped, bankerCoords.w)
      FreezeEntityPosition(ped, true)
      SetEntityInvincible(ped, true)
      SetPedDiesWhenInjured(ped, false)
      SetPedHearingRange(ped, 0.0)
      SetPedAlertness(ped, 0)
      SetBlockingOfNonTemporaryEvents(ped, true)
      TaskSetBlockingOfNonTemporaryEvents(ped, true)
      SetPedFleeAttributes(ped, 0, false)
      SetPedCombatAttributes(ped, 46, true)
      SetPedEnableWeaponBlocking(ped, false)
      SetPedKeepTask(ped, true)

      self.peds[index] = ped

      local function addPedTarget(targetPed)
        if type(Target) ~= "table" or type(Target.addTargetEntity) ~= "function" then
          return false
        end

        Target:addTargetEntity(targetPed, {
          label = Translate("OPEN_BANK"),
          icon = "fas fa-building-columns",
          action = function()
            Main:openApp()
          end,
          canInteract = function(entity)
            if not entity or not DoesEntityExist(entity) then
              return false
            end

            if IsPedAPlayer(entity) then
              return false
            end

            return not IsPedInAnyVehicle(PlayerPedId(), false)
          end
        })

        return true
      end

      if not addPedTarget(ped) then
        CreateThread(function()
          local timeout = GetGameTimer() + 5000

          while timeout > GetGameTimer() do
            if addPedTarget(ped) then
              break
            end

            Wait(100)
          end
        end)
      end

      Main:CreateBankBlip(bankerCoords)
    end)
  end
end

function Main:InitZoneInteraction()
  local zoneRadius = Config.ZoneRadius or 2.0
  local isNearby = false
  local textVisible = false

  for _, bankerCoords in pairs(Config.Bankers) do
    self:CreateBankBlip(bankerCoords)
  end

  CreateThread(function()
    while true do
      local ped = PlayerPedId()
      local playerCoords = GetEntityCoords(ped)
      local closestDistance = math.huge

      for _, bankerCoords in pairs(Config.Bankers) do
        local distance = #(playerCoords - bankerCoords.xyz)
        if closestDistance > distance then
          closestDistance = distance
        end
      end

      isNearby = closestDistance <= zoneRadius

      if isNearby then
        if not IsPedInAnyVehicle(ped, false) then
          if not textVisible then
            textVisible = true

            if type(Interaction) == "table" and type(Interaction.ShowTextUI) == "function" then
              Interaction.ShowTextUI("[E] " .. Translate("OPEN_BANK"), {
                icon = "fas fa-building-columns"
              })
            end
          end

          if IsControlJustReleased(0, 38) then
            Main:openApp()
          end
        elseif textVisible then
          textVisible = false

          if type(Interaction) == "table" and type(Interaction.HideTextUI) == "function" then
            Interaction.HideTextUI()
          end
        end

        Wait(0)
      else
        if textVisible then
          textVisible = false

          if type(Interaction) == "table" and type(Interaction.HideTextUI) == "function" then
            Interaction.HideTextUI()
          end
        end

        Wait(500)
      end
    end
  end)
end

function Main:CreateBankBlip(coords)
  if Config.Blip and Config.Blip.Enabled == false then
    return
  end

  local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
  SetBlipSprite(blip, Config.Blip and Config.Blip.Sprite or 108)
  SetBlipDisplay(blip, Config.Blip and Config.Blip.Display or 4)
  SetBlipScale(blip, Config.Blip and Config.Blip.Scale or 0.9)
  SetBlipColour(blip, Config.Blip and Config.Blip.Colour or 3)
  SetBlipAsShortRange(blip, not Config.Blip)

  BeginTextCommandSetBlipName("STRING")
  AddTextComponentSubstringPlayerName(
    (Config.Blip and Config.Blip.Name)
      or (Config.Blip and Config.Blip.NameKey and Translate(Config.Blip.NameKey))
      or Translate("BANK_BLIP_NAME")
  )
  EndTextCommandSetBlipName(blip)
end

local appOpen = false

function Main:openApp()
  appOpen = true
  SetNuiFocus(true, true)

  SendNUIMessage({
    action = "SET_APP_STATE",
    data = true
  })

  SendNUIMessage({
    action = "SHOW_APP",
    data = {
      element = "showApp",
      toggle = true
    }
  })

  if Config and Config.Currency then
    SendNUIMessage({
      action = "SET_CURRENCY",
      data = tostring(Config.Currency)
    })
  end

  if Locales and Config and Config.Locale and Locales[Config.Locale] then
    SendNUIMessage({
      action = "SET_TRANSLATIONS",
      data = {
        locale = Config.Locale,
        translations = Locales[Config.Locale]
      }
    })
  end
end

function Main:closeApp()
  appOpen = false
  SetNuiFocus(false, false)

  SendNUIMessage({
    action = "SET_APP_STATE",
    data = false
  })
end

CreateThread(function()
  while true do
    if appOpen then
      if IsControlJustPressed(0, 200) or IsControlJustPressed(0, 322) then
        Trace("^3[Banking] Emergency close triggered via ESC key^0")
        Main:closeApp()
      end

      Wait(0)
    else
      Wait(500)
    end
  end
end)

exports("CloseBank", function()
  Main:closeApp()
end)

function Main:sendNUIResponse(success, data, message)
  return {
    success = success,
    data = data,
    message = message
  }
end
