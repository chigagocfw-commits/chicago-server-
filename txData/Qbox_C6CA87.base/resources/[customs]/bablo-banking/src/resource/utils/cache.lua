playerCache = {
  states = {},
  lastValues = {},
  interval = 1000
}

function playerCache.watch(key, getter, options)
  Ensure(key, "string")
  Ensure(getter, "function")
  Ensure(options, "table", "nil")

  if options then
    Ensure(options.interval, "number", "nil")
    Ensure(options.onChange, "function", "nil")
  end

  local state = {
    key = key,
    getter = getter,
    interval = options and options.interval or playerCache.interval,
    lastTick = 0,
    onChange = options and options.onChange or nil
  }

  playerCache.states[key] = state
  playerCache.lastValues[key] = getter()
  LocalPlayer.state[key] = playerCache.lastValues[key]
end

function playerCache.unwatch(key)
  Ensure(key, "string")

  if playerCache.states[key] then
    playerCache.states[key] = nil
  end
end

function playerCache.get(key)
  return playerCache.lastValues[key]
end

CreateThread(function()
  while true do
    local currentTick = GetGameTimer()

    for _, state in pairs(playerCache.states) do
      if currentTick - state.lastTick >= state.interval then
        local newValue = state.getter()
        local oldValue = playerCache.lastValues[state.key]

        if not tbl.deepEqual(newValue, oldValue) then
          playerCache.lastValues[state.key] = newValue
          LocalPlayer.state[state.key] = newValue

          if state.onChange then
            state.onChange(newValue, oldValue)
          end
        end

        state.lastTick = currentTick
      end
    end

    Wait(100)
  end
end)
