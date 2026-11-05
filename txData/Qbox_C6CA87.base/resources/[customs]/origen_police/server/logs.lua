local function split(str, sep)
    local result = {}
    for match in (str .. sep):gmatch("(.-)" .. sep) do
        table.insert(result, match)
    end
    return result
end

-- Check if webhook URL is valid
function isValidURL(url)
    return url ~= "" and url ~= "YOUR_DISCORD_WEBHOOK"
end

-- Main logging function
function CreateLog(data)
    -- data.type: Log type (e.g., "DutyClock", "Shapes", "Ankle")
    -- data.embed: Discord embed object {title, description, color}
    -- data.message: Plain text message
    -- data.source: Player server ID
    
    if not data.type or not ServerConfig.Logs[data.type] then
        return
    end
    
    if not isValidURL(ServerConfig.Logs[data.type]) then
        return
    end
    
    -- Add player identifiers if enabled
    if ServerConfig.UseIdentifiers and data.source then
        local identifiers = "**" .. Config.LogsTranslations.Identifiers .. "**\n"
        identifiers = identifiers .. "ID: " .. data.source .. "\n"
        identifiers = identifiers .. "Name: " .. GetPlayerName(data.source) .. "\n"
        
        -- Add all identifiers except license2 and ip
        for _, id in pairs(GetPlayerIdentifiers(data.source)) do
            if not string.find(id, "license2:") and not string.find(id, "ip:") then
                local parts = split(id, ":")
                identifiers = identifiers .. parts[1] .. ": " .. id .. "\n"
            end
        end
        
        -- Append to embed or message
        if data.embed then
            data.embed.description = (data.embed.description or "") .. "\n\n" .. identifiers
        else
            data.message = (data.message or "") .. "\n\n" .. identifiers
        end
    end
    
    -- Send to Discord webhook
    PerformHttpRequest(
        ServerConfig.Logs[data.type],
        function(err, text, headers) end,
        "POST",
        json.encode({
            embeds = data.embed and {data.embed} or {},
            avatar_url = data.avatar_url or "",
            content = data.message or ""
        }),
        {["Content-Type"] = "application/json"}
    )
end