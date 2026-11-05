

-- Server only
if not IsDuplicityVersion() then
    return
end

Inventory = Inventory or {}

local resourceName = GetCurrentResourceName()

local function isStarted(resource)
    return GetResourceState(resource) == "started"
end

local function debugPrint(message)
    if Config and Config.Debug then
        print(("[%s] %s"):format(resourceName, message))
    end
end

---------------------------------------------------------------------
-- Supported inventory resources
---------------------------------------------------------------------

-- Many inventories share the same shape:
--   AddItem(src, item, count, <slot = nil>, metadata)
--   RemoveItem(src, item, count, ...)
--   <canCarryName>(src, item, count)
-- `opts` tweaks the differences.
local function exportProvider(id, resource, opts)
    opts = opts or {}
    local addMethod      = opts.add or "AddItem"
    local removeMethod   = opts.remove or "RemoveItem"
    local canCarryMethod = opts.canCarry -- nil = provider has no canCarry

    local provider = {
        id = id,
        resource = resource,
        supportsMetadata = true,
    }

    provider.add = function(src, item, count, metadata)
        local e = exports[resource]
        if opts.addSkipsSlot then
            return e[addMethod](e, src, item, count, nil, metadata)
        end
        return e[addMethod](e, src, item, count, metadata)
    end

    if opts.removeTakesFiveArgs then
        provider.remove = function(src, item, count, arg4, arg5)
            local e = exports[resource]
            return e[removeMethod](e, src, item, count, arg4, arg5)
        end
    elseif opts.removeThreeArgs then
        provider.remove = function(src, item, count)
            local e = exports[resource]
            return e[removeMethod](e, src, item, count)
        end
    else
        provider.remove = function(src, item, count, arg4)
            local e = exports[resource]
            return e[removeMethod](e, src, item, count, arg4)
        end
    end

    if canCarryMethod then
        provider.canCarry = function(src, item, count)
            local e = exports[resource]
            return e[canCarryMethod](e, src, item, count)
        end
    end

    return provider
end

local providers = {
    exportProvider("ak47",   "ak47_inventory",   { addSkipsSlot = true, canCarry = "CanCarryItem" }),
    exportProvider("origen", "origen_inventory", { canCarry = "CanCarryItem" }),
    exportProvider("tgiann", "tgiann-inventory", { addSkipsSlot = true, canCarry = "CanCarryItem" }),
    exportProvider("qs",     "qs-inventory",     { addSkipsSlot = true, removeTakesFiveArgs = true, canCarry = "CanCarryItem" }),
    exportProvider("codem",  "codem-inventory",  { addSkipsSlot = true, canCarry = "CanCarryItem" }),
    exportProvider("core",   "core_inventory",   { add = "addItem", remove = "removeItem", removeThreeArgs = true }),
    exportProvider("lj",     "lj-inventory",     { addSkipsSlot = true, canCarry = "CanAddItem" }),
    exportProvider("ps",     "ps-inventory",     { addSkipsSlot = true, canCarry = "CanAddItem" }),

    -- qb-inventory also wants the calling resource name
    {
        id = "qb-inventory",
        resource = "qb-inventory",
        supportsMetadata = true,
        add = function(src, item, count, metadata)
            local e = exports["qb-inventory"]
            return e:AddItem(src, item, count, nil, metadata, resourceName)
        end,
        remove = function(src, item, count, arg4)
            local e = exports["qb-inventory"]
            return e:RemoveItem(src, item, count, arg4, resourceName)
        end,
        canCarry = function(src, item, count)
            local e = exports["qb-inventory"]
            return e:CanAddItem(src, item, count)
        end,
    },

    -- ox_inventory: supports slot-based removal, slot lookup and search
    {
        id = "ox_inventory",
        resource = "ox_inventory",
        supportsMetadata = true,
        add = function(src, item, count, metadata)
            return exports.ox_inventory:AddItem(src, item, count, metadata)
        end,
        remove = function(src, item, count, slot, metadata)
            if slot then
                return exports.ox_inventory:RemoveItem(src, item, count, nil, slot)
            end
            return exports.ox_inventory:RemoveItem(src, item, count, metadata)
        end,
        slot = function(src, slot)
            return exports.ox_inventory:GetSlot(src, slot)
        end,
        canCarry = function(src, item, count, metadata)
            return exports.ox_inventory:CanCarryItem(src, item, count, metadata)
        end,
        search = function(src, item, metadata)
            return exports.ox_inventory:Search(src, "slots", item, metadata)
        end,
    },
}

local providersById = {}
for _, provider in ipairs(providers) do
    providersById[provider.id] = provider
end

---------------------------------------------------------------------
-- Provider detection
---------------------------------------------------------------------

local detectedMode = nil

