function GetCardPinCode(cardNumber)
    if not cardNumber then
        return nil
    end

    local result = MySQL.query.await([[
        SELECT pin
        FROM bablo_bank_cards
        WHERE card_number = ?
        LIMIT 1
    ]], { tostring(cardNumber) })

    if result and result[1] then
        return tonumber(result[1].pin)
    end

    return nil
end
