local shopItems = {}
local isProcessing = false
local shopPeds = {}

-- Dealer state management
local dealer = {
    busy = false,
    busyTimeout = nil,
    coords = nil,
    blip = nil,
    itemName = nil,
    amount = nil,
    generation = 0,
}

local function clearDealerBusy()
    dealer.busy = false
    isProcessing = false
    if dealer.busyTimeout then
        ClearTimeout(dealer.busyTimeout)
        dealer.busyTimeout = nil
    end
end

local function setDealerBusy()
    clearDealerBusy()
    dealer.busy = true
    dealer.generation = dealer.generation + 1
    dealer.busyTimeout = SetTimeout(30000, clearDealerBusy)
end

-- Periodic safety cleanup for stuck busy flags
CreateThread(function()
    while true do
        Wait(30000)
        if dealer.busy and dealer.busyTimeout == nil then
            clearDealerBusy()
        end
    end
end)

-- Price formatting helpers
local function formatPriceMoney(price)
    return locale("buy_item_price", price)
end

local function formatPriceCrypto(price)
    return locale("buy_item_price2", price)
end

local function formatPriceBoth(money, crypto)
    return locale("buy_item_price3", money, crypto)
end

local function formatItemPrice(item)
    if item.price.money and not item.price.crypto then
        return formatPriceMoney(item.price.money)
    elseif not item.price.money and item.price.crypto then
        return formatPriceCrypto(item.price.crypto)
    end
    return formatPriceBoth(item.price.money or 0, item.price.crypto or 0)
end

local function formatBuyHeading(item)
    if item.price.money and not item.price.crypto then
        return locale("buy_item_heading", Utils.getItemLabel(item.name), item.price.money)
    elseif not item.price.money and item.price.crypto then
        return locale("buy_item_heading2", Utils.getItemLabel(item.name), item.price.crypto)
    end
    return locale("buy_item_heading3", Utils.getItemLabel(item.name), item.price.money, item.price.crypto)
end

local function formatSellHeading(item)
    if item.price.money and not item.price.crypto then
        return locale("sell_item_heading", Utils.getItemLabel(item.name), item.price.money)
    elseif not item.price.money and item.price.crypto then
        return locale("sell_item_heading2", Utils.getItemLabel(item.name), item.price.crypto)
    end
    return locale("sell_item_heading3", Utils.getItemLabel(item.name), item.price.money, item.price.crypto)
end

local function formatConfirmText(isBuying, amount, item)
    local label = Utils.getItemLabel(item.name)
    if isBuying then
        if item.price.money and not item.price.crypto then
            return locale("dealer_confirm_purchase_money", amount, label, item.price.money)
        elseif not item.price.money and item.price.crypto then
            return locale("dealer_confirm_purchase_crypto", amount, label, item.price.crypto)
        end
        return locale("dealer_confirm_purchase", amount, label, item.price.money or 0, item.price.crypto or 0)
    end

    if item.price.money and not item.price.crypto then
        return locale("dealer_confirm_sale_money", amount, label, item.price.money)
    elseif not item.price.money and item.price.crypto then
        return locale("dealer_confirm_sale_crypto", amount, label, item.price.crypto)
    end
    return locale("dealer_confirm_sale", amount, label, item.price.money or 0, item.price.crypto or 0)
end

-- Transaction animation
local function playTransactionAnimation(ped)
    if not ped or type(ped) ~= "number" or ped == 0 then return end

    lib.requestAnimDict("mp_common")
    ClearPedTasks(ped)
    TaskPlayAnim(cache.ped, "mp_common", "givetake1_a", 2.0, 1.0, 2000, 16)

    SetTimeout(300, function()
        local coords = GetEntityCoords(ped)
        ClearAreaOfObjects(coords.x, coords.y, coords.z, 3.0, 17)
    end)

    Wait(2000)
    TaskPlayAnim(ped, "mp_common", "givetake1_a", 2.0, 1.0, 3000, 16)
end

-- Get ordered items list
local function getOrderedItems()
    local orders = {}
    for _, item in ipairs(shopItems) do
        if item.ordered then
            table.insert(orders, item)
        end
    end
    return orders
end

-- Get sellable items from inventory
local function getSellableItems()
    return Editable.filterItemsInInventory(Config.ped.sellItems)
end

