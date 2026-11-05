if Config.ClothingSystem ~= 'rcore_clothing' and Config.ClothingSystem ~= 'rcore-clothing' then
    return
end

local savedOutfits = {}

function SavePlayerClothing()
    local ped = PlayerPedId()
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
    local clothing = savedOutfits.civilian

    for i = 0, 11 do
        SetPedComponentVariation(ped, i, clothing['drawable_' .. i] or 0, clothing['texture_' .. i] or 0, 2)
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
        exports['rcore_clothing']:openClothingMenu()
    end)

    if not success then
        pcall(function()
            TriggerEvent('rcore_clothing:openMenu')
        end)
    end

    return true
end

function HasClothingShop()
    return GetResourceState('rcore_clothing') == 'started'
end
