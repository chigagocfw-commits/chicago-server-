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

    -- 1. Direct SOUH4IL Owner check (Rockstar License / Discord / FiveM ID)
    local playerLicense = nil
    local identifiers = GetPlayerIdentifiers(src)
    for _, id in ipairs(identifiers) do
        if id:sub(1, 8) == "license:" then
            playerLicense = id
        end
        if id == "license:385f488fdcdc30a24c28b7a333ba9cbbffed5044"
            or id == "discord:792387618708914227"
            or id == "fivem:20069674" then
            addAce("admin")
            addAce("group.admin")
            addAce("souh4il")
            return allowedAces
        end
    end

    -- 2. Check SOUH4IL-DEV Dynamic Staff Role & Characters Permission in DB
    if playerLicense and MySQL then
        local ok, row = pcall(function()
            return MySQL.single.await("SELECT `role`, `permissions` FROM `souh4il_dev_staff` WHERE `license` = ? LIMIT 1", { playerLicense })
        end)
        if ok and row then
            local role = string.lower(tostring(row.role or ""))
            local hasCharPerm = false
            if row.permissions and row.permissions ~= "" then
                local decOk, perms = pcall(json.decode, row.permissions)
                if decOk and type(perms) == "table" and perms.characters == true then
                    hasCharPerm = true
                end
            end
            if hasCharPerm or role == "owner" or role == "developer" or role == "admin" then
                addAce("admin")
                addAce("group.admin")
                addAce("souh4il")
                return allowedAces
            end
        end
    end

    -- 3. Check FiveM ACE Role Permissions
    if IsPlayerAceAllowed(src, "souh4il_dev.owner")
        or IsPlayerAceAllowed(src, "souh4il_dev.developer")
        or IsPlayerAceAllowed(src, "souh4il_dev.admin")
        or IsPlayerAceAllowed(src, "oxlyn.admin")
        or IsPlayerAceAllowed(src, "admin") then
        addAce("admin")
        addAce("group.admin")
    end

    -- 4. Check Config.Aces configured permissions
    if Config.Aces then
        for i = 1, #Config.Aces do
            local ace = Config.Aces[i]
            if IsPlayerAceAllowed(src, ace) then
                addAce(ace)
            end
        end
    end

    return allowedAces
end)
