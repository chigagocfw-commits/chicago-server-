-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global

local Appearance = {}

---Open first-spawn character customization.
---Picks the correct clothing editor based on the active framework.
function Appearance.openFirstSpawnCustomization()
    local bridge    = Modules.require('bridge')
    local framework = bridge and bridge.framework or 'custom'
    if GetResourceState('rcore_clothing') == 'started' then
        TriggerEvent('rcore_clothing:openCharCreator')
        return
    end
    if GetResourceState('illenium-appearance') == 'started' then
        if framework == 'qb' or framework == 'qbx' then
            TriggerEvent('qb-clothes:client:CreateFirstCharacter')
        elseif framework == 'esx' then
            TriggerEvent('esx_skin:openSaveableMenu')
        elseif framework == 'custom' then
            lib.print.warn('[wasabi_multichar] illenium-appearance has no handler for custom framework')
        end
        return
    end
    if GetResourceState('fivem-appearance') == 'started' then
        local cb = function() end
        exports['fivem-appearance']:startPlayerCustomization(cb, {
            ped = true, headBlend = true, faceFeatures = true, headOverlays = true,
            components = true, props = true, tattoos = false,
        })
        return
    end
    Wait(1500)
    if framework == 'esx' then
        TriggerEvent('esx_skin:openSaveableMenu')
        return
    end
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
end

---Apply ESX skin data manually when no appearance resource is available.
---Used as the final fallback in setPedAppearance.
---@param ped number
---@param skin table
function Appearance.applyPedSkinFallback(ped, skin)
    if not skin then return end
    local function norm(value, divisor) return (value / divisor) + 0.0 end

    local mom, dad = skin.mom or 0, skin.dad or 0
    local gp = skin.grandparents or 0
    SetPedHeadBlendData(ped, mom, dad, gp, mom, dad, gp,
        norm(skin.face_md_weight or 0, 100),
        norm(skin.skin_md_weight or 0, 100),
        skin.face_g_weight and norm(skin.face_g_weight, 100) or 0, false)

    local faceFeatures = {
        'nose_1','nose_2','nose_3','nose_4','nose_5','nose_6',
        'eyebrows_5','eyebrows_6','cheeks_1','cheeks_2','cheeks_3',
        'eye_squint','lip_thickness','jaw_1','jaw_2',
        'chin_1','chin_2','chin_3','chin_4','neck_thickness',
    }
    for i, f in ipairs(faceFeatures) do
        if skin[f] then SetPedFaceFeature(ped, i - 1, norm(skin[f], 10)) end
    end
    if skin.eye_color then SetPedEyeColor(ped, skin.eye_color) end

    local overlays = {
        {'blemishes_1','blemishes_2'}, {'beard_1','beard_2'}, {'eyebrows_1','eyebrows_2'},
        {'age_1','age_2'}, {'makeup_1','makeup_2'}, {'blush_1','blush_2'},
        {'complexion_1','complexion_2'}, {'sun_1','sun_2'}, {'lipstick_1','lipstick_2'},
        {'moles_1','moles_2'}, {'chest_1','chest_2'},
    }
    for i, p in ipairs(overlays) do
        SetPedHeadOverlay(ped, i - 1, skin[p[1]] or 0, norm(skin[p[2]] or 0, 10))
    end

    local overlayColors = {
        [1] = {'beard_3','beard_4'}, [2] = {'eyebrows_3','eyebrows_4'},
        [4] = {'makeup_3','makeup_4'}, [5] = {'blush_3', 0},
        [8] = {'lipstick_3','lipstick_4'}, [10] = {'chest_3', 0},
    }
    for id, p in pairs(overlayColors) do
        local c1 = skin[p[1]] or 0
        local c2 = type(p[2]) == 'number' and p[2] or (skin[p[2]] or 0)
        SetPedHeadOverlayColor(ped, id, 1, c1, c2)
    end

    if skin.hair_1 and skin.hair_2 then SetPedComponentVariation(ped, 2, skin.hair_1, skin.hair_2, 2) end
    if skin.hair_color_1 and skin.hair_color_2 then SetPedHairColor(ped, skin.hair_color_1, skin.hair_color_2) end

    local comps = {
        {d = 'tshirt_1', t = 'tshirt_2', id = 8},  {d = 'torso_1',  t = 'torso_2',  id = 11},
        {d = 'decals_1', t = 'decals_2', id = 10}, {d = 'arms',     t = 'arms_2',   id = 3},
        {d = 'pants_1',  t = 'pants_2',  id = 4},  {d = 'shoes_1',  t = 'shoes_2',  id = 6},
        {d = 'mask_1',   t = 'mask_2',   id = 1},  {d = 'bproof_1', t = 'bproof_2', id = 9},
        {d = 'chain_1',  t = 'chain_2',  id = 7},  {d = 'bags_1',   t = 'bags_2',   id = 5},
    }
    for _, c in ipairs(comps) do
        if skin[c.d] and skin[c.t] then SetPedComponentVariation(ped, c.id, skin[c.d], skin[c.t], 2) end
    end

    local props = {
        {d = 'helmet_1',    t = 'helmet_2',    id = 0}, {d = 'glasses_1',   t = 'glasses_2',   id = 1},
        {d = 'ears_1',      t = 'ears_2',      id = 2}, {d = 'watches_1',   t = 'watches_2',   id = 6},
        {d = 'bracelets_1', t = 'bracelets_2', id = 7},
    }
    for _, p in ipairs(props) do
        if skin[p.d] and skin[p.t] then
            if skin[p.d] == -1 then ClearPedProp(ped, p.id) else SetPedPropIndex(ped, p.id, skin[p.d], skin[p.t], true) end
        end
    end
end

Modules.register('Appearance', Appearance)
