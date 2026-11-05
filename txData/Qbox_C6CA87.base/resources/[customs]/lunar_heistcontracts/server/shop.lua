local shopItems = {}
local dealerLocation = nil

-- Initialize shop items with chance filter
for _, item in ipairs(Config.ped.buyItems) do
    if not item.chance or math.random(1, 100) <= item.chance then
        table.insert(shopItems, table.clone(item))
    end
end

-- Select random dealer location on resource start
dealerLocation = Config.ped.locations[math.random(1, #Config.ped.locations)]

-- Item lookup helpers
local function findBuyItem(itemName)
    for _, item in ipairs(shopItems) do
        if item.name == itemName then return item end
    end
    return nil
end

local function findSellItem(itemName)
    for _, item in ipairs(Config.ped.sellItems) do
        if item.name == itemName then return item end
    end
    return nil
end

-- Validation helpers
local function validatePurchase(player, item, quantity)
    if not player or Config.disableMainMenu or quantity <= 0 then
        return false, locale("unknown_error")
    end

    if not item then
        return false, locale("unknown_error")
    end

    local moneyPrice = (item.price.money or 0) * quantity
    local cryptoPrice = (item.price.crypto or 0) * quantity

    if moneyPrice <= 0 and cryptoPrice <= 0 then
        return false, locale("unknown_error")
    end

    if moneyPrice > 0 then
        local playerMoney = player:getAccountMoney(Config.ped.buyAccount)
        if moneyPrice > playerMoney then
            return false, locale("not_enough_" .. Config.ped.buyAccount)
        end
    end

    if cryptoPrice > 0 then
        local identifier = player:getIdentifier()
        local profile = Profiles.get(identifier)
        if cryptoPrice > (profile and profile.crypto or 0) then
            return false, locale("not_enough_crypto")
        end
    end

    if quantity > item.stock then
        return false, locale("not_enough_stock")
    end

    return true
end

local function processPayment(player, item, quantity)
    local moneyPrice = (item.price.money or 0) * quantity
    local cryptoPrice = (item.price.crypto or 0) * quantity
    local identifier = player:getIdentifier()

    if moneyPrice > 0 then
        player:removeAccountMoney(Config.ped.buyAccount, moneyPrice)
    end

    if cryptoPrice > 0 then
        Profiles.removeCrypto(identifier, cryptoPrice)
        Profiles.sync(identifier)
    end
end

-- Callbacks

lib.callback.register("lunar_contracts:getShopItems", function()
    return shopItems
end)

lib.callback.register("lunar_contracts:getDealerLocation", function()
    return dealerLocation
end)

lib.callback.register("lunar_contracts:buyShopItem", function(source, itemName, quantity)
    local player = Framework.getPlayerFromId(source)
    if not player then return false, locale("unknown_error") end

    local item = findBuyItem(itemName)
    local ok, err = validatePurchase(player, item, quantity)
    if not ok then return ok, err end

    -- Deduct stock
    local itemIndex
    for i, shopItem in ipairs(shopItems) do
        if shopItem.name == itemName then
            itemIndex = i
            break
        end
    end

    item.stock = item.stock - quantity
    TriggerClientEvent("lunar_contracts:updateItemStock", -1, itemIndex, item.stock)

    -- Process payment
    processPayment(player, item, quantity)

    -- Deliver item after delay
    SetTimeout(3000, function()
        player:addItem(item.name, quantity)
    end)

    LogNormal(source, string.format([[
Purchased an item through a dealer.
Item name: %s
Total price: %s$ and %sx %s]],
        Utils.getItemLabel(item.name),
        (item.price.money or 0) * quantity,
        (item.price.crypto or 0) * quantity,
        Config.crypto.label))

    return true
end)

lib.callback.register("lunar_contracts:sellShopItem", function(source, itemName, quantity)
    local player = Framework.getPlayerFromId(source)
    if not player or quantity <= 0 then return false, locale("unknown_error") end

    local item = findSellItem(itemName)
    if not item then
        if Config and Config.debug then print(("[lunar_contracts] [DEBUG] sellShopItem - item '%s' not found in Config.ped.sellItems"):format(itemName)) end
        return false, locale("unknown_error")
    end

    local playerItemCount = player.getItemCount(item.name)

    -- Fallback: try direct ESX inventory scan if getItemCount returned 0
    if playerItemCount == 0 and player.xPlayer and player.xPlayer.inventory then
        local total = 0
        for _, v in pairs(player.xPlayer.inventory) do
            if type(v) == "table" and v.name == item.name then
                total = total + (v.count or v.amount or 0)
            end
        end
        if Config and Config.debug then print(("[lunar_contracts] [DEBUG] xPlayer.inventory fallback: item=%s direct_count=%s"):format(item.name, total)) end
        if total > 0 then
            playerItemCount = total
        end
    end

    if Config and Config.debug then print(("[lunar_contracts] [DEBUG] sellShopItem - player=%s item=%s quantity=%s final_count=%s"):format(source, item.name, quantity, playerItemCount)) end

    if quantity > playerItemCount then
        -- Debug: dump inventory
        if player.xPlayer then
            -- Try xPlayer.inventory directly
            if player.xPlayer.inventory then
                local items = {}
                for k, v in pairs(player.xPlayer.inventory) do
                    if type(v) == "table" and v.name then
                        items[#items+1] = ("%s x%s (slot=%s)"):format(v.name, v.count or v.amount or 0, k)
                    end
                end
                if #items > 0 then
                    if Config and Config.debug then print(("[lunar_contracts] [DEBUG] xPlayer.inventory dump: %s"):format(table.concat(items, ", "))) end
                else
                    if Config and Config.debug then print(("[lunar_contracts] [DEBUG] xPlayer.inventory is empty or has no named items")) end
                    -- Try raw dump of first few entries
                    local raw = {}
                    for k, v in pairs(player.xPlayer.inventory) do
                        raw[#raw+1] = ("[%s]=%s"):format(k, type(v) == "table" and json.encode(v) or tostring(v))
                        if #raw >= 5 then break end
                    end
                    if Config and Config.debug then print(("[lunar_contracts] [DEBUG] xPlayer.inventory raw: %s"):format(table.concat(raw, " | "))) end
                end
            else
                if Config and Config.debug then print(("[lunar_contracts] [DEBUG] xPlayer.inventory is nil")) end
            end
        end
        return false, locale("not_enough_items")
    end

    -- Remove items
    player:removeItem(item.name, quantity)

    -- Give rewards after delay
    SetTimeout(3000, function()
        local moneyReward = (item.price.money or 0) * quantity
        local cryptoReward = (item.price.crypto or 0) * quantity

        if moneyReward > 0 then
            player:addAccountMoney(Config.ped.sellAccount, moneyReward)
        end

        if cryptoReward > 0 then
            local identifier = player:getIdentifier()
            Profiles.addCrypto(identifier, cryptoReward)
            Profiles.sync(identifier)
        end

        LogNormal(source, string.format([[
Sold an item through a dealer.
Item name: %s
Total reward: %s$ and %sx %s]],
            Utils.getItemLabel(item.name), moneyReward, cryptoReward, Config.crypto.label))
    end)

    return true
end)
