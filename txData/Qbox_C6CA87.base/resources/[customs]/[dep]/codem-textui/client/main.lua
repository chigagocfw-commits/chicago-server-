
nuiLoaded = false

-- Blocks execution in the current thread until the NUI is confirmed loaded.
-- Yields every 0ms (next tick) while waiting.
function checkNUI()
  while true do
    if nuiLoaded then
      break
    end
    Wait(0)
  end
end

-- Sends a structured NUI message to the HTML front-end.
-- @param action  string  The action identifier (e.g. "SHOW_TEXTUI")
-- @param payload any     Optional data payload to send alongside the action
function NuiMessage(action, payload)
  checkNUI()
  SendNUIMessage({
    action  = action,
    payload = payload,
  })
end

-- Background thread: polls every 2 seconds until the network session is active,
-- then sends a "CHECK_NUI" message to the front-end to trigger its ready callback.
CreateThread(function()
  while true do
    if nuiLoaded then
      break
    end

    local sessionStarted = NetworkIsSessionStarted()
    if sessionStarted then
      SendNUIMessage({
        action = "CHECK_NUI",
      })
    end

    Wait(2000)
  end
end)

-- NUI callback registered on the front-end side.
-- When the HTML UI is ready it calls "checkNUI" back into Lua,
-- setting nuiLoaded = true and acknowledging with "ok".
RegisterNUICallback("checkNUI", function(data, cb)
  nuiLoaded = true
  cb("ok")
end)

-- Opens the TextUI overlay in the NUI with the provided content.
-- @param message  string  The text to display in the UI
-- @param key      string  The key hint to show (e.g. "[E]")
-- @param thema    string  The visual theme / colour scheme to apply
function OpenTextUI(message, key, thema)
  checkNUI()
  local payload = {
    message = message,
    key     = key,
    thema   = thema,
  }
  NuiMessage("SHOW_TEXTUI", payload)
end

-- Closes / hides the TextUI overlay in the NUI.
function CloseTextUI()
  NuiMessage("CLOSE_TEXTUI")
end

-- Net event: allows a server-side script to open the TextUI on this client.
-- @param message  string  The text to display
-- @param key      string  The key hint label
-- @param thema    string  The visual theme
RegisterNetEvent("codem-textui:ShowTextUI")
AddEventHandler("codem-textui:ShowTextUI", function(message, key, thema)
  OpenTextUI(message, key, thema)
end)

-- Net event: allows a server-side script to close the TextUI on this client.
RegisterNetEvent("codem-textui:CloseTextUI")
AddEventHandler("codem-textui:CloseTextUI", function()
  CloseTextUI()
end)

