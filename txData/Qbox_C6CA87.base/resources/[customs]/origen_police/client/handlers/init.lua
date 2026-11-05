-- Handler Manager System
Handlers = {}
Handlers.__index = Handlers

-- Create new handler manager
function Handlers.new(interval)
    local self = setmetatable({}, Handlers)
    self.interval = interval or 1000
    self.registered = {}
    return self
end

-- Register a new handler
function Handlers:Register(handler)
    if self.registered[handler.name] then
        return
    end
    
    self.registered[handler.name] = handler
    handler.callbacks = {}
    handler.lastResult = nil
    handler.lastExtra = nil
end

-- Add callback to a handler
function Handlers:AddCallback(handlerName, callback)
    if self.registered[handlerName] then
        table.insert(self.registered[handlerName].callbacks, callback)
    end
end

-- Start the handler manager
function Handlers:Start()
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(self.interval)
            
            -- Check if any handlers are registered
            if not next(self.registered) then
                Citizen.Wait(1000)
            else
                -- Process each registered handler
                for _, handler in pairs(self.registered) do
                    local result, extra = handler:check()
                    
                    -- Only trigger callbacks if result changed
                    if result ~= handler.lastResult then
                        handler.lastResult = result
                        handler.lastExtra = extra
                        
                        -- Execute all callbacks
                        for _, callback in ipairs(handler.callbacks) do
                            callback(result, extra)
                        end
                    end
                end
            end
        end
    end)
end

-- Initialize handler manager
HandlerManager = Handlers.new(1000)
HandlerManager:Register(VehicleSitHandler)
HandlerManager:Start()