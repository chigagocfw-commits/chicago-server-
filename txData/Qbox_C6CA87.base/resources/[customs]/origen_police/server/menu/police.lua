-- Search Citizen Callback
FW_CreateCallback("origen_police:police:SearchCitizen", function(source, cb, data)
    local result = {}
    
    if Config.Framework == "qbcore" then
        local jobFilter = ""
        
        if data.job then
            local player = FW_GetPlayer(source)
            if not player then return end
            
            local category = CanOpenTablet(player.PlayerData.job.name)[2]
            
            for _, job in pairs(Config.JobCategory[category]) do
                local separator = (jobFilter ~= "") and "OR" or ""
                jobFilter = jobFilter .. separator .. " job LIKE '%\"name\":\"" .. job.name .. "\"%' "
            end
            
            jobFilter = "AND (" .. jobFilter .. ")"
        end
        
        local citizens = SearchCitizen(data.text, jobFilter)
        
        for i = 1, #citizens do
            local charinfo = json.decode(citizens[i].charinfo)
            local phone = GetPhoneFromIdentifier(citizens[i].citizenid)
            
            table.insert(result, {
                citizenid = citizens[i].citizenid,
                phone = phone,
                firstname = charinfo.firstname,
                lastname = charinfo.lastname,
                image = citizens[i].image
            })
        end
        
    elseif Config.Framework == "esx" then
        local jobFilter = ""
        
        if data.job then
            local player = FW_GetPlayer(source)
            if not player then return end
            
            local category = CanOpenTablet(player.PlayerData.job.name)[2]
            
            for _, job in pairs(Config.JobCategory[category]) do
                local separator = (jobFilter ~= "") and "OR" or ""
                jobFilter = jobFilter .. separator .. " job LIKE '%\"name\":\"" .. job.name .. "\"%' "
            end
            
            jobFilter = "OR (" .. jobFilter .. ")"
        end
        
        local citizens = SearchCitizen(data.text, jobFilter)
        
        for i = 1, #citizens do
            local phone = GetPhoneFromIdentifier(citizens[i].identifier)
            
            table.insert(result, {
                citizenid = citizens[i].identifier,
                phone = phone,
                firstname = citizens[i].firstname,
                lastname = citizens[i].lastname,
                image = citizens[i].image
            })
        end
    end
    
    -- Sort by name
    table.sort(result, function(a, b)
        return (a.firstname .. a.lastname) < (b.firstname .. b.lastname)
    end)
    
    cb(result)
end)

-- Get Citizen Callback
FW_CreateCallback("origen_police:police:GetCitizen", function(source, cb, data)
    local citizenData = false
    local player = FW_GetPlayer(source)
    if not player then return cb(false) end
    
    local category = CanOpenTablet(source)[2]
    
    if Config.Framework == "qbcore" then
        local citizen = GetCitizen(data.citizenid)
        
        if citizen[1] then
            local charinfo = json.decode(citizen[1].charinfo)
            local job = json.decode(citizen[1].job)
            local phone = GetPhoneFromIdentifier(citizen[1].citizenid)
            
            citizenData = {}
            citizenData.notes = MySQL.awaitQuery("SELECT * FROM origen_police_notes WHERE citizenid = ? ORDER BY id DESC", {data.citizenid})
            citizenData.bills = GetBillsFromCitizenID(data.citizenid, category)
            citizenData.licenses = json.encode(GetLicensesByIdentifier(data.citizenid))
            citizenData.properties = GetCitizenProperties(citizen[1].citizenid)
            citizenData.weapons = GetWeapons(data.citizenid, json.decode(citizen[1].inventory))
            -- Only show reports from the same job category
            local jobCategory = exports.origen_police:CanOpenTablet(player.PlayerData.job.name)[2]
            citizenData.reports = MySQL.awaitQuery("SELECT id, title FROM origen_police_reports WHERE job = @job AND (implicated LIKE @citizenid OR victims LIKE @citizenid) ORDER BY id DESC", {
                ["@job"] = jobCategory,
                ["@citizenid"] = "%" .. data.citizenid .. "%"
            })
            citizenData.vehicles = GetVehiclesByIdentifier(data.citizenid)
            citizenData.citizenid = citizen[1].citizenid
            citizenData.image = citizen[1].image
            citizenData.firstname = charinfo.firstname
            citizenData.lastname = charinfo.lastname
            citizenData.phone = phone
            citizenData.iban = GetPlayerBankNumber(data.citizenid, charinfo.account)
            citizenData.dangerous = citizen[1].dangerous
            citizenData.wanted = citizen[1].wanted
            citizenData.birthdate = charinfo.birthdate
            citizenData.nationality = charinfo.nationality
            citizenData.gender = GetGender(charinfo.gender)
            citizenData.job = job.label
            citizenData.grade = job.grade.name
            citizenData.ankle = GetTrackerFromCitizenid(citizen[1].citizenid)
        end
        
    elseif Config.Framework == "esx" then
        local citizen = GetCitizen(data.citizenid)
        
        if citizen[1] then
            local phone = GetPhoneFromIdentifier(citizen[1].identifier)
            local vehicles = GetVehiclesByIdentifier(data.citizenid)
            local properties = GetCitizenProperties(citizen[1].identifier)
            
            -- Process vehicles
            for i = 1, #vehicles do
                vehicles[i].vehicle = json.decode(vehicles[i].vehicle)
                vehicles[i].hash = vehicles[i].vehicle.model
                vehicles[i].garage = "Garage"
            end
            
            -- Get job info
            local jobData = Framework.Shared.Jobs[citizen[1].job]
            local gradeName = "XXXXXXXXX"
            
            if jobData then
                if jobData.grades[tostring(citizen[1].job_grade)] then
                    gradeName = jobData.grades[tostring(citizen[1].job_grade)].label
                end
                jobData = jobData.label
            else
                jobData = citizen[1].job
            end
            
            citizenData = {}
            citizenData.notes = MySQL.awaitQuery("SELECT * FROM origen_police_notes WHERE citizenid = ? ORDER BY id DESC", {data.citizenid})
            citizenData.bills = GetBillsFromCitizenID(data.citizenid, category)
            citizenData.licenses = json.encode(GetLicensesByIdentifier(data.citizenid))
            citizenData.properties = properties
            -- Only show reports from the same job category
            local jobCategory = exports.origen_police:CanOpenTablet(player.PlayerData.job.name)[2]
            citizenData.reports = MySQL.awaitQuery("SELECT id, title FROM origen_police_reports WHERE job = @job AND (implicated LIKE @citizenid OR victims LIKE @citizenid) ORDER BY id DESC", {
                ["@job"] = jobCategory,
                ["@citizenid"] = "%" .. data.citizenid .. "%"
            })
            citizenData.vehicles = vehicles or {}
            citizenData.citizenid = citizen[1].identifier
            citizenData.weapons = GetWeapons(data.citizenid, json.decode(citizen[1].inventory))
            citizenData.image = citizen[1].image
            citizenData.firstname = citizen[1].firstname
            citizenData.lastname = citizen[1].lastname
            citizenData.phone = phone
            citizenData.iban = GetPlayerBankNumber(citizen[1].identifier)
            citizenData.dangerous = citizen[1].dangerous
            citizenData.wanted = citizen[1].wanted
            citizenData.birthdate = citizen[1].dateofbirth
            citizenData.nationality = GetPlayerNationality(citizen[1].identifier)
            citizenData.gender = GetGender(citizen[1].sex)
            citizenData.job = jobData
            citizenData.grade = gradeName
            citizenData.ankle = GetTrackerFromCitizenid(citizen[1].identifier)
        end
    end
    
    cb(citizenData)
end)

