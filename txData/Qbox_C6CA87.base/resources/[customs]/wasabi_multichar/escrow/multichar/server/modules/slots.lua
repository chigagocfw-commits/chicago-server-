local VipSlots = lib.class("VipSlots")

function VipSlots:constructor()
end

function VipSlots:ensureTable()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS wasabi_multicharacter_vips (
            identifier VARCHAR(255) PRIMARY KEY,
            transactions LONGTEXT DEFAULT NULL
        )
    ]])
    TriggerEvent("wasabi_multicharacter:SetUpUsersTable")
end

function GetPlayerLicense(source)
    if GetConvarInt("sv_fxdkMode", 0) == 1 then
        return "license:fxdk"
    end

    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:match("^license:") then
            return identifier
        end
    end

    return nil
end

function VipSlots:getCount(source)
    local license = GetPlayerLicense(source)
    if not license then
        return 0
    end

    local result = MySQL.query.await([[
        SELECT transactions FROM wasabi_multicharacter_vips WHERE identifier = ?
    ]], { license })

    if not result or not result[1] then
        return 0
    end

    local transactions = json.decode(result[1].transactions or "[]")
    local count = 0
    if transactions then
        for _ in pairs(transactions) do
            count = count + 1
        end
    end

    return count
end

function VipSlots:confirmTebexPurchase(source, transactionId)
    local license = GetPlayerLicense(source)
    if not license then
        return false
    end

    local tebexSecret = GetConvar("sv_tebexSecret", "none")
    if tebexSecret == "none" then
        lib.notify(source, {
            title = "Tebex",
            description = "Tebex secret not configured",
            type = "error"
        })
        return false
    end

    local packageId = Config.TebexPackageID
    if not packageId or packageId == 0 then
        return false
    end

    local purchasePromise = promise.new()
    local requestUrl = "https://plugin.tebex.io/payments/" .. transactionId

    PerformHttpRequest(requestUrl, function(statusCode, responseText)
        if statusCode ~= 200 then
            lib.notify(source, {
                title = "Purchase Failed",
                description = "Could not verify",
                type = "error"
            })
            purchasePromise:resolve(false)
            return
        end

        local paymentData = json.decode(responseText)
        local packageFound = false

        if paymentData and paymentData.packages then
            for _, pkg in ipairs(paymentData.packages) do
                if pkg.id == Config.TebexPackageID then
                    packageFound = true
                    break
                end
            end
        end

        if not packageFound then
            lib.notify(source, {
                title = "Purchase",
                description = "Package not found",
                type = "error"
            })
            purchasePromise:resolve(false)
            return
        end

        local allVips = MySQL.query.await("SELECT * FROM wasabi_multicharacter_vips")
        for _, vip in ipairs(allVips or {}) do
            local transactions = json.decode(vip.transactions or "[]")
            for _, existingTx in pairs(transactions or {}) do
                if existingTx == transactionId then
                    lib.notify(source, {
                        title = "Purchase",
                        description = "Transaction already used",
                        type = "error"
                    })
                    purchasePromise:resolve(false)
                    return
                end
            end
        end

        local playerVip = MySQL.query.await("SELECT * FROM wasabi_multicharacter_vips WHERE identifier = ?", { license })
        local playerTransactions = {}
        if playerVip and playerVip[1] then
            playerTransactions = json.decode(playerVip[1].transactions or "[]") or {}
        end

        table.insert(playerTransactions, transactionId)
        local encodedTransactions = json.encode(playerTransactions)

        MySQL.update.await([[
            INSERT INTO wasabi_multicharacter_vips (identifier, transactions) VALUES (?, ?)
            ON DUPLICATE KEY UPDATE transactions = ?
        ]], { license, encodedTransactions, encodedTransactions })

        lib.notify(source, {
            title = "Slot Added",
            description = "VIP character slot added",
            type = "success"
        })
        TriggerClientEvent("wasabi_multichar:slotPurchased", source)
        purchasePromise:resolve(true)
    end, "GET", "", { ["X-Tebex-Secret"] = tebexSecret })

    return Citizen.Await(purchasePromise)
end

function VipSlots:addManual(source, license, adminName)
    if not IsPlayerAceAllowed(source, "wasabi_multichar.addvip") then
        return false
    end

    local transactions = {}
    local result = MySQL.query.await("SELECT * FROM wasabi_multicharacter_vips WHERE identifier = ?", { license })
    if result and result[1] then
        transactions = json.decode(result[1].transactions or "[]") or {}
    end

    local tag = "added_by_" .. (adminName or "admin")
    table.insert(transactions, tag)
    local encoded = json.encode(transactions)

    MySQL.update.await([[
        INSERT INTO wasabi_multicharacter_vips (identifier, transactions) VALUES (?, ?)
        ON DUPLICATE KEY UPDATE transactions = ?
    ]], { license, encoded, encoded })

    return true
end

Modules.register("VipSlots", VipSlots)
