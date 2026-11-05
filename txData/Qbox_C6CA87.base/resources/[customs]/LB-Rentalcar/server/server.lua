--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/tndFR89Sye - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.st/
--]]

local QBCore = exports['qb-core']:GetCoreObject()

local MySQL = MySQL or exports.oxmysql
local ActiveRentals = {}

RegisterNetEvent('lb-rental:server:rentVehicle', function(vehicleIndex, locationIndex)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local vehicleInfo = Config.Vehicles[vehicleIndex]
    if not vehicleInfo then return end

    local citizenId = Player.PlayerData.citizenid
    local activeRental = ActiveRentals[citizenId]
    if activeRental then
        TriggerClientEvent('lb-rental:client:notify', src, 'Cannot Rent', 'You already have an active rental', 'error')
        return
    end

    local deposit = math.floor(vehicleInfo.price * Config.DepositPercent)
    local totalCost = deposit

    local cash = Player.PlayerData.money[Config.Currency]
    if not cash or cash < totalCost then
        TriggerClientEvent('lb-rental:client:notify', src, 'Cannot Rent', ('You need $%s to rent this vehicle'):format(totalCost), 'error')
        return
    end

    Player.Functions.RemoveMoney(Config.Currency, totalCost, 'rental-deposit')

    local plate = 'RENT' .. math.random(100, 999)
    ActiveRentals[citizenId] = {
        plate = plate,
        deposit = deposit,
        price = vehicleInfo.price,
        model = vehicleInfo.model,
        locationIndex = locationIndex,
    }

    if MySQL then
        MySQL.insert('INSERT INTO rental_history (citizenid, vehicle_model, price, deposit, plate, rent_time) VALUES (@citizenid, @vehicle, @price, @deposit, @plate, NOW())', {
            ['@citizenid'] = citizenId,
            ['@vehicle'] = vehicleInfo.model,
            ['@price'] = vehicleInfo.price,
            ['@deposit'] = deposit,
            ['@plate'] = plate,
        })
    end

    TriggerClientEvent('lb-rental:client:spawnVehicle', src, vehicleIndex, locationIndex, plate)
    TriggerClientEvent('lb-rental:client:notify', src, 'Rental Confirmed', ('Rented %s - Deposit paid: $%s'):format(vehicleInfo.label, deposit), 'success')
end)

RegisterNetEvent('lb-rental:server:returnVehicle', function(plate)
    local src = source
    print(('[LB-Rental] Server: Processing return for source %s, plate %s'):format(src, plate or 'nil'))
    
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then
        print('[LB-Rental] Server: No player found!')
        TriggerClientEvent('lb-rental:client:returnProcessed', src, false, 'Error processing return')
        return
    end

    local citizenId = Player.PlayerData.citizenid
    local activeRental = ActiveRentals[citizenId]
    print(('[LB-Rental] Server: CitizenID %s, Active Rental: %s'):format(citizenId, activeRental ~= nil))
    
    if not activeRental then
        print('[LB-Rental] Server: No active rental in memory!')
        TriggerClientEvent('lb-rental:client:returnProcessed', src, false, 'No active rental found')
        return
    end

    local deposit = activeRental.deposit
    local fee = math.floor(deposit * Config.RefundPercent)
    local refund = deposit - fee

    if MySQL then
        print('[LB-Rental] Server: Updating MySQL rental history...')
        MySQL.execute('UPDATE rental_history SET return_time = NOW(), refund = @refund WHERE citizenid = @citizenid AND plate = @plate AND return_time IS NULL', {
            ['@citizenid'] = citizenId,
            ['@plate'] = activeRental.plate,
            ['@refund'] = refund,
        })
    end

    ActiveRentals[citizenId] = nil
    Player.Functions.AddMoney(Config.Currency, refund, 'rental-refund')
    
    print(('[LB-Rental] Server: Return complete! Refunded $%s'):format(refund))
    TriggerClientEvent('lb-rental:client:returnProcessed', src, true, ('Vehicle returned - Refunded: $%s (Fee: $%s)'):format(refund, fee))
end)