-- Build answer items table for dealer menu
local function buildAnswerItems(items, getLabel, getPrice)
    local result = {}
    for _, item in ipairs(items) do
        table.insert(result, {
            name = item.name,
            label = getLabel(item),
            price = item.price,
            imageUrl = Editable.getInventoryIcon(item.name)
        })
    end
    return result
end

-- =============================================
-- Shop data management
-- =============================================

lib.callback("lunar_contracts:getShopItems", 1000, function(items)
    for i, item in ipairs(items) do
        shopItems[i] = {
            name = item.name,
            label = Utils.getItemLabel(item.name),
            description = item.description,
            image = Editable.getInventoryIcon(item.name) or "",
            price = item.price,
            stock = item.stock,
            ordered = false
        }
    end
end)

RegisterNetEvent("lunar_contracts:updateItemStock", function(itemIndex, newStock)
    shopItems[itemIndex].stock = newStock
    if newStock == 0 and shopItems[itemIndex].ordered then
        shopItems[itemIndex].ordered = false
        LR.notify(locale("no_longer_in_stock"), "error")
    end
    UI.sendMessage("updateShopData", shopItems)
end)

RegisterNUICallback("getShopData", function(_, cb)
    cb(shopItems)
end)

-- Dealer blip management
local function updateDealerBlip()
    if not dealer.coords then return end

    if dealer.blip then
        dealer.blip.remove()
    end

    dealer.blip = Utils.createBlip(dealer.coords, Config.ped.blip)
    SetBlipRoute(dealer.blip.value, true)

    CreateThread(function()
        Utils.distanceWait(dealer.coords, 10.0)
        if dealer.blip then
            dealer.blip.remove()
            dealer.blip = nil
        end
    end)
end

local function removeDealerBlip()
    if dealer.blip then
        dealer.blip.remove()
        dealer.blip = nil
    end
end

-- NUI order management (old flow support)
RegisterNUICallback("orderShopItem", function(itemName, cb)
    for i, item in ipairs(shopItems) do
        if item.name == itemName then
            shopItems[i].ordered = true
            break
        end
    end
    updateDealerBlip()
    UI.sendMessage("updateShopData", shopItems)
    cb({})
end)

RegisterNUICallback("removeItemFromOrder", function(itemName, cb)
    local orderedCount = 0
    for i, item in ipairs(shopItems) do
        if item.name == itemName then
            shopItems[i].ordered = false
        end
        if shopItems[i].ordered then
            orderedCount = orderedCount + 1
        end
    end
    UI.sendMessage("updateShopData", shopItems)
    if orderedCount == 0 then
        removeDealerBlip()
    end
    cb({})
end)

RegisterNUICallback("contactDealer", function(_, cb)
    updateDealerBlip()
    cb({})
end)

-- =============================================
-- Old menu system (legacy, Config.ped.oldMenu)
-- =============================================

local function buyShopItem(data)
    local itemIndex = data.itemIndex
    local pedIndex = data.pedIndex
    local item = shopItems[itemIndex]
    if not item then return end

    local input = lib.inputDialog(formatBuyHeading(item), {
        { type = "number", label = locale("amount"), min = 1, required = true }
    })
    if not input then return end

    local amount = input[1]
    isProcessing = true

    local success, msg = lib.callback.await("lunar_contracts:buyShopItem", false, item.name, amount)
    if not success then
        LR.notify(msg, "error")
        isProcessing = false
        return
    end

    shopItems[itemIndex].ordered = false
    UI.sendMessage("updateShopData", shopItems)

    local ped = shopPeds[pedIndex] and shopPeds[pedIndex].get()
    playTransactionAnimation(ped)

    LR.notify(locale("bought_item", amount, Utils.getItemLabel(item.name)), "success")
    Wait(2000)
    isProcessing = false
end

local function showOrderMenu(pedIndex)
    local ordered = getOrderedItems()
    if #ordered == 0 then
        LR.notify(locale("no_placed_orders"), "error")
        return
    end

    local options = {}
    for i, item in ipairs(shopItems) do
        if item.ordered then
            table.insert(options, {
                title = Utils.getItemLabel(item.name),
                description = formatItemPrice(item),
                icon = Editable.getInventoryIcon(item.name),
                onSelect = buyShopItem,
                args = { itemIndex = i, pedIndex = pedIndex }
            })
        end
    end

    lib.registerContext({ id = "shop_orders", title = locale("shop_orders"), options = options })
    lib.showContext("shop_orders")