-- Search Vehicle Callback
FW_CreateCallback("origen_police:police:SearchVehicle", function(source, cb, data)
    local result = {}
    
    if Config.Framework == "qbcore" then
        local vehicles = SearchDataFromVehicle(data.plate)
        
        for i = 1, #vehicles do
            local charinfo = json.decode(vehicles[i].charinfo)
            local owner = "Unknown"
            
            if charinfo then
                owner = charinfo.firstname .. " " .. charinfo.lastname .. " (" .. vehicles[i].citizenid .. ")"
            end
            
            table.insert(result, {
                hash = vehicles[i].hash,
                plate = vehicles[i].plate,
                owner = owner,
                garage = vehicles[i].garage or "Outside"
            })
        end
        
    elseif Config.Framework == "esx" then
        local vehicles = SearchDataFromVehicle(data.plate)
        
        for i = 1, #vehicles do
            local owner = "Unknown"
            
            if vehicles[i].firstname then
                owner = vehicles[i].firstname .. " " .. vehicles[i].lastname .. " (" .. vehicles[i].owner .. ")"
            end
            
            table.insert(result, {
                hash = json.decode(vehicles[i].vehicle).model,
                plate = vehicles[i].plate,
                owner = owner,
                garage = "Garage"
            })
        end
    end
    
    cb(result)
end)

-- New Police Note Callback
FW_CreateCallback("origen_police:police:NewPoliceNote", function(source, cb, data)
    local player = FW_GetPlayer(source)
    if not player then return end
    
    local author = player.PlayerData.charinfo.firstname .. " " .. 
                   player.PlayerData.charinfo.lastname .. " (" .. 
                   (player.PlayerData.metadata.police_badge or "0000") .. ")"
    
    MySQL.insert("INSERT INTO origen_police_notes (citizenid, title, description, author) VALUES (?, ?, ?, ?)", {
        data.citizenid .. (data.police and "-police" or ""),
        data.noteTitle,
        data.noteText,
        author
    }, function(insertId)
        if insertId then
            cb({
                id = insertId,
                author = author,
                date = os.time()
            })
            
            CreateLog({
                type = "Notes",
                embed = {
                    title = Config.LogsTranslations.CreateNote.title,
                    description = Config.LogsTranslations.CreateNote.message:format(data.noteTitle, data.noteText, author),
                    color = 1791423
                },
                source = source
            })
        else
            TriggerClientEvent("origen_police:ShowNotification", source, Config.Translations.ProblemCreateNote)
            cb(false)
        end
    end)
end)

