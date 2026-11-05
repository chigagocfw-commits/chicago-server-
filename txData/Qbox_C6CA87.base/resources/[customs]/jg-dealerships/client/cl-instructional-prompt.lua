Interactions = Interactions or {}
Interactions.Client = Interactions.Client or {}
Interactions.Client.InstrPrmt = Interactions.Client.InstrPrmt or {}

local lastPromptSignature

local function buildPromptSignature(text, keybinds, wasd)
  local signature = text .. tostring(wasd or "")

  if keybinds then
    for _, keybind in ipairs(keybinds) do
      signature = signature .. keybind.key .. keybind.desc
    end
  end

  return signature
end

function Interactions.Client.InstrPrmt.Show(text, keybinds, wasd, error)
  local promptSignature = buildPromptSignature(text, keybinds, wasd)

  if promptSignature ~= lastPromptSignature then
    PlaySoundFrontend(-1, "OTHER_TEXT", "HUD_AWARDS", false)
    lastPromptSignature = promptSignature
  end

  SendNUIMessage({
    type = "showInstrPrmt",
    text = text,
    keybinds = keybinds,
    wasd = wasd,
    error = error,
  })
end

function Interactions.Client.InstrPrmt.Hide()
  lastPromptSignature = nil
  SendNUIMessage({ type = "hideInstrPrmt" })
end
