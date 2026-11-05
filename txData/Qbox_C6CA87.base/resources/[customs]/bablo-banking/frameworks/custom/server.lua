Framework = Framework or {};

CreateThread(function()
    if Config.Framework ~= 'standalone' then
        return
    end

    function Framework:fetchPlayer(source)
        return source
    end

    function Framework:getIdentifier()
        return GetPlayerIdentifiers(source)[1]
    end

    function Framework:getPlayerName(source)
        return GetPlayerName(source)
    end

    -- Hooks fired when money is added/removed through AddMoney/RemoveMoney/AddMoneyByCard.
    -- info = { accountNumber, amount, description, isAtm, actorIdentifier, cardNumber, newBalance, isDefault, owner }
    function Framework:onDeposit(info)
    end

    function Framework:onWithdrawal(info)
    end

    RegisterServerCallback({
        eventName = eventName .. 'server:getIdentifier',
        eventCallback = function(source)
            if not source then
                return { status = false, message = "NO_SOURCE" }
            end

            return { status = true, identifier = Framework:getIdentifier(source) }
        end
    })
end)