-- Update Police Note Callback
FW_CreateCallback("origen_police:police:UpdatePoliceNote", function(source, cb, data)
    local success = false
    
    if data.type == "pin" then
        local affected = MySQL.awaitUpdate("UPDATE origen_police_notes SET fixed = 1 WHERE id = ?", {data.noteid})
        success = affected > 0
        
    elseif data.type == "unpin" then
        local affected = MySQL.awaitUpdate("UPDATE origen_police_notes SET fixed = 0 WHERE id = ?", {data.noteid})
        success = affected > 0
        
    elseif data.type == "delete" then
        local result = MySQL.awaitQuery("DELETE FROM origen_police_notes WHERE id = ?", {data.noteid})
        success = result.affectedRows > 0
        
        CreateLog({
            type = "Notes",
            embed = {
                title = Config.LogsTranslations.DeleteNote.title,
                description = Config.LogsTranslations.DeleteNote.message:format(data.noteid),
                color = 1791423
            },
            source = source
        })
    end
    
    cb(success)
end)

-- Update Citizen Status Callback
FW_CreateCallback("origen_police:police:UpdateCitizenStatus", function(source, cb, data)
    if Config.Framework == "qbcore" then
        local affected = MySQL.awaitUpdate("UPDATE players SET " .. data.column .. " = ? WHERE citizenid = ?", {
            data.value,
            data.citizenid
        })
        cb(affected > 0)
        
    elseif Config.Framework == "esx" then
        local affected = MySQL.awaitUpdate("UPDATE users SET " .. data.column .. " = ? WHERE identifier = ?", {
            data.value,
            data.citizenid
        })
        cb(affected > 0)
    end
end)

-- Update Citizen Image Callback
FW_CreateCallback("origen_police:police:UpdateCitizenImage", function(source, cb, data)
    if Config.Framework == "qbcore" then
        local affected = MySQL.awaitUpdate("UPDATE players SET image = ? WHERE citizenid = ?", {
            data.value,
            data.citizenid
        })
        cb(affected > 0)
        
    elseif Config.Framework == "esx" then
        local affected = MySQL.awaitUpdate("UPDATE users SET image = ? WHERE identifier = ?", {
            data.value,
            data.citizenid
        })
        cb(affected > 0)
    end
end)

-- New Report Callback
FW_CreateCallback("origen_police:police:NewReport", function(source, cb)
    local player = FW_GetPlayer(source)
    if not player then return end
    
    local timestamp = os.time() * 1000
    local author = player.PlayerData.charinfo.firstname .. " " .. 
                   player.PlayerData.charinfo.lastname .. " (" .. 
                   (player.PlayerData.metadata.police_badge or "0000") .. ")"
    local category = exports.origen_police:CanOpenTablet(player.PlayerData.job.name)[2]
    
    MySQL.insert("INSERT INTO origen_police_reports (title, author, job) VALUES (?, ?, ?)", {
        exports.origen_police:GetConfig("Translations").IntroduceName,
        author,
        category
    }, function(insertId)
        if insertId then
            cb({
                id = insertId,
                date = timestamp,
                author = author
            })
        else
            TriggerClientEvent("origen_police:ShowNotification", source, Config.Translations.ProblemCreateReport)
            cb(false)
        end
    end)
end)

-- Get 100 Reports Callback
FW_CreateCallback("origen_police:police:Get100Reports", function(source, cb)
    local player = FW_GetPlayer(source)
    if not player then return end
    
    local category = exports.origen_police:CanOpenTablet(player.PlayerData.job.name)[2]
    local reports = MySQL.awaitQuery("SELECT id, title, author, date, tags FROM origen_police_reports WHERE job = ? ORDER BY id DESC LIMIT 100", {category})
    
    cb(reports)
end)

-- Search Report Callback
FW_CreateCallback("origen_police:police:SearchReport", function(source, cb, data)
    local result = nil
    local player = FW_GetPlayer(source)
    if not player then return end
    
    local category = exports.origen_police:CanOpenTablet(player.PlayerData.job.name)[2]
    
    if data.tags then
        if data.text ~= "" then
            result = MySQL.awaitQuery("SELECT id, title, author, date, tags FROM origen_police_reports WHERE (id LIKE @text OR title LIKE @text OR author LIKE @text) AND job = @job AND tags LIKE @tags ORDER BY id DESC LIMIT 100", {
                ["@text"] = "%" .. data.text .. "%",
                ["@tags"] = "%" .. data.tags .. "%",
                ["@job"] = category
            })
        else
            result = MySQL.awaitQuery("SELECT id, title, author, date, tags FROM origen_police_reports WHERE job = @job AND tags LIKE @tags ORDER BY id DESC LIMIT 100", {
                ["@job"] = category,
                ["@tags"] = "%" .. data.tags .. "%"
            })
        end
    else
        result = MySQL.awaitQuery("SELECT id, title, author, date, tags FROM origen_police_reports WHERE job = @job AND (id LIKE @text OR title LIKE @text OR author LIKE @text) ORDER BY id DESC LIMIT 100", {
            ["@job"] = category,
            ["@text"] = "%" .. data.text .. "%"
        })
    end
    
    cb(result)
end)

