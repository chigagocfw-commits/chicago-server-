if Config.Billing ~= 'standalone' then
    return
end

local activeBills = {}

function OpenBillingMenu(shopId, shopData)
    local options = {
        {
            title = _U('BILLING_CREATE_BILL') or 'Create Bill',
            description = _U('BILLING_CREATE_DESC') or 'Create a new bill for a nearby player',
            icon = 'file-invoice-dollar',
            onSelect = function()
                OpenCreateBillMenu(shopId, shopData)
            end
        },
        {
            title = _U('BILLING_VIEW_PENDING') or 'View Pending Bills',
            description = _U('BILLING_PENDING_DESC') or 'View all pending bills you have sent',
            icon = 'clock',
            onSelect = function()
                ViewPendingBills(shopId)
            end
        },
        {
            title = _U('BILLING_HISTORY') or 'Billing History',
            description = _U('BILLING_HISTORY_DESC') or 'View your billing history',
            icon = 'history',
            onSelect = function()
                ViewBillingHistory(shopId)
            end
        }
    }

    lib.registerContext({
        id = 'mechanic_billing_menu',
        title = _U('BILLING_MENU') or 'Billing Menu',
        options = options
    })

    lib.showContext('mechanic_billing_menu')
end

function OpenCreateBillMenu(shopId, shopData)
    local nearbyPlayers = GetNearbyPlayers(10.0)

    if #nearbyPlayers == 0 then
        lib.notify({
            title = _U('BILLING') or 'Billing',
            description = _U('NO_NEARBY_PLAYERS') or 'No players nearby',
            type = 'error'
        })
        return
    end

    local playerOptions = {}
    for _, player in ipairs(nearbyPlayers) do
        table.insert(playerOptions, {
            title = player.name,
            description = 'ID: ' .. player.id,
            icon = 'user',
            onSelect = function()
                CreateBillForPlayer(player.id, shopId, shopData)
            end
        })
    end

    lib.registerContext({
        id = 'mechanic_billing_select_player',
        title = _U('SELECT_PLAYER') or 'Select Player',
        menu = 'mechanic_billing_menu',
        options = playerOptions
    })

    lib.showContext('mechanic_billing_select_player')
end

function CreateBillForPlayer(targetId, shopId, shopData)
    local input = lib.inputDialog(_U('CREATE_BILL') or 'Create Bill', {
        {
            type = 'number',
            label = _U('BILL_AMOUNT') or 'Amount',
            description = _U('BILL_AMOUNT_DESC') or 'Enter the bill amount',
            icon = 'dollar-sign',
            required = true,
            min = 1
        },
        {
            type = 'input',
            label = _U('BILL_REASON') or 'Reason',
            description = _U('BILL_REASON_DESC') or 'Enter the reason for this bill',
            icon = 'file-alt',
            required = true,
            max = 100
        }
    })

    if not input then return end

    local amount = tonumber(input[1])
    local reason = input[2]

    if not amount or amount <= 0 then
        lib.notify({
            title = _U('BILLING') or 'Billing',
            description = _U('INVALID_AMOUNT') or 'Invalid amount',
            type = 'error'
        })
        return
    end

    TriggerServerEvent('qs-mechanic-creator:server:createBill', targetId, amount, reason, shopId)
end

function GetNearbyPlayers(radius)
    local players = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    for _, playerId in ipairs(GetActivePlayers()) do
        if playerId ~= PlayerId() then
            local targetPed = GetPlayerPed(playerId)
            if targetPed and DoesEntityExist(targetPed) then
                local targetCoords = GetEntityCoords(targetPed)
                local distance = #(playerCoords - targetCoords)
                if distance <= radius then
                    table.insert(players, {
                        id = GetPlayerServerId(playerId),
                        name = GetPlayerName(playerId),
                        distance = distance
                    })
                end
            end
        end
    end

    table.sort(players, function(a, b) return a.distance < b.distance end)
    return players
end

function ViewPendingBills(shopId)
    lib.callback('qs-mechanic-creator:server:getPendingBills', false, function(bills)
        if not bills or #bills == 0 then
            lib.notify({
                title = _U('BILLING') or 'Billing',
                description = _U('NO_PENDING_BILLS') or 'No pending bills',
                type = 'info'
            })
            return
        end

        local options = {}
        for _, bill in ipairs(bills) do
            table.insert(options, {
                title = bill.targetName or 'Unknown',
                description = FormatCurrency(bill.amount) .. ' - ' .. bill.reason,
                icon = 'file-invoice',
                metadata = {
                    {label = _U('DATE') or 'Date', value = bill.date},
                    {label = _U('STATUS') or 'Status', value = bill.status}
                },
                onSelect = function()
                    OpenBillActions(bill, shopId)
                end
            })
        end

        lib.registerContext({
            id = 'mechanic_pending_bills',
            title = _U('PENDING_BILLS') or 'Pending Bills',
            menu = 'mechanic_billing_menu',
            options = options
        })

        lib.showContext('mechanic_pending_bills')
    end, shopId)
