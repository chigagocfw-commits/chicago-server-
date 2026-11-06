--[[
    Prism Inventory Bridge & UI Initialization
    Handles dynamic character profile card (Mugshot, Citizen ID, Character Name, Cash & Bank)
]]

CreateThread(function()
    SendNUIMessage({
        action = "setupNotifyTheme",
        data = {
            Prism = Prism.ThemeSettings
        }
    })
    SendNUIMessage({
        action = "updateThemePrism",
        data = {
            ThemeSettings = Prism.ThemeSettings
        }
    })
end)

local function GetPlayerProfileData()
    local pData = nil
    pcall(function()
        if exports["qbx_core"] then
            pData = exports["qbx_core"]:GetPlayerData()
        elseif exports["qb-core"] then
            local qb = exports["qb-core"]:GetCoreObject()
            if qb and qb.Functions then
                pData = qb.Functions.GetPlayerData()
            end
        end
    end)
    return pData
end

function SetupPrismInventory(left, right)
    local pData = GetPlayerProfileData()

    -- 1. Profile Picture / Mugshot ("la img"):
    if (not mugshot or mugshot == '') and exports['MugShotBase64'] then
        pcall(function()
            local ped = (cache.ped and cache.ped ~= 0) and cache.ped or PlayerPedId()
            mugshot = exports['MugShotBase64']:GetMugShotBase64(ped, false)
        end)
    end
    left.mugshot = mugshot or ''

    -- 2. Character Name:
    local charName = nil
    if pData and pData.charinfo then
        local fn = pData.charinfo.firstname or ''
        local ln = pData.charinfo.lastname or ''
        if fn ~= '' or ln ~= '' then
            charName = fn .. ' ' .. ln
        end
    end
    if not charName or charName == '' then
        charName = GetPlayerName(PlayerId()) or 'Citizen'
    end
    left.label = charName

    -- 3. Identity / Citizen Card ID ("la cart"):
    if pData and pData.citizenid and pData.citizenid ~= '' then
        left.id = pData.citizenid
    else
        left.id = tostring(GetPlayerServerId(PlayerId()))
    end

    -- 4. Money & Bank ("la flos"):
    local cash = 0
    local bank = 0

    local oxCash = exports.ox_inventory:Search('count', 'money')
    if oxCash ~= nil then
        cash = oxCash
    elseif left.items then
        for _, item in pairs(left.items) do
            if item and item.name == 'money' then
                cash = cash + (item.count or item.amount or 0)
            end
        end
    elseif pData and pData.money and pData.money.cash then
        cash = pData.money.cash
    end

    if pData and pData.money and pData.money.bank then
        bank = pData.money.bank
    end

    left.pdata = {
        money = cash,
        bank = bank
    }

    left.slots = shared.playerslots

    SendNUIMessage({
        action = "setupInventory",
        data = {
            leftInventory = left,
            rightInventory = right,
            mouseTrailActive = Prism.mouseTrailActive,
            ThemeSettings = Prism.ThemeSettings,
            Texts = Prism.Texts,
            UseNativeLabeling = Prism.UseNativeLabeling
        }
    })
end
