if Config.ClothingSystem ~= 'fivem-appearance' then
    return
end

local savedOutfits = {}

function SavePlayerClothing()
    local ped = PlayerPedId()
    local success, appearance = pcall(function()
        return exports['fivem-appearance']:getPedAppearance(ped)
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

    if savedOutfits.civilian.model or savedOutfits.civilian.components then
        local success = pcall(function()
            exports['fivem-appearance']:setPlayerAppearance(savedOutfits.civilian)
        end)
        if success then
            return true
        end
    end

    local ped = PlayerPedId()
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
        local components = {}
        for componentId, data in pairs(outfitData.components) do
            local id = tonumber(componentId)
            if id then
                table.insert(components, {
                    component_id = id,
                    drawable = data.drawable or 0,
                    texture = data.texture or 0
                })
            end
        end
        if #components > 0 then
            local success = pcall(function()
                exports['fivem-appearance']:setPedComponents(ped, components)
            end)
            if not success then
                for _, comp in ipairs(components) do
                    SetPedComponentVariation(ped, comp.component_id, comp.drawable, comp.texture, 2)
                end
            end
        end
    end

    if outfitData.props then
        local props = {}
        for propId, data in pairs(outfitData.props) do
            local id = tonumber(propId)
            if id then
                table.insert(props, {
                    prop_id = id,
                    drawable = data.drawable or -1,
                    texture = data.texture or 0
                })
            end
        end
        if #props > 0 then
            local success = pcall(function()
                exports['fivem-appearance']:setPedProps(ped, props)
            end)
            if not success then
                for _, prop in ipairs(props) do
                    if prop.drawable >= 0 then
                        SetPedPropIndex(ped, prop.prop_id, prop.drawable, prop.texture, true)
                    else
                        ClearPedProp(ped, prop.prop_id)
                    end
                end
            end
        end
    end

    return true
end

function OpenClothingShop()
    local success = pcall(function()
        exports['fivem-appearance']:startPlayerCustomization(function(appearance)
            if appearance then
                TriggerServerEvent('fivem-appearance:save', appearance)
            end
        end)
    end)
    return success
end

function HasClothingShop()
    return GetResourceState('fivem-appearance') == 'started'
end
