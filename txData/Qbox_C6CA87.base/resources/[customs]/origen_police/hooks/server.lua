-- Track last execution times for rate limiting
local actionTimers = {}

-- Register a protected server action with security checks
-- @param eventName: Name of the network event
-- @param callback: Function to execute
-- @param timerKey: Key for rate limiting
-- @param minDelay: Minimum delay between executions (ms)
-- @param sourceArgIndex: Index of source argument to validate (optional)
-- @param skipJobCheck: Skip job validation (optional)
function RegisterServerAction(eventName, callback, timerKey, minDelay, sourceArgIndex, skipJobCheck)
  -- Initialize timer tracking for this action type
  actionTimers[timerKey] = actionTimers[timerKey] or {}
  
  RegisterNetEvent(eventName, function(...)
    local playerId = source
    
    if not playerId then
      return
    end
    
    -- Rate limiting check
    local lastExecution = actionTimers[timerKey][playerId]
    if lastExecution then
      local timeSinceLastExecution = GetGameTimer() - lastExecution
      
      if timeSinceLastExecution < minDelay then
        BanPlayer(playerId, "Hook action detect too fast executions in event: " .. eventName)
        return
      end
    end
    
    -- Update last execution time
    actionTimers[timerKey][playerId] = GetGameTimer()
    
    -- Validate source argument if specified
    local sourceArg = nil
    if sourceArgIndex then
      sourceArg = select(sourceArgIndex, ...)
    end
    
    if sourceArg == -1 then
      BanPlayer(playerId, "Hook action with invalid source value in event: " .. eventName)
      return
    end
    
    -- Job validation check
    if not skipJobCheck then
      local canOpen, hasJob = CanOpenTablet(playerId)
      if not canOpen then
        -- Don't ban/kick for job validation, just deny the action
        -- This is a normal case when players without proper jobs try to use police actions
        if Config.Debug then
          print("^3[origen_police]^0 Player " .. playerId .. " attempted action '" .. eventName .. "' without proper job authorization")
        end
        return
      end
    end
    
    -- Execute the callback with all arguments
    callback(...)
  end)
end