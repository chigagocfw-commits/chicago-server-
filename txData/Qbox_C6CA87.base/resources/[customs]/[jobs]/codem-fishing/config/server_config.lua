bot_Token = ""


Discordwebhook = {
    ['sell'] = "",
    ['buy'] = ""
}



function SendDiscordLog(src, type, items, totalprice)
    local Webhook = Discordwebhook[type]
    if not Webhook then return end

    local PlayerName = GetPlayerName(src) or "Unknown"
    local Identifier = GetIdentifier(src) or "Unknown"
    local ItemsDetails = ""

    for _, item in pairs(items) do
        ItemsDetails = ItemsDetails .. string.format("`%s` (**x%s**)", item.label, item.amount)
    end

    local embed = {
        {
            ["author"] = {
                ["name"] = "Fishing Job Market",
            },
            ["title"] = "Market Transaction Completed",
            ["description"] = string.format(
                "**Player Name:** %s\n**Identifier:** %s\n**ID:** %s\n**Type:** %s\n**Total Price:** $%s",
                PlayerName, Identifier, src, type, totalprice
            ),
            ["fields"] = {
                {
                    ["name"] = type == 'sell' and "Products Sold" or "Products Buy",
                    ["value"] = ItemsDetails ~= "" and ItemsDetails or "There are no products.",
                    ["inline"] = false
                }
            },
            ["color"] = 3066993,
            ["footer"] = {
                ["text"] = os.date("Transaction Date: %Y-%m-%d %H:%M:%S"),
            }
        }
    }

    PerformHttpRequest(Webhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Fishing Job Market",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end