-- Returns the id of the first running inventory resource, or "esx"/"qb"
-- (the framework's built-in inventory) if none are running. Cached after first call.
function Inventory.Mode()
    if detectedMode then
        return detectedMode
    end

    for _, provider in ipairs(providers) do
        if isStarted(provider.resource) then
            detectedMode = provider.id
            debugPrint("Inventory bridge: " .. provider.id)
            return detectedMode
        end
    end

    detectedMode = Framework.Name == "esx" and "esx" or "qb"
    debugPrint("Inventory bridge: framework (" .. detectedMode .. ")")
    return detectedMode
end

-- The active provider, or nil when using the framework's built-in inventory.
local function getProvider()
    local provider = providersById[Inventory.Mode()]
    if provider and isStarted(provider.resource) then
        return provider
    end
    return nil
end

function Inventory.SupportsMetadata()
    local provider = getProvider()
    if provider then
        return provider.supportsMetadata ~= false
    end
    return Framework.Name ~= "esx"
end

local function normaliseCount(count)
    return math.max(1, math.floor(tonumber(count) or 1))
end

---------------------------------------------------------------------
-- Items
---------------------------------------------------------------------

function Inventory.AddItem(src, item, count, metadata)
    count = normaliseCount(count)

    local provider = getProvider()
    if provider then
        local ok, result = pcall(provider.add, src, item, count, metadata)
        if not ok then
            debugPrint(("AddItem failed on %s: %s"):format(provider.id, tostring(result)))
        end
        return ok and result ~= false and result ~= nil
    end

    local player = Framework.GetPlayer(src)
    if not player then
        return false
    end

    if Framework.Name == "esx" then
        return (pcall(function()
            player.addInventoryItem(item, count)
        end))
    end

    local ok, result = pcall(function()
        return player.Functions.AddItem(item, count, false, metadata)
    end)
    return ok and result ~= false
end

-- `slot` and `metadata` are forwarded to the provider, which decides how to use them.
function Inventory.RemoveItem(src, item, count, slot, metadata)
    count = normaliseCount(count)

    local provider = getProvider()
    if provider then
        local ok, result = pcall(provider.remove, src, item, count, slot, metadata)
        if not ok then
            debugPrint(("RemoveItem failed on %s: %s"):format(provider.id, tostring(result)))
        end
        return ok and result ~= false and result ~= nil
    end

    local player = Framework.GetPlayer(src)
    if not player then
        return false
    end

    if Framework.Name == "esx" then
        return (pcall(function()
            player.removeInventoryItem(item, count)
        end))
    end

    local ok, result = pcall(function()
        return player.Functions.RemoveItem(item, count, slot)
    end)
    return ok and result ~= false
end

-- Returns { name, count, metadata } for a slot, or nil.
-- Only inventories that expose slot lookups (ox_inventory) or QB-style
-- frameworks are supported.
function Inventory.GetSlot(src, slot)
    if not slot then
        return nil
    end

    local provider = getProvider()
    if provider and provider.slot then
        local ok, data = pcall(provider.slot, src, slot)
        if ok and type(data) == "table" then
            return {
                name = data.name,
                count = data.count,
                metadata = data.metadata or data.info,
            }
        end
        return nil
    end

    local player = Framework.GetPlayer(src)
    if not player or Framework.Name == "esx" then
        return nil
    end

    local ok, data = pcall(function()
        return player.Functions.GetItemBySlot(slot)
    end)
    if ok and type(data) == "table" then
        return {
            name = data.name,
            count = data.amount or data.count,
            metadata = data.info or data.metadata,
        }
    end

    return nil
end

-- Finds the slot holding `itemName` whose metadata has the given `contract` value.
function Inventory.FindContractSlot(src, itemName, contract)
    local provider = getProvider()
    if provider and provider.search then
        local ok, results = pcall(provider.search, src, itemName)
        if ok and type(results) == "table" then
            for _, item in pairs(results) do
                if type(item) == "table"
                    and type(item.metadata) == "table"
                    and item.metadata.contract == contract then
                    return item.slot
                end
            end
        end
        return nil
    end

    local player = Framework.GetPlayer(src)
    if not player or Framework.Name == "esx" then
        return nil
    end

    local ok, items = pcall(function()
        return player.PlayerData.items
    end)
    if ok and type(items) == "table" then
        for _, item in pairs(items) do
            if type(item) == "table"
                and item.name == itemName
                and type(item.info) == "table"
                and item.info.contract == contract then
                return item.slot
            end
        end
    end

    return nil
end

-- Returns false only if the inventory explicitly says the player can't carry it.
function Inventory.CanCarry(src, item, count, metadata)
    count = normaliseCount(count)

    local provider = getProvider()
    if provider and provider.canCarry then
        local ok, result = pcall(provider.canCarry, src, item, count, metadata)
        if ok and result ~= nil then
            return result and true or false
        end
    end

    local player = Framework.GetPlayer(src)
    if player and Framework.Name == "esx" and player.canCarryItem then
        local ok, result = pcall(function()
            return player.canCarryItem(item, count)
        end)
        if ok and result ~= nil then
            return result and true or false
        end
    end

    return true
end

---------------------------------------------------------------------
-- Usable items
---------------------------------------------------------------------

-- Registers `handler(src, slot, metadata)` as the use-callback for `itemName`
-- on both the inventory export (ox-style) and the framework. Uses are
-- debounced to once per 400ms per player.
function Inventory.RegisterUsable(itemName, handler)
    local lastUse = {}

    local function debounced(src, slot, metadata)
        local now = GetGameTimer()
        if lastUse[src] and now - lastUse[src] < 400 then
            return
        end
        lastUse[src] = now
        handler(src, slot, metadata)
    end

    -- ox_inventory-style item export; returning false cancels the default use
    exports(itemName, function(event, item, inventory, slot)
        if event ~= "usingItem" then
            return
        end

        local src = type(inventory) == "table" and inventory.id or inventory
        local slotData = Inventory.GetSlot(src, slot)

        debounced(tonumber(src), slot, slotData and slotData.metadata or nil)
        return false
    end)

    Framework.RegisterUsableItem(itemName, debounced)
end