end

local function sellShopItem(data)
    local item = data.item
    local pedIndex = data.pedIndex

    local input = lib.inputDialog(formatSellHeading(item), {
        { type = "number", label = locale("amount"), min = 1, required = true }
    })
    if not input then return end

    local amount = input[1]
    isProcessing = true

    local success, msg = lib.callback.await("lunar_contracts:sellShopItem", false, item.name, amount)
    if not success then
        LR.notify(msg, "error")
        isProcessing = false
        return
    end

    local ped = shopPeds[pedIndex] and shopPeds[pedIndex].get()
    playTransactionAnimation(ped)

    LR.notify(locale("sold_item", amount, Utils.getItemLabel(item.name)), "success")
    Wait(2000)
    isProcessing = false
end

local function showSellMenu(pedIndex)
    local sellableItems = getSellableItems()
    if #sellableItems == 0 then
        LR.notify(locale("no_items_to_sell"), "error")
        return
    end

    local options = {}
    for _, item in ipairs(sellableItems) do
        table.insert(options, {
            title = Utils.getItemLabel(item.name),
            description = formatItemPrice(item),
            icon = Editable.getInventoryIcon(item.name),
            onSelect = sellShopItem,
            args = { item = item, pedIndex = pedIndex }
        })
    end

    lib.registerContext({ id = "sell_items", title = locale("sell_items"), options = options })
    lib.showContext("sell_items")
end

-- =============================================
-- Interactive dealer conversation system
-- =============================================

local function findShopItemIndex(itemName)
    for i, item in ipairs(shopItems) do
        if item.name == itemName then return i end
    end
    return nil
end

local function findSellItem(itemName)
    local sellable = getSellableItems()
    for _, item in ipairs(sellable) do
        if item.name == itemName then return item end
    end
    return nil
end

local function buildReceiveOrderStep()
    local ordered = getOrderedItems()
    if #ordered == 0 then
        LR.notify(locale("dealer_no_placed_orders"), "error")
        return nil
    end

    return {
        question = locale("dealer_select_item_to_buy"),
        answerItems = buildAnswerItems(ordered, function(item)
            return Utils.getItemLabel(item.name)
        end)
    }
end

local function buildSellItemsStep()
    local sellable = getSellableItems()
    if #sellable == 0 then
        LR.notify(locale("no_items_to_sell"), "error")
        return nil
    end

    return {
        question = locale("dealer_select_item_to_sell"),
        answerItems = buildAnswerItems(sellable, function(item)
            return Utils.getItemLabel(item.name)
        end)
    }
end

local function buildConfirmStep(isBuying)
    local itemData
    if isBuying then
        local idx = findShopItemIndex(dealer.itemName)
        itemData = idx and shopItems[idx]
    else
        itemData = findSellItem(dealer.itemName)
    end

    if not itemData then
        clearDealerBusy()
        return nil
    end

    return {
        question = formatConfirmText(isBuying, dealer.amount, itemData),
        answers = {
            { id = isBuying and "pos_confirm_buy" or "pos_confirm_sell", label = locale("dealer_confirm_yes"), icon = "circle-check" },
            { id = "neg_cancel", label = locale("dealer_confirm_no"), icon = "circle-xmark" }
        }
    }
end

local function executeBuy()
    local gen = dealer.generation
    CreateThread(function()
        isProcessing = true

        local success, msg = lib.callback.await("lunar_contracts:buyShopItem", false, dealer.itemName, dealer.amount)
        if not success then
            LR.notify(msg, "error")
            isProcessing = false
            if dealer.generation == gen then clearDealerBusy() end
            return
        end

        if dealer.generation ~= gen then return end

        local itemIndex = findShopItemIndex(dealer.itemName)
        if itemIndex then
            shopItems[itemIndex].ordered = false
        end
        UI.sendMessage("updateShopData", shopItems)

        local ped = shopPeds[1] and shopPeds[1].get()
        CreateThread(function()
            LR.progressBar(locale("dealer_completing_transaction"), 3000, false)
        end)
        playTransactionAnimation(ped)

        LR.notify(locale("bought_item", dealer.amount, Utils.getItemLabel(dealer.itemName)), "success")
        Wait(2000)
        isProcessing = false
        if dealer.generation == gen then clearDealerBusy() end
    end)
end