-- Get Report Callback
FW_CreateCallback("origen_police:police:GetReport", function(source, cb, data)
    local player = FW_GetPlayer(source)
    if not player then return cb(nil) end
    
    local jobCategory = exports.origen_police:CanOpenTablet(player.PlayerData.job.name)[2]
    
    -- Only allow viewing reports from the same job category
    local report = MySQL.awaitQuery("SELECT * FROM origen_police_reports WHERE id = ? AND job = ?", {data.reportid, jobCategory})
    
    if report and report[1] then
        local billsByPerson = {}
        local bills = GetBillsFromReporter(data.reportid)
        
        for _, bill in pairs(bills) do
            billsByPerson[bill.citizenid] = {
                bills = bill.concepts,
                price = bill.price,
                months = bill.months
            }
        end
        
        report[1].implicated = json.decode(report[1].implicated)
        
        for i = 1, #report[1].implicated do
            report[1].implicated[i].bills = billsByPerson[report[1].implicated[i].citizenid] or {}
        end
        
        report[1].implicated = json.encode(report[1].implicated)
        
        cb(report[1])
    else
        cb(false)
    end
end)

-- Update Report Callback
FW_CreateCallback("origen_police:police:UpdateReport", function(source, cb, data)
    local player = FW_GetPlayer(source)
    if not player then return cb(false) end
    
    local jobCategory = exports.origen_police:CanOpenTablet(player.PlayerData.job.name)[2]
    
    -- Verify the report belongs to the same job category before allowing updates
    local reportCheck = MySQL.awaitQuery("SELECT job FROM origen_police_reports WHERE id = ?", {data.reportid})
    if not reportCheck[1] or reportCheck[1].job ~= jobCategory then
        return cb(false)
    end
    
    if data.key == "implicated" then
        local success = true
        
        -- Process bills for implicated persons
        for i = 1, #data.value do
            if data.value[i].bills and data.value[i].billid == "none" then
                local player = FW_GetPlayer(source)
                if not player then return end
                
                local author = player.PlayerData.charinfo.firstname .. " " .. 
                              player.PlayerData.charinfo.lastname .. " (" .. 
                              (player.PlayerData.metadata.police_badge or "0000") .. ")"
                local category = CanOpenTablet(player.PlayerData.job.name)[2]
                
                success = NewBillReport(i, data, author, category)
                data.value[i].billid = success
                
            elseif data.value[i].bills and data.value[i].billid and data.value[i].billid ~= "none" then
                success = UpdateBillReport(i, data)
            end
            
            data.value[i].bills = nil
            data.value[i].price = nil
            data.value[i].months = nil
        end
        
        if data.deletedbill then
            DeleteBill(source, {billid = data.deletedbill})
        end
        
        MySQL.update("UPDATE origen_police_reports SET implicated = ? WHERE id = ?", {
            json.encode(data.value),
            data.reportid
        }, function(affected)
            cb(affected > 0 and success)
        end)
    else
        MySQL.update("UPDATE origen_police_reports SET `" .. data.key .. "` = ? WHERE id = ?", {
            data.value,
            data.reportid
        }, function(affected)
            cb(affected > 0)
        end)
    end
end)

-- Delete Report Callback
FW_CreateCallback("origen_police:police:DeleteReport", function(source, cb, data)
    local player = FW_GetPlayer(source)
    if not player then return cb(false) end
    
    local jobCategory = exports.origen_police:CanOpenTablet(player.PlayerData.job.name)[2]
    
    -- Only allow deleting reports from the same job category
    local result = MySQL.awaitQuery("DELETE FROM origen_police_reports WHERE id = ? AND job = ?", {data.reportid, jobCategory})
    cb(result.affectedRows > 0)
end)

-- Send Bill Callback
FW_CreateCallback("origen_police:police:SendBill", function(source, cb, data)
    cb(sendBill(source, data))
end)

-- Delete Bill Callback
FW_CreateCallback("origen_police:police:DeleteBill", function(source, cb, data)
    cb(DeleteBill(source, data))
end)

-- Set Police Badge Callback
FW_CreateCallback("origen_police:police:SetPoliceBadge", function(source, cb, data)
    local player = FW_GetPlayerFromCitizenid(data.citizenid)
    if not player then return end
    
    local badgeLength = exports.origen_police:GetConfig("PoliceBadgeLength")
    
    -- Adjust badge length
    if string.len(data.badge) > badgeLength then
        data.badge = data.badge:sub(2, -1)
    elseif string.len(data.badge) < badgeLength then
        data.badge = "0" .. data.badge
    end
    
    player.Functions.SetMetaData("police_badge", data.badge)
    
    CreateLog({
        type = "Management",
        embed = {
            title = Config.LogsTranslations.SetBadge.title,
            description = Config.LogsTranslations.SetBadge.message:format(
                player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname .. " (" .. (data.badge or "0000") .. ")",
                data.badge
            ),
            color = 1791423
        },
        source = source
    })
    
    cb(true)
end)

