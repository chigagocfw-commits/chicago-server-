

-- Vehicle sale contracts: seller offers a contract to a passenger, who signs
-- and pays; ownership is transferred in the DB.

Contract = Contract or {}

local RESOURCE = GetCurrentResourceName()

local function log(message)
    print(("[%s] %s"):format(RESOURCE, message))
end

local function debugLog(message)
    if Config.Debug then log(message) end
end

local contracts = {}       -- contract id -> contract
local lockedPlates = {}    -- plate key -> contract id
local activeBySource = {}  -- player source -> contract id (seller or buyer)

local function cfg()
    return Config.Contract or {}
end

local function itemName()
    return cfg().item or "vehicle_contract"
end

local function fail(cb, key, ...)
    cb({ ok = false, error = key, message = _U(key, ...) })
end

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

local ID_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

local function newContractId()
    for _ = 1, 20 do
        local chars = {}
        for i = 1, 8 do
            local r = math.random(1, #ID_ALPHABET)
            chars[i] = ID_ALPHABET:sub(r, r)
        end

        local id = "OX-" .. table.concat(chars)
        if not contracts[id] and not DB.ContractExists(id) then
            return id
        end
    end

    return "OX-" .. tostring(os.time())
end

local function vehiclePlate(entity)
    local ok, text = pcall(GetVehicleNumberPlateText, entity)
    return ok and Utils.Trim(text or "") or ""
end

-- Returns vehicle, seat for the vehicle the player is in
local function playerVehicle(src)
    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return nil end

    local ok, veh = pcall(GetVehiclePedIsIn, ped, false)
    if not (ok and veh and veh ~= 0 and DoesEntityExist(veh)) then
        return nil
    end

    for seat = -1, 7 do
        if GetPedInVehicleSeat(veh, seat) == ped then
            return veh, seat
        end
    end

    return nil
end

-- Everyone sitting in `veh` except `excludeSrc`
local function listPassengers(veh, excludeSrc)
    local list = {}

    for _, playerId in ipairs(GetPlayers()) do
        local id = tonumber(playerId)
        if id and id ~= excludeSrc then
            local ped = GetPlayerPed(id)
            if ped and ped ~= 0 then
                for seat = -1, 7 do
                    if GetPedInVehicleSeat(veh, seat) == ped then
                        list[#list + 1] = { id = id, name = Framework.GetName(id), seat = seat }
                        break
                    end
                end
            end
        end
    end

    return list
end

local function isInVehicle(veh, src)
    local ped = GetPlayerPed(src)
    if not (ped and ped ~= 0 and veh and DoesEntityExist(veh)) then
        return false
    end

    for seat = -1, 7 do
        if GetPedInVehicleSeat(veh, seat) == ped then
            return true
        end
    end

    return false
end

local function vehicleLabel(v)
    return (v.meta and v.meta.nickname)
        or (v.meta and v.meta.label)
        or v.modelName
        or v.plate
end

-- Client-facing view of a contract
local function paperView(c)
    return {
        id = c.id,
        no = c.id,
        date = c.date,
        createdAt = c.createdAt,
        expiresAt = c.expiresAt,
        now = os.time(),
        seller = c.sellerName,
        buyer = c.buyerName,
        buyerId = c.buyerSrc,
        vehicle = {
            plate = c.plateRaw,
            key = c.key,
            model = c.model,
            modelName = c.modelName,
            label = c.label,
            condition = c.condition,
            props = c.props,
            vtype = c.vtype,
        },
        price = c.price,
        tax = c.tax,
        total = c.price,
        net = c.price - c.tax,
        status = c.status,
        accounts = cfg().accounts or { "cash", "bank" },
    }
end

-- Tells both parties' UIs the contract status changed
local function pushStatus(c, status, extra)
    local payload = { id = c.id, status = status }
    if extra then
        for k, v in pairs(extra) do payload[k] = v end
    end

    if c.sellerSrc then
        TriggerClientEvent(RESOURCE .. ":client:contractStatus", c.sellerSrc, payload)
    end
    if c.buyerSrc then
        TriggerClientEvent(RESOURCE .. ":client:contractStatus", c.buyerSrc, payload)
    end
end

-- Ends a contract (expired / cancelled / declined / paid), freeing all locks
local function closeContract(c, status)
    if not contracts[c.id] then return end
    contracts[c.id] = nil

    if lockedPlates[c.key] == c.id then
        lockedPlates[c.key] = nil
    end
    if activeBySource[c.sellerSrc] == c.id then
        activeBySource[c.sellerSrc] = nil
    end
    if c.buyerSrc and activeBySource[c.buyerSrc] == c.id then
        activeBySource[c.buyerSrc] = nil
    end

    c.status = status

    -- "paid" is resolved as "accepted" by the pay callback itself
    if status ~= "paid" and not c.demo then
        DB.ResolveContract(c.id, status, false)
    end

    pushStatus(c, status)

    if not c.demo then
        TriggerEvent(RESOURCE .. ":server:contractClosed", c.id, status)
    end
end

--------------------------------------------------------------------------------
-- Showcase (demo) buyer: an NPC "buys" the car, nothing is transferred
--------------------------------------------------------------------------------

local demoBuyers = {} -- admin source -> { name, seated }

local DEMO_NAMES = {
    female = { "Maria Sousa", "Sofia Almeida", "Emma Walker", "Chloe Martin" },
    male   = { "Daniel Costa", "James Carter", "Lucas Ferreira", "Noah Bennett" },
}

-- Adds the NPC to the passenger list (id -1) if they're seated
local function appendDemoPassenger(list, src)
    local demo = demoBuyers[src]
    if demo and demo.seated then
        list[#list + 1] = { id = -1, name = demo.name, seat = 0, demo = true }
    end
    return list
end

Framework.RegisterCallback("contract:demo", function(source, cb)
    if not cfg().enabled then
        return fail(cb, "contract_disabled")
    end
    if not Framework.IsAdmin(source) then
        return fail(cb, "no_permission")
    end
    if activeBySource[source] then
        return fail(cb, "contract_busy")
    end

    local female = math.random(1, 2) == 1
    local pool = female and DEMO_NAMES.female or DEMO_NAMES.male

    demoBuyers[source] = { name = pool[math.random(1, #pool)], seated = false }

    cb({ ok = true, name = demoBuyers[source].name, female = female })
end)

RegisterNetEvent(RESOURCE .. ":sv:contractDemoSeated", function(seated)
    local src = source
    if demoBuyers[src] then
        demoBuyers[src].seated = seated == true
    end
end)

AddEventHandler("playerDropped", function()
    demoBuyers[source] = nil
end)

local function createDemoContract(src, cb, vehicle, plateKey, owned, price)
    local demo = demoBuyers[src]
    if not (demo and demo.seated) then
        return fail(cb, "contract_no_passenger")
    end

    local now = os.time()
    local c = {
        id = newContractId(),
        key = plateKey,
        plateRaw = owned.plate,
        netId = NetworkGetNetworkIdFromEntity(vehicle),
        demo = true,
        seller = Framework.GetIdentifier(src),
        sellerSrc = src,
        sellerName = Framework.GetName(src),
        buyer = "showcase",
        buyerName = demo.name,
        model = owned.model or GetEntityModel(vehicle),
        modelName = owned.modelName,
        label = vehicleLabel(owned),
        condition = Utils.Condition(owned.props),
        props = owned.props,
        vtype = (owned.meta and owned.meta.vtype) or nil,
        price = price,
        tax = math.floor(price * ((cfg().tax or 0) / 100)),
        status = "pending",
        createdAt = now,
        expiresAt = now + math.max(1, cfg().offerMinutes or 5) * 60,
        date = os.date("%d/%m/%Y", now),
    }

    contracts[c.id] = c
    lockedPlates[plateKey] = c.id
    activeBySource[src] = c.id

    log(("showcase contract %s: %s → %s (NPC) — nothing is transferred"):format(c.id, c.sellerName, demo.name))

    cb({ ok = true, paper = paperView(c), message = _U("contract_offered", demo.name) })

    -- Script the NPC: signs after 3.5s, pays after 7.5s
    SetTimeout(3500, function()
        if contracts[c.id] ~= c or c.status ~= "pending" then return end

        c.status = "signed"
        pushStatus(c, "signed")
        Framework.Notify(src, _U("contract_signed_notify", c.buyerName), "info")
    end)

    SetTimeout(7500, function()
        if contracts[c.id] ~= c or c.status ~= "signed" then return end

        closeContract(c, "paid")
        Framework.Notify(src, _U("contract_paid_seller", c.buyerName, Utils.Money(c.price - c.tax), c.label), "success")

        if demoBuyers[src] then
            demoBuyers[src].seated = false
        end
        TriggerClientEvent(RESOURCE .. ":client:contractDemoDone", src)
    end)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function Contract.IsLocked(plateKey)
    return lockedPlates[plateKey] ~= nil
end

function Contract.SessionForPlate(plateKey)
    local c = lockedPlates[plateKey] and contracts[lockedPlates[plateKey]]
    if not c then return nil end

    return {
        id = c.id,
        buyer = c.buyerName,
        price = c.price,
        expiresAt = c.expiresAt,
        status = c.status,
    }
end

-- Called when the contract item is used: opens the seller UI
function Contract.Use(src, slot)
    if not cfg().enabled then
        return Framework.Notify(src, _U("contract_disabled"), "error")
    end
    if not DB.Ready then
        return Framework.Notify(src, _U("not_loaded"), "error")
    end
    if activeBySource[src] then
        return Framework.Notify(src, _U("contract_busy"), "error")
    end

    local vehicle = playerVehicle(src)
    if not vehicle then
        return Framework.Notify(src, _U("contract_not_in_vehicle"), "error")
    end

    local key = Utils.PlateKey(vehiclePlate(vehicle))
    local owned = (key ~= "") and DB.GetByPlate(key) or nil

    if not (owned and owned.owner == Framework.GetIdentifier(src)) then
        return Framework.Notify(src, _U("contract_not_owner"), "error")
    end
    if owned.state == "impounded" then
        return Framework.Notify(src, _U("vehicle_impounded"), "error")
    end
    if lockedPlates[key] then
        return Framework.Notify(src, _U("contract_locked"), "error")
    end

    TriggerClientEvent(RESOURCE .. ":client:contractSeller", src, {
        slot = slot,
        netId = NetworkGetNetworkIdFromEntity(vehicle),
        vehicle = {
            plate = owned.plate,
            key = key,
            model = owned.model or GetEntityModel(vehicle),
            modelName = owned.modelName,
            label = (owned.meta and owned.meta.label) or nil,
            condition = Utils.Condition(owned.props),
            props = owned.props,
            vtype = (owned.meta and owned.meta.vtype) or nil,
        },
        passengers = appendDemoPassenger(listPassengers(vehicle, src), src),
        limits = {
            min = cfg().minPrice or 1,
            max = cfg().maxPrice or 50000000,
            tax = cfg().tax or 0,
            minutes = cfg().offerMinutes or 5,
        },
        sellerName = Framework.GetName(src),
        date = os.date("%d/%m/%Y"),
        now = os.time(),
    })
end

--------------------------------------------------------------------------------
-- Callbacks
--------------------------------------------------------------------------------

Framework.RegisterCallback("contract:passengers", function(source, cb)
    local vehicle = playerVehicle(source)
    if not vehicle then
        return cb({})
    end

    cb(appendDemoPassenger(listPassengers(vehicle, source), source))
end)

Framework.RegisterCallback("contract:offer", function(source, cb, price, buyerId, slot)
    if not cfg().enabled then return fail(cb, "contract_disabled") end
    if not DB.Ready then return fail(cb, "not_loaded") end
    if activeBySource[source] then return fail(cb, "contract_busy") end

    price = math.floor(tonumber(price) or 0)
    local minPrice = cfg().minPrice or 1
    local maxPrice = cfg().maxPrice or 50000000

    if price < minPrice or price > maxPrice then
        return fail(cb, "contract_price", Utils.Money(minPrice), Utils.Money(maxPrice))
    end

    local vehicle = playerVehicle(source)
    if not vehicle then return fail(cb, "contract_not_in_vehicle") end

    local key = Utils.PlateKey(vehiclePlate(vehicle))
    local sellerIdentifier = Framework.GetIdentifier(source)
    local owned = (key ~= "") and DB.GetByPlate(key) or nil

    if not (owned and owned.owner == sellerIdentifier) then
        return fail(cb, "contract_not_owner")
    end
    if owned.state == "impounded" then return fail(cb, "vehicle_impounded") end
    if lockedPlates[key] then return fail(cb, "contract_locked") end
    if Vehicles.IsRecovering(key) then return fail(cb, "vehicle_out") end

    -- Showcase mode (NPC buyer)
    if tonumber(buyerId) == -1 then
        return createDemoContract(source, cb, vehicle, key, owned, price)
    end

    -- Real buyer: must be a different player sitting in the same vehicle
    local buyer = tonumber(buyerId)
    if not (buyer and buyer ~= source and GetPlayerName(buyer) and isInVehicle(vehicle, buyer)) then
        return fail(cb, "contract_no_passenger")
    end
    if activeBySource[buyer] then return fail(cb, "contract_buyer_busy") end
    if not Framework.IsLoaded(buyer) then return fail(cb, "contract_no_passenger") end

    local buyerIdentifier = Framework.GetIdentifier(buyer)
    if buyerIdentifier == sellerIdentifier then
        return fail(cb, "contract_self")
    end

    local maxVehicles = Config.Garage.maxVehiclesPerPlayer or 0
    if maxVehicles > 0 and maxVehicles <= DB.CountOwned(buyerIdentifier) then
        return fail(cb, "contract_max_vehicles")
    end

    -- Only remember the inventory slot if it still holds the contract item
    if slot then
        local slotItem = Inventory.GetSlot(source, slot)
        if slotItem and slotItem.name ~= itemName() then
            slot = nil
        end
    end

    local now = os.time()
    local c = {
        id = newContractId(),
        key = key,
        plateRaw = owned.plate,
        netId = NetworkGetNetworkIdFromEntity(vehicle),
        seller = sellerIdentifier,
        sellerSrc = source,
        sellerName = Framework.GetName(source),
        buyer = buyerIdentifier,
        buyerSrc = buyer,
        buyerName = Framework.GetName(buyer),
        model = owned.model or GetEntityModel(vehicle),
        modelName = owned.modelName,
        label = vehicleLabel(owned),
        condition = Utils.Condition(owned.props),
        props = owned.props,
        vtype = (owned.meta and owned.meta.vtype) or nil,
        price = price,
        tax = math.floor(price * ((cfg().tax or 0) / 100)),
        slot = slot,
        status = "pending",
        createdAt = now,
        expiresAt = now + math.max(1, cfg().offerMinutes or 5) * 60,
        date = os.date("%d/%m/%Y", now),
    }

    -- Re-check after the lookups above
    if Vehicles.IsRecovering(key) then
        return fail(cb, "vehicle_out")
    end

    contracts[c.id] = c
    lockedPlates[key] = c.id
    activeBySource[source] = c.id
    activeBySource[buyer] = c.id

    DB.CreateContract({
        id = c.id,
        plate = key,
        seller = sellerIdentifier,
        sellerName = c.sellerName,
        buyer = buyerIdentifier,
        buyerName = c.buyerName,
        price = price,
        model = tostring(c.model or ""),
        label = c.label,
        createdAt = now,
        expiresAt = c.expiresAt,
        data = { condition = c.condition, plateRaw = owned.plate, tax = c.tax },
    })

    local paper = paperView(c)
    paper.balances = {
        cash = Framework.GetMoney(buyer, "cash"),
        bank = Framework.GetMoney(buyer, "bank"),
    }

    TriggerClientEvent(RESOURCE .. ":client:contractBuyer", buyer, paper)
    Framework.Notify(buyer, _U("contract_offer_received", c.sellerName, c.label, Utils.Money(price)), "info")

    TriggerEvent(RESOURCE .. ":server:contractCreated", c.id, sellerIdentifier, buyerIdentifier, key, price)

    cb({ ok = true, paper = paperView(c), message = _U("contract_offered", c.buyerName) })
end)

-- Looks up a contract the player is part of; closes it if it has expired
local function getContractFor(id, src)
    local c = contracts[tostring(id or "")]
    if not c then return nil end

    if c.sellerSrc ~= src and c.buyerSrc ~= src then
        return nil
    end

    if c.expiresAt < os.time() then
        closeContract(c, "expired")
        return nil
    end

    return c
end

Framework.RegisterCallback("contract:sign", function(source, cb, id)
    local c = getContractFor(id, source)
    if not (c and c.buyerSrc == source) then
        return fail(cb, "contract_invalid")
    end

    if c.status == "pending" then
        c.status = "signed"
        DB.SetContractStatus(c.id, "signed")
        pushStatus(c, "signed")

        if c.sellerSrc then
            Framework.Notify(c.sellerSrc, _U("contract_signed_notify", c.buyerName), "info")
        end
    end

    cb({ ok = true })
end)

Framework.RegisterCallback("contract:pay", function(source, cb, id, account)
    local c = getContractFor(id, source)
    if not (c and c.buyerSrc == source) then
        return fail(cb, "contract_invalid")
    end

    if c.status ~= "signed" and c.status ~= "pending" then
        return fail(cb, "contract_invalid")
    end

    -- Both parties must still be in the vehicle
    local entity = NetworkGetEntityFromNetworkId(c.netId)
    if cfg().requireSameVehicle ~= false then
        local together = entity and entity ~= 0 and DoesEntityExist(entity)
            and isInVehicle(entity, c.buyerSrc)
            and isInVehicle(entity, c.sellerSrc)

        if not together then
            return fail(cb, "contract_left_vehicle")
        end
    end

    -- Seller must still own the vehicle
    local owned = DB.GetByPlate(c.key)
    if not (owned and owned.owner == c.seller) then
        closeContract(c, "cancelled")
        return fail(cb, "contract_vehicle_gone")
    end

    local buyerIdentifier = Framework.GetIdentifier(source)
    if buyerIdentifier ~= c.buyer then
        return fail(cb, "contract_invalid")
    end

    -- Validate the chosen payment account
    account = (account == "cash") and "cash" or "bank"

    local accountAllowed = false
    for _, allowed in ipairs(cfg().accounts or { "cash", "bank" }) do
        if allowed == account then accountAllowed = true end
    end
    if not accountAllowed then
        return fail(cb, "contract_invalid")
    end

    -- Take the money
    if not Framework.RemoveMoney(source, account, c.price, "vehicle purchase") then
        return fail(cb, "not_enough_money", Utils.Money(c.price))
    end

    -- Pay the seller (minus tax), online or offline
    local sellerNet = c.price - c.tax
    local payoutAccount = cfg().sellerReceives or "bank"
    if payoutAccount == "same" then payoutAccount = account end

    local sellerPlayer = Framework.GetPlayerByIdentifier(c.seller)
    if sellerPlayer then
        if not Framework.AddMoney(sellerPlayer, payoutAccount, sellerNet, "vehicle sale") then
            DB.AddMoneyOffline(c.seller, payoutAccount, sellerNet)
        end
    else
        DB.AddMoneyOffline(c.seller, payoutAccount, sellerNet)
    end

    -- Transfer ownership
    DB.Transfer(owned, buyerIdentifier, Framework.GetLicense(source))
    DB.UpsertMeta(c.key, { nickname = false })
    Vehicles.Transferred(c.key, buyerIdentifier, source, sellerPlayer, (entity and entity ~= 0) and entity or nil)

    if cfg().consumeItem ~= false and sellerPlayer then
        Inventory.RemoveItem(sellerPlayer, itemName(), 1, c.slot, nil)
    end

    DB.ResolveContract(c.id, "accepted", false)
    DB.SetContractBuyerName(c.id, Framework.GetName(source))

    log(("contract %s: %s sold %s (%s) to %s for %s"):format(
        c.id, c.sellerName, c.label, c.plateRaw, Framework.GetName(source), Utils.Money(c.price)
    ))

    TriggerEvent(RESOURCE .. ":server:contractAccepted", c.id, c.seller, buyerIdentifier, c.key, c.price)

    closeContract(c, "paid")

    if sellerPlayer then
        Framework.Notify(sellerPlayer, _U("contract_paid_seller", Framework.GetName(source), Utils.Money(sellerNet), c.label), "success")
    end

    cb({ ok = true, message = _U("contract_paid_buyer", c.label, c.plateRaw) })
end)

Framework.RegisterCallback("contract:decline", function(source, cb, id)
    local c = getContractFor(id, source)
    if not (c and c.buyerSrc == source) then
        return fail(cb, "contract_invalid")
    end

    closeContract(c, "declined")

    if c.sellerSrc then
        Framework.Notify(c.sellerSrc, _U("contract_declined_seller", c.buyerName, c.label), "warning")
    end

    cb({ ok = true, message = _U("contract_declined") })
end)

-- Accepts a contract id, or a plate (looked up through the plate lock)
Framework.RegisterCallback("contract:cancel", function(source, cb, idOrPlate)
    local c = contracts[tostring(idOrPlate or "")]

    if not c then
        local contractId = lockedPlates[Utils.PlateKey(idOrPlate)]
        c = contractId and contracts[contractId] or nil
    end

    if not (c and (c.sellerSrc == source or c.buyerSrc == source)) then
        return fail(cb, "contract_invalid")
    end

    closeContract(c, "cancelled")

    -- NOTE: when the seller cancels a contract with no buyer (showcase mode),
    -- this falls back to notifying the seller themselves. Kept from the original.
    local other = (c.sellerSrc == source and c.buyerSrc) or c.sellerSrc
    if other then
        Framework.Notify(other, _U("contract_cancelled_other", c.label), "warning")
    end

    cb({ ok = true, message = _U("contract_cancelled") })
end)

--------------------------------------------------------------------------------
-- Maintenance
--------------------------------------------------------------------------------

function Contract.Sweep()
    local now = os.time()

    for _, c in pairs(contracts) do
        if now > c.expiresAt then
            debugLog(("contract %s expired"):format(c.id))
            closeContract(c, "expired")

            if c.sellerSrc then
                Framework.Notify(c.sellerSrc, _U("contract_expired"), "warning")
            end
            if c.buyerSrc then
                Framework.Notify(c.buyerSrc, _U("contract_expired"), "warning")
            end
        end
    end
end

-- Gives back blank contract items for offers that were voided (e.g. after a restart)
function Contract.DeliverRefunds(src)
    if not (DB.Ready and GetPlayerName(src)) then return end

    local identifier = Framework.GetIdentifier(src)
    if not identifier then return end

    local ok, refunds = pcall(DB.PendingRefunds, identifier)
    if not (ok and type(refunds) == "table") then return end

    for _, refund in ipairs(refunds) do
        if Inventory.AddItem(src, itemName(), 1) then
            DB.ClearRefund(refund.id)
            Framework.Notify(src, _U("contract_refund"), "info")
            log(("blank contract returned to %s (contract %s)"):format(
                GetPlayerName(src) or src, tostring(refund.id)
            ))
        end
    end
end

-- A player leaving cancels their active contract
AddEventHandler("playerDropped", function()
    local id = activeBySource[source]
    local c = id and contracts[id]
    if c then
        closeContract(c, "cancelled")
    end
end)

function Contract.Boot()
    if not cfg().enabled then return end

    local voided = DB.ExpirePendingContracts() or 0
    if voided > 0 then
        log(("%d unfinished contract(s) from the last session voided"):format(voided))
    end

    Inventory.RegisterUsable(itemName(), function(src, slot)
        Contract.Use(src, slot)
    end)

    CreateThread(function()
        while true do
            Wait(15000)
            pcall(Contract.Sweep)
        end
    end)
end

