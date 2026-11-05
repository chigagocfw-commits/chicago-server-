if Config.ClothingSystem ~= 'ox_appearance' then
    return
end

local savedOutfits = {}

function SavePlayerClothing()
    local ped = PlayerPedId()
    local success, appearance = pcall(function()
        return exports['ox_appearance']:getPedAppearance(ped)
    end)

    if success and appearance then
        savedOutfits.civilian = appearance
        return appearance
    end

    local clothing = {}
    for i = 0, 11 do
        clothing['drawable_' .. i] = GetPedDrawableVariation(ped, i)
        clothing['texture_' .. i] = GetPedTextureVariation(ped, i)
    end
    for i = 0, 7 do
        clothing['prop_' .. i] = GetPedPropIndex(ped, i)
        clothing['propTexture_' .. i] = GetPedPropTextureIndex(ped, i)
    end
    savedOutfits.civilian = clothing
    return clothing
end

function RestorePlayerClothing()
    if not savedOutfits.civilian then
        return false
    end

    local ped = PlayerPedId()

    if savedOutfits.civilian.model or savedOutfits.civilian.components then
        local success = pcall(function()
            exports['ox_appearance']:setPlayerAppearance(savedOutfits.civilian)
        end)
        if success then
            return true
        end
    end

    local clothing = savedOutfits.civilian
    for i = 0, 11 do
        if clothing['drawable_' .. i] then
            SetPedComponentVariation(ped, i, clothing['drawable_' .. i] or 0, clothing['texture_' .. i] or 0, 2)
        end
    end
    for i = 0, 7 do
        if clothing['prop_' .. i] and clothing['prop_' .. i] >= 0 then
            SetPedPropIndex(ped, i, clothing['prop_' .. i], clothing['propTexture_' .. i] or 0, true)
        else
            ClearPedProp(ped, i)
        end
    end
    return true
end

function ApplyOutfit(outfitData)
    if not outfitData then
        return false
    end

    local ped = PlayerPedId()

    if outfitData.components then
        for componentId, data in pairs(outfitData.components) do
            local id = tonumber(componentId)
            if id then
                SetPedComponentVariation(ped, id, data.drawable or 0, data.texture or 0, 2)
            end
        end
    end

    if outfitData.props then
        for propId, data in pairs(outfitData.props) do
            local id = tonumber(propId)
            if id then
                if data.drawable and data.drawable >= 0 then
                    SetPedPropIndex(ped, id, data.drawable, data.texture or 0, true)
                else
                    ClearPedProp(ped, id)
                end
            end
        end
    end

    return true
end

function OpenClothingShop()
    local success = pcall(function()
        exports['ox_appearance']:startPlayerCustomization(function(appearance)
            if appearance then
                TriggerServerEvent('ox_appearance:save', appearance)
            end
        end)
    end)
    return success
end

function HasClothingShop()
    return GetResourceState('ox_appearance') == 'started'
end