-- Get Police List Callback
FW_CreateCallback("origen_police:police:GetPoliceList", function(source, cb, data)
    local result = {}
    local processed = {}
    local onlineIds = {}
    
    local player = FW_GetPlayer(source)
    if not player then
        cb({})
        return
    end
    
    local jobName = player.PlayerData.job.name
    local category = exports.origen_police:CanOpenTablet(jobName)[2]
    local jobs = exports.origen_police:GetConfig("JobCategory")[category]
    
    if Config.Framework == "qbcore" then
        for _, job in pairs(jobs) do
            local onDuty = Framework.Functions.GetPlayersOnDuty(job.name)
            for _, playerId in pairs(onDuty) do
                table.insert(onlineIds, playerId)
            end
        end
        
    elseif Config.Framework == "esx" then
        if jobs == nil then
            cb({})
            print("CANT FIND JOBS IN CONFIG WITH CATEGORY: ", category)
            return
        end
        
        if GetResourceState("origen_police") == "started" then
            onlineIds = exports.origen_police:GetPlayersInDuty(category) or {}
        end
    end
    
    -- Process online players
    for i = 1, #onlineIds do
        pcall(function()
            local onlinePlayer = FW_GetPlayer(onlineIds[i])
            
            if onlinePlayer and onlinePlayer.PlayerData then
                local dbTable = (Config.Framework == "qbcore") and "players" or "users"
                local idColumn = (Config.Framework == "qbcore") and "citizenid" or "identifier"
                
                local imageQuery = MySQL.awaitQuery("SELECT image FROM " .. dbTable .. " WHERE " .. idColumn .. " = ?", {
                    onlinePlayer.PlayerData.citizenid
                })
                
                local image = (imageQuery[1] and imageQuery[1].image) or nil
                local titleLabel = ""
                
                for _, job in pairs(jobs) do
                    if job.name == onlinePlayer.PlayerData.job.name then
                        titleLabel = job.titleListLabel
                        break
                    end
                end
                
                table.insert(result, {
                    citizenid = onlinePlayer.PlayerData.citizenid,
                    firstname = onlinePlayer.PlayerData.charinfo.firstname,
                    lastname = onlinePlayer.PlayerData.charinfo.lastname,
                    image = image,
                    badge = (onlinePlayer.PlayerData.metadata and onlinePlayer.PlayerData.metadata.police_badge) or "0000",
                    grade = onlinePlayer.PlayerData.job.grade.name,
                    job = onlinePlayer.PlayerData.job.name,
                    titleLabel = titleLabel or "x List"
                })
                
                processed[onlinePlayer.PlayerData.citizenid] = true
            end
        end)
    end
    
    -- Process offline players
    local function processOffline(offlinePlayers)
        for i = 1, #offlinePlayers do
            pcall(function()
                local identifier = (Config.Framework == "qbcore") and offlinePlayers[i].citizenid or offlinePlayers[i].identifier
                
                if not processed[identifier] then
                    local charinfo, metadata, job, grade
                    
                    local offlinePlayer = FW_GetPlayerFromCitizenid(identifier)
                    
                    if offlinePlayer and offlinePlayer.PlayerData then
                        charinfo = offlinePlayer.PlayerData.charinfo
                        metadata = offlinePlayer.PlayerData.metadata or {}
                        job = offlinePlayer.PlayerData.job
                        grade = job.grade.name
                    else
                        charinfo = json.decode(offlinePlayers[i].charinfo or "{}")
                        metadata = json.decode(offlinePlayers[i].metadata or "{}")
                        job = json.decode(offlinePlayers[i].job or "{}")
                        grade = offlinePlayers[i].job_grade or "unknown"
                    end
                    
                    local titleLabel = nil
                    for _, jobData in pairs(jobs) do
                        if jobData.name == job.name then
                            titleLabel = jobData.titleListLabel
                            break
                        end
                    end
                    
                    if titleLabel ~= nil then
                        table.insert(result, {
                            citizenid = identifier,
                            firstname = charinfo.firstname or "Unknown",
                            lastname = charinfo.lastname or "Unknown",
                            image = offlinePlayers[i].image or nil,
                            badge = metadata.police_badge or "0000",
                            grade = grade,
                            job = job.name or "unknown",
                            titleLabel = titleLabel
                        })
                    end
                end
            end)
        end
    end
    
    if jobs then
        local jobFilter = ""
        for _, job in pairs(jobs) do
            jobFilter = jobFilter .. "job LIKE '%" .. job.name .. "%' OR "
        end
        jobFilter = jobFilter:sub(1, -5)
        
        local offlinePlayers = GetPoliceList(jobFilter)
        if offlinePlayers then
            processOffline(offlinePlayers)
        end
    end
    
    -- Sort by name
    table.sort(result, function(a, b)
        return (a.firstname .. a.lastname) < (b.firstname .. b.lastname)
    end)
    
    cb(result)
end)