local function executeSell()
    local gen = dealer.generation
    CreateThread(function()
        isProcessing = true

        local success, msg = lib.callback.await("lunar_contracts:sellShopItem", false, dealer.itemName, dealer.amount)
        if not success then
            LR.notify(msg, "error")
            isProcessing = false
            if dealer.generation == gen then clearDealerBusy() end
            return
        end

        if dealer.generation ~= gen then return end

        local ped = shopPeds[1] and shopPeds[1].get()
        CreateThread(function()
            LR.progressBar(locale("dealer_completing_transaction"), 3000, false)
        end)
        playTransactionAnimation(ped)

        LR.notify(locale("sold_item", dealer.amount, Utils.getItemLabel(dealer.itemName)), "success")
        Wait(2000)
        isProcessing = false
        if dealer.generation == gen then clearDealerBusy() end
    end)
end

-- Cleanup wrapper: ensures dealer busy flag is cleared on exit
local function withDealerCleanup(fn)
    local ok = pcall(fn)
    if not ok then
        clearDealerBusy()
    end
end

local function interactWithDealer(pedIndex)
    local pedEntry = shopPeds[pedIndex]
    if not pedEntry then return end
    local ped = pedEntry.get()
    if type(ped) ~= "number" or ped == 0 then return end

    -- Reset any stuck state from previous incomplete conversations
    clearDealerBusy()
    setDealerBusy()

    dealer.itemName = nil
    dealer.amount = nil
    local isBuying = nil

    local function handleSelection(selected)
        if not selected or selected.id == "neg_cancel" or selected.id == "just_passing" then
            clearDealerBusy()
            return
        end

        -- Initial menu routing
        if selected.id == "receive_order" then
            return buildReceiveOrderStep()
        end

        if selected.id == "sell_items" then
            return buildSellItemsStep()
        end

        -- Item selected (from receive_order or sell_items list)
        if selected.name then
            dealer.itemName = selected.name

            -- Determine if buying or selling
            local shopIdx = findShopItemIndex(selected.name)
            isBuying = shopIdx ~= nil and shopItems[shopIdx].ordered

            return {
                question = locale("dealer_enter_amount"),
                answerNumberInput = locale("amount")
            }
        end

        -- Amount entered
        if selected.value then
            dealer.amount = tonumber(selected.value) or 0
            if dealer.amount <= 0 then
                return {
                    question = locale("dealer_invalid_amount"),
                    answerNumberInput = locale("amount")
                }
            end

            return buildConfirmStep(isBuying)
        end

        -- Confirmation
        if selected.id == "pos_confirm_buy" then
            executeBuy()
            return nil
        end

        if selected.id == "pos_confirm_sell" then
            executeSell()
            return nil
        end

        clearDealerBusy()
    end

    withDealerCleanup(function()
        exports.lunar_bridge.openPedInteractionMenu(ped, {
            name = locale("dealer"),
            specifier = "",
            question = locale("dealer_greeting"),
            answers = {
                { id = "receive_order", label = locale("dealer_receive_order"), icon = "file-invoice" },
                { id = "sell_items", label = locale("dealer_sell_items"), icon = "dollar-sign" },
                { id = "just_passing", label = locale("dealer_just_passing"), icon = "circle-xmark" }
            }
        }, handleSelection)
    end)
end

-- =============================================
-- Ped creation
-- =============================================

CreateThread(function()
    Wait(5000)

    local coords = lib.callback.await("lunar_contracts:getDealerLocation", false)
    if not coords then
        print("[lunar_contracts] Error: No dealer location received from server")
        return
    end

    dealer.coords = coords

    if Config.ped.oldMenu then
        shopPeds[1] = Utils.createPed(dealer.coords, Config.ped.model, {{
            label = locale("receive_order"),
            icon = "file-invoice",
            onSelect = showOrderMenu,
            args = 1,
            canInteract = function() return not isProcessing end
        }, {
            label = locale("sell_items"),
            icon = "dollar-sign",
            onSelect = showSellMenu,
            args = 1,
            canInteract = function() return not isProcessing end
        }})
    else
        shopPeds[1] = Utils.createPed(dealer.coords, Config.ped.model, {{
            label = locale("dealer_talk"),
            icon = "comments",
            onSelect = interactWithDealer,
            args = 1,
            canInteract = function() return not isProcessing and not dealer.busy end
        }})
    end
end)
