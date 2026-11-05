Modules = {}

local isClient = not IsDuplicityVersion()
local clientEntries = { "multichar_client", "session" }
local serverEntries = { "multichar_server" }

local registeredModules = {}
local initializingModules = {}
local allInitialized = false
local initCallbacks = {}
local isInitializing = false
local registeredEntries = {}
local resolvedEntries = {}
local pendingEntryCallbacks = {}

function ResolveLoadOrder(moduleName, resolved, visiting)
    if visiting[moduleName] then
        local cycle = { moduleName }
        local found = false
        for i = #resolved, 1, -1 do
            if found then
                cycle[#cycle + 1] = resolved[i]
            end
            if resolved[i] == moduleName then
                found = true
                cycle[#cycle + 1] = resolved[i]
            end
        end
        lib.print.error(string.format("Circular dependency detected: %s", table.concat(cycle, " -> ")))
        return nil
    end

    if resolved[moduleName] then
        return {}
    end

    local mod = registeredModules[moduleName]
    if not mod then
        return nil
    end

    resolved[moduleName] = true
    visiting[moduleName] = true
    resolved[#resolved + 1] = moduleName

    local loadOrder = {}
    for i = 1, #mod.dependencies do
        local depName = mod.dependencies[i]
        local depOrder = ResolveLoadOrder(depName, resolved, visiting)
        if depOrder then
            for j = 1, #depOrder do
                local alreadyPresent = false
                for k = 1, #loadOrder do
                    if loadOrder[k] == depOrder[j] then
                        alreadyPresent = true
                        break
                    end
                end
                if not alreadyPresent then
                    loadOrder[#loadOrder + 1] = depOrder[j]
                end
            end
        end
    end

    visiting[moduleName] = nil

    local hasSelf = false
    for i = 1, #loadOrder do
        if loadOrder[i] == moduleName then
            hasSelf = true
            break
        end
    end
    if not hasSelf then
        loadOrder[#loadOrder + 1] = moduleName
    end

    return loadOrder
end

function InitModule(moduleName)
    local mod = registeredModules[moduleName]
    if not mod then
        lib.print.warn(string.format("Cannot init unknown module: %s", moduleName))
        return false
    end

    if mod.initialized then
        return true
    end

    if initializingModules[moduleName] then
        return true
    end

    initializingModules[moduleName] = true

    for i = 1, #mod.dependencies do
        local depName = mod.dependencies[i]
        local depMod = registeredModules[depName]
        if not depMod then
            lib.print.warn(string.format("Module '%s' depends on unregistered module '%s'", moduleName, depName))
        else
            if not depMod.initialized then
                InitModule(depName)
            end
        end
    end

    for i = 1, #mod.optionalDependencies do
        local optDepName = mod.optionalDependencies[i]
        local optMod = registeredModules[optDepName]
        if optMod and not optMod.initialized then
            InitModule(optDepName)
        end
    end

    if mod.init then
        local ok, err = pcall(mod.init)
        if not ok then
            lib.print.error(string.format("Failed to initialize module '%s': %s", moduleName, tostring(err)))
        end
    end

    mod.initialized = true
    initializingModules[moduleName] = nil

    if initCallbacks[moduleName] then
        for i = 1, #initCallbacks[moduleName] do
            local cb = initCallbacks[moduleName][i]
            local ok, err = pcall(cb, mod.module)
            if not ok then
                lib.print.error(string.format("Callback error for module '%s': %s", moduleName, tostring(err)))
            end
        end
        initCallbacks[moduleName] = nil
    end

    return true
end

function Modules.register(name, moduleTable, options)
    local shouldMerge = false
    local dependencies = {}
    local optionalDependencies = {}

    if type(options) == "boolean" then
        shouldMerge = options
    elseif type(options) == "table" then
        shouldMerge = options.merge or false
        dependencies = options.dependencies or {}
        optionalDependencies = options.optionalDependencies or {}
    end

    if registeredModules[name] and not shouldMerge then
        lib.print.warn(string.format("Module '%s' already registered, use merge option to extend", name))
    end

    if registeredModules[name] and shouldMerge then
        for key, value in pairs(moduleTable) do
            registeredModules[name].module[key] = value
        end

        if moduleTable.init and not registeredModules[name].init then
            registeredModules[name].init = moduleTable.init
        end

        for i = 1, #dependencies do
            local dep = dependencies[i]
            local found = false
            for j = 1, #registeredModules[name].dependencies do
                if registeredModules[name].dependencies[j] == dep then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(registeredModules[name].dependencies, dep)
            end
        end
    else
        registeredModules[name] = {
            name = name,
            module = moduleTable,
            dependencies = dependencies,
            optionalDependencies = optionalDependencies,
            init = moduleTable.init,
            initialized = false,
            loaded = true
        }
    end

    moduleTable.loaded = true

    if allInitialized and not registeredModules[name].initialized then
        InitModule(name)
    end
end

function Modules.require(name)
    local mod = registeredModules[name]
    if not mod then
        lib.print.error(string.format("Module '%s' not found", name))
        return {}
    end
    return mod.module
end

function Modules.get(name)
    if registeredModules[name] then
        return registeredModules[name].module
    end
    return nil
end

function Modules.isLoaded(name)
    return registeredModules[name] ~= nil
end

function Modules.isInitialized(name)
    if not name then
        return allInitialized
    end
    return registeredModules[name] ~= nil and registeredModules[name].initialized
end

function Modules.waitFor(moduleNames, timeout)
    timeout = timeout or 10000
    local startTime = GetGameTimer()

    for i = 1, #moduleNames do
        local modName = moduleNames[i]
        while not registeredModules[modName] do
            if GetGameTimer() - startTime > timeout then
                lib.print.error(string.format("Timeout waiting for module '%s' to register", modName))
                return false
            end
            Wait(50)
        end
    end

    return true
end

function Modules.awaitInit(moduleNames, timeout)
    timeout = timeout or 10000
    local startTime = GetGameTimer()

    for i = 1, #moduleNames do
        local modName = moduleNames[i]
        while true do
            if registeredModules[modName] and registeredModules[modName].initialized then
                break
            end
            if GetGameTimer() - startTime > timeout then
                lib.print.error(string.format("Timeout waiting for module '%s' to initialize", modName))
                return false
            end
            Wait(50)
        end
    end

    return true
end

function Modules.onInit(name, callback)
    if registeredModules[name] and registeredModules[name].initialized then
        local ok, err = pcall(callback, registeredModules[name].module)
        if not ok then
            lib.print.error(string.format("Callback error for module '%s': %s", name, tostring(err)))
        end
        return
    end

    initCallbacks[name] = initCallbacks[name] or {}
    table.insert(initCallbacks[name], callback)
end

function Modules.initAll(delay)
    if allInitialized or isInitializing then
        return
    end

    isInitializing = true

    if delay and delay > 0 then
        Wait(delay)
    end

    local moduleNames = {}
    for name in pairs(registeredModules) do
        table.insert(moduleNames, name)
    end

    local loadOrder = {}
    local visited = {}

    for i = 1, #moduleNames do
        local order = ResolveLoadOrder(moduleNames[i], {}, {})
        if order then
            for j = 1, #order do
                local modName = order[j]
                if not visited[modName] then
                    visited[modName] = true
                    table.insert(loadOrder, modName)
                end
            end
        end
    end

    for i = 1, #loadOrder do
        InitModule(loadOrder[i])
    end

    allInitialized = true
    isInitializing = false
end

function Modules.init(name)
    local mod = registeredModules[name]
    if not mod then
        lib.print.error(string.format("Cannot init unknown module: %s", name))
        return false
    end

    if mod.initialized then
        return true
    end

    local order = ResolveLoadOrder(name, {}, {})
    if not order then
        return false
    end

    for i = 1, #order do
        InitModule(order[i])
    end

    return mod.initialized
end

function Modules.isAllInitialized()
    return allInitialized
end

function Modules.getRegistered()
    local names = {}
    for name in pairs(registeredModules) do
        table.insert(names, name)
    end
    return names
end

function Modules.getStatus(name)
    if name then
        local mod = registeredModules[name]
        if not mod then
            return { exists = false }
        end
        return {
            exists = true,
            loaded = mod.loaded,
            initialized = mod.initialized,
            dependencies = mod.dependencies,
            hasInit = mod.init ~= nil
        }
    end

    local status = {}
    for k, mod in pairs(registeredModules) do
        status[k] = {
            loaded = mod.loaded,
            initialized = mod.initialized,
            dependencies = mod.dependencies,
            hasInit = mod.init ~= nil
        }
    end
    return status
end

function Modules.reset()
    registeredModules = {}
    initializingModules = {}
    allInitialized = false
    initCallbacks = {}
    isInitializing = false
    registeredEntries = {}
    resolvedEntries = {}
    pendingEntryCallbacks = {}
end

function Modules.getAll()
    local all = {}
    for k, mod in pairs(registeredModules) do
        all[k] = mod.module
    end
    return all
end

local entriesToRegister = isClient and clientEntries or serverEntries
for i = 1, #entriesToRegister do
    registeredEntries[entriesToRegister[i]] = true
end

function Modules.registerEntry(entryName)
    registeredEntries[entryName] = true
end

function Modules.resolveEntry(entryName)
    if not registeredEntries[entryName] then
        lib.print.warn(string.format("resolveEntry called for unregistered entry: %s", entryName))
    end

    resolvedEntries[entryName] = true

    if Modules.allEntriesResolved() then
        for i = 1, #pendingEntryCallbacks do
            local ok, err = pcall(pendingEntryCallbacks[i])
            if not ok then
                lib.print.error(string.format("Entry callback error: %s", tostring(err)))
            end
        end
        pendingEntryCallbacks = {}
    end
end

function Modules.isEntryResolved(entryName)
    return resolvedEntries[entryName] == true
end

function Modules.allEntriesResolved()
    for entry in pairs(registeredEntries) do
        if not resolvedEntries[entry] then
            return false
        end
    end
    return true
end

function Modules.awaitEntries(timeout)
    timeout = timeout or 10000
    local result = lib.waitFor(
        Modules.allEntriesResolved,
        string.format("Timed out waiting for entries: %s", table.concat(Modules.getPendingEntries(), ", ")),
        timeout
    )
    return result ~= nil
end

function Modules.onEntriesResolved(callback)
    if Modules.allEntriesResolved() then
        local ok, err = pcall(callback)
        if not ok then
            lib.print.error(string.format("Entry callback error: %s", tostring(err)))
        end
        return
    end
    table.insert(pendingEntryCallbacks, callback)
end

function Modules.getPendingEntries()
    local pending = {}
    for entry in pairs(registeredEntries) do
        if not resolvedEntries[entry] then
            table.insert(pending, entry)
        end
    end
    return pending
end

function Modules.getEntries()
    local entries = {}
    for entry in pairs(registeredEntries) do
        table.insert(entries, entry)
    end
    return entries
end

function Modules.isFullyReady()
    return allInitialized and Modules.allEntriesResolved()
end

function Modules.awaitFullyReady(timeout)
    timeout = timeout or 10000
    local startTime = GetGameTimer()

    while not allInitialized do
        if GetGameTimer() - startTime > timeout then
            lib.print.error("Timeout waiting for modules to initialize")
            return false
        end
        Wait(50)
    end

    local remainingTime = timeout - (GetGameTimer() - startTime)
    if remainingTime <= 0 then
        lib.print.error("Timeout waiting for entries to resolve")
        return false
    end

    return Modules.awaitEntries(remainingTime)
end