-- Get Police Callback
FW_CreateCallback("origen_police:police:GetPolice", function(source, cb, data)
    local player = FW_GetPlayerFromCitizenid(data.citizenid)
    local policeData = false
    
    if player and player.PlayerData and player.PlayerData.source ~= nil then
        local dbTable = (Config.Framework == "qbcore") and "players" or "users"
        local idColumn = (Config.Framework == "qbcore") and "citizenid" or "identifier"
        
        local imageQuery = MySQL.awaitQuery("SELECT image FROM " .. dbTable .. " WHERE " .. idColumn .. " = ?", {
            player.PlayerData.citizenid
        })
        
        local image = (imageQuery[1] and imageQuery[1].image) or nil
        local jobData = Framework.Shared.Jobs[player.PlayerData.job.name]
        local grade = player.PlayerData.job.grade.name
        
        if Config.Framework == "esx" and jobData then
            if jobData.grades[tostring(player.PlayerData.job.grade.level)] then
                grade = jobData.grades[tostring(player.PlayerData.job.grade.level)].label
            end
        end
        
        local department = "unk"
        if jobData and jobData.grades[tostring(player.PlayerData.job.grade.level)] then
            department = jobData.grades[tostring(player.PlayerData.job.grade.level)].type or "unk"
        end
        
        local phone = GetPhoneFromIdentifier(player.PlayerData.citizenid)
        
        policeData = {
            citizenid = player.PlayerData.citizenid,
            image = image,
            firstname = player.PlayerData.charinfo.firstname,
            lastname = player.PlayerData.charinfo.lastname,
            phone = phone,
            iban = GetPlayerBankNumber(player.PlayerData.citizenid, player.PlayerData.charinfo.account),
            birthdate = player.PlayerData.charinfo.birthdate,
            nationality = (Config.Framework == "qbcore") and player.PlayerData.charinfo.nationality or GetPlayerNationality(player.PlayerData.citizenid),
            badge = player.PlayerData.metadata.police_badge or "0000",
            gender = GetGender(player.PlayerData.charinfo.gender),
            condecorates = player.PlayerData.metadata.condecorates or {},
            divisions = player.PlayerData.metadata.divisions or {},
            department = department,
            grade = grade
        }
        
    else
        if Config.Framework == "qbcore" then
            local police = GetPolice(data.citizenid)
            
            if police[1] then
                local charinfo = json.decode(police[1].charinfo)
                local job = json.decode(police[1].job)
                local metadata = json.decode(police[1].metadata)
                local phone = GetPhoneFromIdentifier(police[1].citizenid)
                
                local department = "lspd"
                if Framework.Shared.Jobs[job.name] and Framework.Shared.Jobs[job.name].grades[tostring(job.grade.level)] then
                    department = Framework.Shared.Jobs[job.name].grades[tostring(job.grade.level)].type or "lspd"
                end
                
                policeData = {
                    citizenid = police[1].citizenid,
                    image = police[1].image,
                    firstname = charinfo.firstname,
                    lastname = charinfo.lastname,
                    phone = phone,
                    iban = GetPlayerBankNumber(police[1].citizenid, charinfo.account),
                    birthdate = charinfo.birthdate,
                    nationality = charinfo.nationality,
                    badge = metadata.police_badge or "0000",
                    gender = GetGender(charinfo.gender),
                    condecorates = metadata.condecorates or {},
                    divisions = metadata.divisions or {},
                    department = department,
                    grade = job.grade.name
                }
            end
            
        elseif Config.Framework == "esx" then
            local police = GetPolice(data.citizenid)
            
            if police[1] then
                local phone = GetPhoneFromIdentifier(police[1].identifier)
                local jobData = Framework.Shared.Jobs[police[1].job]
                local metadata = json.decode(police[1].metadata or "{}")
                
                local gradeName = "XXXXXXXXX"
                if jobData then
                    if jobData.grades[tostring(police[1].job_grade)] then
                        gradeName = jobData.grades[tostring(police[1].job_grade)].label
                    end
                end
                
                local department = "lspd"
                if jobData and jobData.grades[tostring(police[1].job_grade)] then
                    department = jobData.grades[tostring(police[1].job_grade)].type or "lspd"
                end
                
                policeData = {
                    citizenid = police[1].identifier,
                    image = police[1].image,
                    firstname = police[1].firstname,
                    lastname = police[1].lastname,
                    phone = phone,
                    iban = GetPlayerBankNumber(police[1].identifier),
                    birthdate = police[1].dateofbirth,
                    nationality = GetPlayerNationality(police[1].identifier),
                    badge = metadata.police_badge or "0000",
                    gender = GetGender(police[1].sex),
                    condecorates = metadata.condecorates or {},
                    divisions = metadata.divisions or {},
                    department = department,
                    grade = gradeName
                }
            end
        end
    end
    
    if policeData then
        policeData.notes = MySQL.awaitQuery("SELECT * FROM origen_police_notes WHERE citizenid = ? ORDER BY id DESC", {
            data.citizenid .. "-police"
        })
        
        policeData.reports = MySQL.awaitQuery("SELECT id, title FROM origen_police_reports WHERE cops LIKE @citizenid OR author LIKE @name ORDER BY id DESC", {
            ["@citizenid"] = "%" .. data.citizenid .. "%",
            ["@name"] = "%" .. policeData.firstname .. " " .. policeData.lastname .. "%"
        })
    end
    
    cb(policeData)
end)

-- Update Police MetaData Callback
FW_CreateCallback("origen_police:police:UpdatePoliceMetaData", function(source, cb, data)
    local player = FW_GetPlayerFromCitizenid(data.citizenid)
    
    if not player or not player.PlayerData then
        cb(false)
        return
    end
    
    if not player.PlayerData.metadata[data.type] then
        player.PlayerData.metadata[data.type] = {}
    end
    
    player.PlayerData.metadata[data.type][data.id] = data.value
    player.Functions.SetMetaData(data.type, player.PlayerData.metadata[data.type])
    
    if not player.PlayerData.source then
        if player.Functions.Save then
            player.Functions.Save()
        end
    end
    
    cb(true)
end)