end

function OpenBillActions(bill, shopId)
    local options = {
        {
            title = _U('CANCEL_BILL') or 'Cancel Bill',
            description = _U('CANCEL_BILL_DESC') or 'Cancel this pending bill',
            icon = 'times',
            onSelect = function()
                local confirm = lib.alertDialog({
                    header = _U('CONFIRM_CANCEL') or 'Confirm Cancel',
                    content = _U('CONFIRM_CANCEL_DESC') or 'Are you sure you want to cancel this bill?',
                    centered = true,
                    cancel = true
                })
                if confirm == 'confirm' then
                    TriggerServerEvent('qs-mechanic-creator:server:cancelBill', bill.id, shopId)
                end
            end
        }
    }

    lib.registerContext({
        id = 'mechanic_bill_actions',
        title = _U('BILL_ACTIONS') or 'Bill Actions',
        menu = 'mechanic_pending_bills',
        options = options
    })

    lib.showContext('mechanic_bill_actions')
end

function ViewBillingHistory(shopId)
    lib.callback('qs-mechanic-creator:server:getBillingHistory', false, function(history)
        if not history or #history == 0 then
            lib.notify({
                title = _U('BILLING') or 'Billing',
                description = _U('NO_BILLING_HISTORY') or 'No billing history',
                type = 'info'
            })
            return
        end

        local options = {}
        for _, record in ipairs(history) do
            local statusIcon = record.status == 'paid' and 'check-circle' or (record.status == 'cancelled' and 'times-circle' or 'clock')
            table.insert(options, {
                title = record.targetName or 'Unknown',
                description = FormatCurrency(record.amount) .. ' - ' .. record.reason,
                icon = statusIcon,
                metadata = {
                    {label = _U('DATE') or 'Date', value = record.date},
                    {label = _U('STATUS') or 'Status', value = record.status}
                }
            })
        end

        lib.registerContext({
            id = 'mechanic_billing_history',
            title = _U('BILLING_HISTORY') or 'Billing History',
            menu = 'mechanic_billing_menu',
            options = options
        })

        lib.showContext('mechanic_billing_history')
    end, shopId)
end

function ReceiveBill(billData)
    local alert = lib.alertDialog({
        header = _U('NEW_BILL') or 'New Bill',
        content = string.format(
            '%s\n\n%s: %s\n%s: %s\n%s: %s',
            _U('BILL_RECEIVED') or 'You have received a bill',
            _U('FROM') or 'From',
            billData.senderName,
            _U('AMOUNT') or 'Amount',
            FormatCurrency(billData.amount),
            _U('REASON') or 'Reason',
            billData.reason
        ),
        centered = true,
        cancel = true,
        labels = {
            confirm = _U('PAY') or 'Pay',
            cancel = _U('DECLINE') or 'Decline'
        }
    })

    if alert == 'confirm' then
        TriggerServerEvent('qs-mechanic-creator:server:payBill', billData.id)
    else
        TriggerServerEvent('qs-mechanic-creator:server:declineBill', billData.id)
    end
end

RegisterNetEvent('qs-mechanic-creator:client:receiveBill', function(billData)
    ReceiveBill(billData)
end)

RegisterNetEvent('qs-mechanic-creator:client:billPaid', function(billId, amount)
    lib.notify({
        title = _U('BILLING') or 'Billing',
        description = string.format(_U('BILL_PAID_SUCCESS') or 'Bill paid: %s', FormatCurrency(amount)),
        type = 'success'
    })
end)

RegisterNetEvent('qs-mechanic-creator:client:billDeclined', function(billId)
    lib.notify({
        title = _U('BILLING') or 'Billing',
        description = _U('BILL_DECLINED') or 'Bill was declined',
        type = 'error'
    })
end)

RegisterNetEvent('qs-mechanic-creator:client:billCancelled', function(billId)
    lib.notify({
        title = _U('BILLING') or 'Billing',
        description = _U('BILL_CANCELLED') or 'Bill has been cancelled',
        type = 'info'
    })
end)

function HasBillingSystem()
    return true
end
