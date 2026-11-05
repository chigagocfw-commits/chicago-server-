local minigameRunning = false
local lastResult = 123
local updateSpeed = 20
local uiCurrentlyShown = false
local targetZoneWidth = nil
local currentDifficulty = nil
local indicatorAngle = nil
local currentProgress = 0
indicatorPosNum = 0
local completionCallback = nil

function startMinigame()
  setDifficulty()
  indicatorPosition()
  
  if uiCurrentlyShown == true then
    SendNUIMessage({
      showUI = false
    })
    uiCurrentlyShown = false
  else
    SendNUIMessage({
      showUI = true
    })
    uiCurrentlyShown = true
  end
  
  minigameRunning = true
end

function stopMinigame()
  SendNUIMessage({
    showUI = false
  })
  uiCurrentlyShown = false
  minigameRunning = false
end

function setDifficulty()
  if currentDifficulty == 1 then
    targetZoneWidth = math.random(9, 15)
  elseif currentDifficulty == 2 then
    targetZoneWidth = math.random(6, 9)
  elseif currentDifficulty == 3 then
    targetZoneWidth = math.random(2, 6)
  end
  
  SendNUIMessage({
    setDifficulty = targetZoneWidth
  })
end

function indicatorPosition()
  local randomAngle = math.random(90, 300)
  indicatorAngle = randomAngle - 90
  
  local calculatedPos = indicatorAngle + 90
  calculatedPos = calculatedPos / 360
  calculatedPos = calculatedPos * 100
  calculatedPos = calculatedPos - 100
  calculatedPos = calculatedPos * -1
  
  indicatorPosNum = calculatedPos
  
  SendNUIMessage({
    indicator = indicatorAngle
  })
end

CreateThread(function()
  while true do
    if minigameRunning == true then
      if currentProgress < 100 then
        currentProgress = currentProgress + 1
        
        local controlPressed = IsDisabledControlPressed(0, 80)
        if controlPressed then
          local targetPosition = indicatorPosNum + targetZoneWidth
          
          if targetPosition > currentProgress and currentProgress > indicatorPosNum then
            if completionCallback then
              completionCallback(true)
            end
            lastResult = true
          else
            if completionCallback then
              completionCallback(false)
            end
            lastResult = false
          end
          
          minigameRunning = false
          SendNUIMessage({
            showUI = false
          })
          uiCurrentlyShown = false
          currentProgress = 0
        end
      else
        if completionCallback then
          completionCallback(false)
        end
        lastResult = false
        minigameRunning = false
        SendNUIMessage({
          showUI = false
        })
        uiCurrentlyShown = false
        currentProgress = 0
      end
      
      SendNUIMessage({
        progress = currentProgress
      })
    end
    Wait(updateSpeed)
  end
end)

AddEventHandler("minerjob_minigame:start", function(difficultyLevel, gameSpeed, callbackFunction)
  updateSpeed = gameSpeed
  currentDifficulty = difficultyLevel
  completionCallback = callbackFunction
  startMinigame()
end)