-- Get Busqueda (Wanted) Callback
FW_CreateCallback("origen_police:police:GetBusqueda", function(source, cb)
    if Config.Framework == "qbcore" then
        local wanted, result = GetWanted()
        
        for i = 1, #wanted do
            wanted[i].charinfo = json.decode(wanted[i].charinfo)
            
            table.insert(result, {
                citizenid = wanted[i].citizenid,
                name = wanted[i].charinfo.firstname .. " " .. wanted[i].charinfo.lastname,
                image = wanted[i].image
            })
        end
        
        cb(result)
        
    elseif Config.Framework == "esx" then
        local wanted, result = GetWanted()
        
        for i = 1, #wanted do
            table.insert(result, {
                citizenid = wanted[i].identifier,
                name = wanted[i].firstname .. " " .. wanted[i].lastname,
                image = wanted[i].image
            })
        end
        
        cb(result)
    end
end)

-- Get Morosos (Debtors) Callback
FW_CreateCallback("origen_police:police:GetMorosos", function(source, cb)
    local player = FW_GetPlayer(source)
    if not player then return end
    
    local tabletAccess = CanOpenTablet(player.PlayerData.job.name)
    local category = tabletAccess and tabletAccess[2] or nil
    
    if not category then
        cb({})
        return
    end
    
    if Config.Framework == "qbcore" then
        local debtors = GetDebors(category) or {}
        local result = {}
        
        for i = 1, #debtors do
            debtors[i].charinfo = json.decode(debtors[i].charinfo)
            
            table.insert(result, {
                citizenid = debtors[i].citizenid,
                price = debtors[i].totalprice,
                name = debtors[i].charinfo.firstname .. " " .. debtors[i].charinfo.lastname,
                image = debtors[i].image
            })
        end
        
        table.sort(result, function(a, b)
            return a.price > b.price
        end)
        
        cb(result)
        
    elseif Config.Framework == "esx" then
        local debtors = GetDebors(category) or {}
        local result = {}
        
        for i = 1, #debtors do
            table.insert(result, {
                citizenid = debtors[i].citizenid,
                price = debtors[i].totalprice,
                name = debtors[i].firstname .. " " .. debtors[i].lastname,
                image = debtors[i].image
            })
        end
        
        table.sort(result, function(a, b)
            return a.price > b.price
        end)
        
        cb(result)
    end
end)

-- Get Vehicle Callback
FW_CreateCallback("origen_police:police:GetVehicle", function(source, cb, data)
    local vehicleData = false
    
    if Config.Framework == "qbcore" then
        local vehicle = GetDataFromVehicle(data.plate)
        
        if vehicle[1] then
            local charinfo = json.decode(vehicle[1].charinfo)
            local owner = "Desconocido"
            
            if charinfo then
                owner = charinfo.firstname .. " " .. charinfo.lastname .. " (" .. vehicle[1].citizenid .. ")"
            end
            
            vehicleData = {
                hash = vehicle[1].hash,
                plate = vehicle[1].plate,
                owner = owner,
                garage = vehicle[1].garage or "Outside",
                wanted = vehicle[1].wanted,
                description = vehicle[1].description
            }
        end
        
    elseif Config.Framework == "esx" then
        local vehicle = GetDataFromVehicle(data.plate)
        
        if vehicle[1] then
            local owner = "Desconocido"
            
            if vehicle[1].firstname then
                owner = vehicle[1].firstname .. " " .. vehicle[1].lastname .. " (" .. vehicle[1].owner .. ")"
            end
            
            vehicleData = {
                hash = json.decode(vehicle[1].vehicle).model,
                plate = vehicle[1].plate,
                owner = owner,
                garage = "Garage",
                wanted = vehicle[1].wanted,
                description = vehicle[1].description
            }
        end
    end
    
    cb(vehicleData)
end)

-- Update Vehicle Callback
FW_CreateCallback("origen_police:police:UpdateVehicle", function(source, cb, data)
    cb(UpdateVehicleData(data.key, data.value, data.plate))
end)

