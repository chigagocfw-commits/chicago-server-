RegisterNetEvent("origen_police:client:domyfinguer", function()
    local PlayerData = FW_GetPlayerData(false)
    local text = Config.Translations['domyfinguer']:format((PlayerData.charinfo.firstname .. " " .. PlayerData.charinfo.lastname))
    UseCommand('me', text)
end)

function LeavePoliceEquipment(p)
    local PlayerData = FW_GetPlayerData(false)
    local invID = "armas_policiales_" .. (p.station or 0).."_"..PlayerData.citizenid
    local stashData = Config.Stashes.PoliceEquipment
    OpenStash(invID, stashData.label, stashData.slots, stashData.weight, PlayerData.citizenid, true)
end

function PoliceInventory(p)
    local PlayerData = FW_GetPlayerData(false)
    local invID = "inventario_policial_" .. (p.station or 0)
    local stashData = Config.Stashes.PoliceInventory
    OpenStash(invID, stashData.label, stashData.slots, stashData.weight, PlayerData.citizenid, false)
end

function OpenEvidenceInventory(p)
    OpenMenu('dialog', GetCurrentResourceName(), 'evidenceInventory', {
        title = "Enter the Evidence ID",
    }, function(data, menu)
        if type(data) ~= "table" then
            data = {value = data}
        end
        if data and data.value then
            local text = tostring(data.value)
            if text and text:gsub("%s+", "") ~= "" then
                local stashData = Config.Stashes.Evidence
                OpenStash("org_police_evidence_"..text, stashData.label.." "..text, stashData.slots, stashData.weight, nil, false)
            end

            menu.close()
        else
            ShowNotification(Config.Translations.MustEnterNumber)
        end
    end, function(data, menu)
        menu.close()
    end)
end

function CanOpenQuickAccessMenu()
    -- Check if player can open quick access menu
    local PlayerData = FW_GetPlayerData(false)
    if PlayerData == nil or PlayerData.job == nil or PlayerData.job.name == nil then return false end
    return (CanOpenTablet(PlayerData.job.name)[1] and PlayerData.job.onduty)
end

function handCuff(cb) -- This is just a callback so you can do anything you want, there's no need to add anything if you don't want to.
    cb(true)
end