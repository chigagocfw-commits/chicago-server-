--[[
░▒▓████████▓▒░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓████████▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓███████▓▒░  
   ░▒▓█▓▒░  ░▒▓█▓▒░             ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░  ░▒▓█▓▒░░▒▓█▓▒░      ░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░ 
   ░▒▓█▓▒░   ░▒▓██████▓▒░       ░▒▓█▓▒░░▒▓█▓▒░░▒▓██████▓▒░░▒▓███████▓▒░  
                                                                         
 This File Leaked By TC HUB Team, Join Our Server For More
 DISCORD: - https://discord.gg/k3S8RjkPWc - https://t.me/+RgDxwPX3L7w2ODBk - https://tchub.shop/
--]]

if Config.Framework ~= "qb" then
    return
end

if not Config.Crypto.QBit then
    return
end

while not QB do
    Wait(500)
    debugprint("QBit: Waiting for QB to load")
end

function GetQBit()
    local promise = promise.new()

    QB.Functions.TriggerCallback("qb-crypto:server:GetCryptoData", function(cryptoData)
        promise:resolve(cryptoData)
    end, "qbit")

    return Citizen.Await(promise)
end

function BuyQBit(amount)
    local promise = promise.new()

    QB.Functions.TriggerCallback("qb-crypto:server:BuyCrypto", function(res)
        promise:resolve({ success = type(res) == "table" })
    end, {
        Coins = amount / GetQBit().Worth,
        Price = amount
    })

    return Citizen.Await(promise)
end

function SellQBit(amount)
    local promise = promise.new()

    QB.Functions.TriggerCallback("qb-crypto:server:SellCrypto", function(res)
        promise:resolve({ success = type(res) == "table" })
    end, {
        Coins = amount,
        Price = math.floor(amount * GetQBit().Worth + 0.5)
    })

    return Citizen.Await(promise)
end

function TransferQBit(amount, toNumber)
    local otherWallet = AwaitCallback("crypto:getOtherQBitWallet", toNumber)
    if not otherWallet then
        return { success = false }
    end

    local qbit = GetQBit()
    if qbit.Portfolio < amount then
        return { success = false }
    end

    local promise = promise.new()

    QB.Functions.TriggerCallback("qb-crypto:server:TransferCrypto", function(res)
        promise:resolve({ success = type(res) == "table" })
    end, {
        Coins = amount,
        WalletId = otherWallet
    })

    return Citizen.Await(promise)
end