-- Get Police Count Callback
FW_CreateCallback("origen_police:server:GetPoliceCount", function(source, cb)
    local player = FW_GetPlayer(source)
    if not player then return end
    
    if Config.Framework == "qbcore" then
        local tabletAccess = CanOpenTablet(player.PlayerData.job.name)
        local category = tabletAccess and tabletAccess[2] or nil
        local onDuty = {}
        
        if category and Config.JobCategory[category] then
            for _, job in pairs(Config.JobCategory[category]) do
                local jobOnDuty = Framework.Functions.GetPlayersOnDuty(job.name)
                if jobOnDuty then
                    for i = 1, #jobOnDuty do
                        table.insert(onDuty, jobOnDuty[i])
                    end
                end
            end
        end
        
        cb(#onDuty)
        
    elseif Config.Framework == "esx" then
        local tabletAccess = CanOpenTablet(player.PlayerData.job.name)
        local category = tabletAccess and tabletAccess[2] or nil
        local count = 0
        if category then
            local playersInDuty = GetPlayersInDuty(category)
            count = playersInDuty and #playersInDuty or 0
        end
        cb(count)
    end
end)

-- Set Police Job Callback
FW_CreateCallback("origen_police:server:SetPoliceJob", function(source, cb, data)
    local player = FW_GetPlayer(source)
    if not player then return end
    
    local jobName = player.PlayerData.job.name
    local category = exports.origen_police:CanOpenTablet(jobName)[2]
    
    if not category then
        print("A player tried to hire someone without a job category with citizenid: " .. player.PlayerData.citizenid)
        cb(false)
        return
    end
    
    local targetPlayer = FW_GetPlayerFromCitizenid(data.citizenid)
    if not targetPlayer then return end
    
    local targetGrade = tonumber(targetPlayer.PlayerData.job.grade.level)
    local playerGrade = tonumber(player.PlayerData.job.grade.level)
    
    if targetGrade >= playerGrade then
        cb("You can't change the grade of someone with the same or higher grade than you.")
        return
    end
    
    data.grade = data.grade and tonumber(data.grade) or 0
    
    if not data.job then
        data.job = "unemployed"
        data.grade = 0
    end
    
    if targetPlayer then
        data.job = string.lower(data.job)
        
        if data.job == "unemployed" then
            if Config.Framework == "esx" then
                if targetPlayer.PlayerData and targetPlayer.PlayerData.source then
                    DropDutyPlayer(targetPlayer.PlayerData.source)
                end
            end
            
            targetPlayer.Functions.SetMetaData("police_badge", "0000")
            targetPlayer.Functions.SetMetaData("divisions", {})
            targetPlayer.Functions.SetMetaData("condecorates", {})
            
            CreateLog({
                type = "Management",
                embed = {
                    title = Config.LogsTranslations.FirePolice.title,
                    description = Config.LogsTranslations.FirePolice.message:format(
                        targetPlayer.PlayerData.charinfo.firstname .. " " .. targetPlayer.PlayerData.charinfo.lastname
                    ),
                    color = 1791423
                },
                source = source
            })
        end
        
        if targetPlayer.PlayerData and targetPlayer.PlayerData.source then
            targetPlayer.Functions.SetJob(data.job, data.grade)
        else
            local jobData = {
                name = data.job,
                label = Framework.Shared.Jobs[data.job].label,
                onduty = Framework.Shared.Jobs[data.job].defaultDuty,
                grade = {}
            }
            
            local gradeStr = tostring(data.grade) or "0"
            if Framework.Shared.Jobs[data.job].grades[gradeStr] then
                local gradeData = Framework.Shared.Jobs[data.job].grades[gradeStr]
                jobData.grade.name = gradeData.name
                jobData.grade.level = gradeStr
                jobData.payment = gradeData.payment or 30
                jobData.isboss = gradeData.isboss or false
            else
                jobData.grade.name = "No Grades"
                jobData.grade.level = 0
                jobData.payment = 30
                jobData.isboss = false
            end
            
            local playerInfo = MySQL.awaitQuery("SELECT " .. 
                (Config.Framework == "qbcore" and "charinfo" or "firstname, lastname") .. 
                ", image FROM " .. 
                (Config.Framework == "qbcore" and "players" or "users") .. 
                " WHERE " .. 
                (Config.Framework == "qbcore" and "citizenid" or "identifier") .. 
                " = ?", {data.citizenid})
            
            if Config.Framework == "qbcore" then
                MySQL.awaitUpdate("UPDATE players SET job = ? WHERE citizenid = ?", {
                    json.encode(jobData),
                    data.citizenid
                })
                
                playerInfo[1].charinfo = json.decode(playerInfo[1].charinfo)
                
                cb({
                    firstname = playerInfo[1].charinfo.firstname,
                    lastname = playerInfo[1].charinfo.lastname,
                    citizenid = data.citizenid,
                    image = playerInfo[1].image,
                    grade = jobData.grade.name
                })
            else
                MySQL.awaitUpdate("UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?", {
                    jobData.name,
                    tonumber(jobData.grade.level),
                    data.citizenid
                })
                
                cb({
                    firstname = playerInfo[1].firstname,
                    lastname = playerInfo[1].lastname,
                    citizenid = data.citizenid,
                    image = playerInfo[1].image,
                    grade = jobData.grade.name
                })
            end
        end
    else
        local imageQuery = MySQL.awaitQuery("SELECT image FROM " .. 
            (Config.Framework == "qbcore" and "players" or "users") .. 
            " WHERE " .. 
            (Config.Framework == "qbcore" and "citizenid" or "identifier") .. 
            " = ?", {targetPlayer.PlayerData.citizenid})
        
        local image = (imageQuery[1] and imageQuery[1].image) or nil
        
        if data.job ~= "unemployed" then
            if targetPlayer.PlayerData and targetPlayer.PlayerData.source then
                TriggerClientEvent("origen_police:toggleDuty", tonumber(targetPlayer.PlayerData.source), true)
            end
        end
        
        CreateLog({
            type = "Management",
            embed = {
                title = Config.LogsTranslations.HirePolice.title,
                description = Config.LogsTranslations.HirePolice.message:format(
                    targetPlayer.PlayerData.charinfo.firstname .. " " .. targetPlayer.PlayerData.charinfo.lastname,
                    data.job,
                    data.grade
                ),
                color = 1791423
            },
            source = source
        })
        
        cb({
            firstname = targetPlayer.PlayerData.charinfo.firstname,
            lastname = targetPlayer.PlayerData.charinfo.lastname,
            citizenid = targetPlayer.PlayerData.citizenid,
            image = image,
            grade = targetPlayer.PlayerData.job.grade.name
        })
    end
end)