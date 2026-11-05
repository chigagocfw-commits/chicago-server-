Interactions = Interactions or {}
Interactions.Client = Interactions.Client or {}
Interactions.Client.TextUIManager = Interactions.Client.TextUIManager or {}

local activePrompts = {}
local currentPromptId
local isActive = false
local lastCallbackAt = {}
local debounceMs = 300

local function updateVisiblePrompt()
  local highestPriority
  local selectedPrompt

  for id, prompt in pairs(activePrompts) do
    if not highestPriority or prompt.priority > highestPriority then
      highestPriority = prompt.priority
      selectedPrompt = {
        id = id,
        data = prompt,
      }
    end
  end

  if selectedPrompt then
    if currentPromptId ~= selectedPrompt.id then
      if isActive then
        Framework.Client.HideTextUI()
      end

      Framework.Client.ShowTextUI(selectedPrompt.data.text)
      currentPromptId = selectedPrompt.id
      isActive = true
    end
  elseif isActive then
    Framework.Client.HideTextUI()
    currentPromptId = nil
    isActive = false
  end
end

function Interactions.Client.TextUIManager.Show(id, text, key, callback)
  activePrompts[id] = {
    text = text,
    key = key,
    callback = callback,
    priority = GetGameTimer(),
  }

  updateVisiblePrompt()
end

function Interactions.Client.TextUIManager.Hide(id)
  if not id then return end

  activePrompts[id] = nil
  lastCallbackAt[id] = nil
  updateVisiblePrompt()
end

function Interactions.Client.TextUIManager.IsActive()
  return isActive
end

function Interactions.Client.TextUIManager.IsShowingId(id)
  return currentPromptId == id
end

function Interactions.Client.TextUIManager.HandleKeyPress()
  if not isActive or not currentPromptId then return end

  local prompt = activePrompts[currentPromptId]
  if not prompt then return end
  if not IsControlJustReleased(0, prompt.key) then return end

  local now = GetGameTimer()
  local lastTriggered = lastCallbackAt[currentPromptId] or 0
  if now - lastTriggered <= debounceMs then return end

  lastCallbackAt[currentPromptId] = now

  local ok, errorMessage = pcall(prompt.callback)
  if not ok then
    print("[TextUIManager] Error in callback:", errorMessage)
  end
end

function Interactions.Client.TextUIManager.ForceHideAll()
  if isActive then
    Framework.Client.HideTextUI()
  end

  activePrompts = {}
  currentPromptId = nil
  isActive = false
  lastCallbackAt = {}
end

AddEventHandler("onResourceStop", function(resourceName)
  if GetCurrentResourceName() == resourceName then
    Interactions.Client.TextUIManager.ForceHideAll()
  end
end)

exports("ForceHideTextUI", function()
  Interactions.Client.TextUIManager.ForceHideAll()
end)
