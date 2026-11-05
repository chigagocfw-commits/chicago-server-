--       _                           _   _             _                   _             _                
--   ___| | ___  __ _ _ __   ___  __| | | |__  _   _  | |__  _ __ __ _  __| |_   _   ___| |_ ___ _ __     
--  / __| |/ _ \/ _` | '_ \ / _ \/ _` | | '_ \| | | | | '_ \| '__/ _` |/ _` | | | | / __| __/ _ \ '_ \    
-- | (__| |  __/ (_| | | | |  __/ (_| | | |_) | |_| | | |_) | | | (_| | (_| | |_| | \__ \ ||  __/ | | |   
--  \___|_|\___|\__,_|_| |_|\___|\__,_| |_.__/ \__, | |_.__/|_|  \__,_|\__,_|\__, | |___/\__\___|_| |_|   
--  / _(_)_  _____  __| | | |__  _   _  | |__  |___/ ___(_)_ __ ___   | |__  |___/_ __ _ __ ___ _ __ __ _ 
-- | |_| \ \/ / _ \/ _` | | '_ \| | | | | '_ \ / _` |_  / | '_ ` _ \  | '_ \ / _ \ '__| '__/ _ \ '__/ _` |
-- |  _| |>  <  __/ (_| | | |_) | |_| | | | | | (_| |/ /| | | | | | | | | | |  __/ |  | | |  __/ | | (_| |
-- |_| |_/_/\_\___|\__,_| |_.__/ \__, | |_| |_|\__,_/___|_|_| |_| |_| |_| |_|\___|_|  |_|  \___|_|  \__,_|
--                               |___/
--   

-- This event is triggered on client every time the player makes a puff.
-- Use this for visual effects, sounds, UI updates, camera effects, etc.
-- This event is local/client-side only.

AddEventHandler("rtx_smoking:client:OnPuff", function(data)

    -- data.type = type of smoking item
    -- Possible values:
    -- "cigarette" = classic cigarette
    -- "cigar"     = cigar
    -- "joint"     = weed joint
    -- "bong"      = bong
    -- "vape"      = electronic vape
    -- "hookah"    = hookah / shisha

    if data.type == "vape" then
        -- Example: apply vape-related visual effect
    end

    if data.type == "bong" then
        -- Example: apply strong smoke effect
    end

    if data.type == "joint" then
        -- Example: apply weed high effect
    end

    if data.type == "cigarette" then
        -- Example: apply light nicotine effect
    end

    if data.type == "cigar" then
        -- Example: apply stronger nicotine effect
    end

    if data.type == "hookah" then
        -- Example: apply relaxed hookah smoke effect
    end

    -- data.amount = puff strength based on hold duration
    -- Example range:
    -- 0.1  = very small puff
    -- 10.0 = very strong puff

    local strength = data.amount

    -- data.holdDuration = how long the puff button was held in milliseconds
    -- Example:
    -- 500  = short puff
    -- 2000 = long puff

    local holdTime = data.holdDuration

    -- data.autoReleased = true if puff ended automatically
    -- false if player released the key manually
    -- For hookah this can usually be false unless you add auto-release logic.

    local wasAuto = data.autoReleased

    -- data.item = exact item name
    -- Examples:
    -- "vape_1_red"
    -- "bong"
    -- "joint_og_kush"
    -- "cigarette_redwood"
    -- "hookah"

    local itemName = data.item

    -- data.hookahId = unique hookah ID
    -- Only exists when data.type == "hookah"

    local hookahId = data.hookahId

    -- data.stats = current item stats, depends on type

    -- Example for vape:
    -- data.stats.battery
    -- data.stats.fill
    -- data.stats.heat
    -- data.stats.durability

    -- Example for bong:
    -- data.stats.water
    -- data.stats.fill
    -- data.stats.smokeLevel
    -- data.stats.durability

    -- Example for joint/cigarette/cigar:
    -- data.stats.durability
    -- data.stats.burnLevel
    -- data.stats.smokeLevel
    -- data.stats.fill

    -- Example for hookah:
    -- data.stats.water
    -- data.stats.tobacco
    -- data.stats.coal
    -- data.stats.hoses

    local stats = data.stats

end)
function ShowGtaClassicInteraction(textdata)
	AddTextEntry("gtavclassicinteractionrtxaireastery", textdata)
	BeginTextCommandDisplayHelp("gtavclassicinteractionrtxaireastery")
	EndTextCommandDisplayHelp(0, false, true, -1)
end

function showHelp(text, coords)
    AddTextEntry('floatingHelpNotification' .. GetGameTimer()//10000, "<FONT SIZE='8'>" .. text)
    SetFloatingHelpTextWorldPosition(1, coords)
    SetFloatingHelpTextStyle(1, 1, 2, -1, 3, 0) 
    BeginTextCommandDisplayHelp('floatingHelpNotification' .. GetGameTimer()//10000)
    EndTextCommandDisplayHelp(2, false, false, 0)
end


function GetPlayerGender()
    local ped = PlayerPedId()
    local model = GetEntityModel(ped)

    if model == GetHashKey("mp_m_freemode_01") then
        return "male"
    elseif model == GetHashKey("mp_f_freemode_01") then
        return "female"
    end

    return "unknown"
end

function GetCoughSoundKey()
    local gender = GetPlayerGender()

    if gender == "female" then
        return "cough_female"
    end

    return "cough_male"
end

function GetExhaleSoundKey()
    local gender = GetPlayerGender()

    if gender == "female" then
        return "exhalefemale"
    end

    return "exhalemale"
end

function DrawText3D(x, y, z, text)
	local onScreen,_x,_y=World3dToScreen2d(x,y,z)
	local px,py,pz=table.unpack(GetGameplayCamCoords()) 
	if onScreen then
		SetTextScale(0.35, 0.35)
		SetTextFont(4)
		SetTextProportional(1)
		SetTextColour(255, 255, 255, 255)
		SetTextEntry("STRING")
		SetTextCentre(1)
		AddTextComponentString(text)
        DrawText(_x,_y)
        local factor = (string.len(text)) / 240
		DrawRect(_x, _y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 150)
	end
end

function ShowInteraction(textdata, coordsdata)
	if Config.SmokingInteractionSystem == 1 then
		SendNUIMessage({
			message = "infonotifyshow",
			infonotifytext = Language[Config.Language][textdata.."-normal"]
		})	
		Citizen.Wait(500)
	elseif Config.SmokingInteractionSystem == 2 then
		DrawText3D(coordsdata.x, coordsdata.y, coordsdata.z, Language[Config.Language][textdata.."-3d"])	
	elseif Config.SmokingInteractionSystem == 3 then	
		ShowGtaClassicInteraction(Language[Config.Language][textdata.."-classic"])
	elseif Config.SmokingInteractionSystem == 4 then	
		showHelp(Language[Config.Language][textdata.."-float"], coordsdata)
	end
end

function HideInteraction()
	if Config.SmokingInteractionSystem == 1 then
		SendNUIMessage({ message = "hidenotify" })
	end
end

function AddTargetZone(targettype, targetnamedata, targettypedata, targetheading, targetdistance, targetlabel, targeticon, targetevent)
	if Config.Targettype == "qtarget" then
		if targettype == "coords" then
			local targetcoordsdata = vector3(targettypedata.x, targettypedata.y, targettypedata.z+0.5)
			exports[Config.TargetSystemsNames.qtarget]:AddBoxZone(targetnamedata, targetcoordsdata, 2.5, 2.5, {
				name = targetnamedata,
				heading = targetheading,
				debugPoly = false,
				minZ = targetcoordsdata.z-1.5,
				maxZ = targetcoordsdata.z+1.5,
				}, {
					options = {
						{
							event = targetevent,
							icon = targeticon,
							label = targetlabel
						},
					},
					distance = targetdistance
			})	
		else
			exports[Config.TargetSystemsNames.qtarget]:AddTargetModel({GetHashKey(targettypedata)}, {
				options = {
					{
						name = targetnamedata,
						event = targetevent,
						icon = targeticon,
						label = targetlabel,
					},
				},
				distance = targetdistance
			})		
		end
	elseif Config.Targettype == "qbtarget" then
		if targettype == "coords" then
			local targetcoordsdata = vector3(targettypedata.x, targettypedata.y, targettypedata.z+0.5)
			exports[Config.TargetSystemsNames.qbtarget]:AddBoxZone(targetnamedata, targetcoordsdata, 2.5, 2.5, {
				name = targetnamedata,
				heading = targetheading,
				debugPoly = false,
				minZ = targetcoordsdata.z-1.5,
				maxZ = targetcoordsdata.z+1.5,
			}, {
				options = {
					{
					  type = "client",
					  action = function(entity) 
						TriggerEvent(targetevent)
					  end,
					  icon = targeticon,
						  label = targetlabel,
						},
					},
				distance = targetdistance
			})	
		else
			exports[Config.TargetSystemsNames.qbtarget]:AddTargetModel({GetHashKey(targettypedata)}, {
				options = {
					{
						name = targetnamedata,
						event = targetevent,
						icon = targeticon,
						label = targetlabel,
					},
				},
				distance = targetdistance
			})				
		end
	elseif Config.Targettype == "oxtarget" then								
		if targettype == "coords" then
			local targetcoordsdata = vector3(targettypedata.x, targettypedata.y, targettypedata.z+0.5)
			exports[Config.TargetSystemsNames.oxtarget]:addBoxZone({
				coords = targetcoordsdata,
				size = vec3(2, 2, 2),
				rotation = targetheading,
				options = {
					{
						name = targetnamedata,
						event = targetevent,
						icon = targeticon,
						distance = targetdistance,
						label = targetlabel,
						canInteract = function(entity, distance, coords, name)
							return true
						end
					}
				}
			})	
		else
			exports[Config.TargetSystemsNames.oxtarget]:addModel(GetHashKey(targettypedata), {
				{
					name = targetnamedata,
					event = targetevent,
					icon = targeticon,
					label = targetlabel,
				}						
			})				
		end
	end
end

progressPromise = nil

RegisterNUICallback("rtxProgressStart", function(_, cb)
    
    cb({})
end)

RegisterNUICallback("rtxProgressDone", function(data, cb)
    if progressPromise then
        progressPromise:resolve(true)
        progressPromise = nil
    end
    cb({})
end)

RegisterNUICallback("rtxProgressCancel", function(_, cb)
    if progressPromise then
        progressPromise:resolve(false)
        progressPromise = nil
    end
    cb({})
end)

function StartProgress(opts)
    if progressPromise then return false end

    progressPromise = promise.new()
    SendNUIMessage({
        message   = "RTX_PROGRESS_START",
        title     = opts.title or "Progress",
        label     = opts.label or "",
        icon      = opts.icon or "fa-solid fa-spinner",
        timeMs    = opts.time or 5000,
        canCancel = opts.canCancel ~= false
    })

    return Citizen.Await(progressPromise)
end

local HelpNotify = {}

function HelpNotify.Show(opts)
    opts = opts or {}

    SendNUIMessage({
        message    = "HelpNotifyShow",
        title      = opts.title or "Help",
        text       = opts.text or "",
        tagline    = opts.tagline or nil,
        icon       = opts.icon or "fa-circle-info",
        keys       = opts.keys or nil,
        autoHideMs = opts.autoHideMs or 0
    })
end

function HelpNotify.Hide()
    SendNUIMessage({
        message = "HelpNotifyHide"
    })
end

exports("ShowHelpNotify", HelpNotify.Show)
exports("HideHelpNotify", HelpNotify.Hide)


local Notify = {}
local notifyIdCounter = 0

function Notify.Show(opts)
    opts = opts or {}
    notifyIdCounter = notifyIdCounter + 1
    local id = notifyIdCounter

    SendNUIMessage({
        message = "NotifyShow",
        id      = id,
        title   = opts.title or "Notification",
        text    = opts.text or "",
        type    = opts.type or "info",
        timeout = opts.timeout or 5000,
        icon    = opts.icon or nil
    })
	--PlaySoundEffect("sounds/soundnotify.mp3")
end

function Notify.Hide(id)
    if not id then return end

    SendNUIMessage({
        message = "NotifyHide",
        id      = id
    })
end

function Notify.HideAll()
    SendNUIMessage({
        message = "NotifyHide"
    })
end
exports("ShowNotify",     Notify.Show)
exports("HideNotify",     Notify.Hide)
exports("HideAllNotify",  Notify.HideAll)

function CreateHookahTargets()
	if Config.Targettype == "qtarget" then
		exports[Config.TargetSystemsNames.qtarget]:AddTargetModel({GetHashKey("rtx_sempre_smoking_shisha")}, {
			options = {
				{
					name = "hookahinteract",
					event = "rtx_smoking:Global:HookahInteractTarget",
					icon = Config.TargetIcons.hookahmanage,
					label = Language[Config.Language]["hookah"],
				},	
				{
					name = "hookahgrab",
					event = "rtx_smoking:Global:HookahHoseTarget",
					icon = Config.TargetIcons.hookahgrab,
					label = Language[Config.Language]["hookahhose"],
				},
			},
			distance = Config.HookahInteractDistance+2.5
		})		
	elseif Config.Targettype == "qbtarget" then
		exports[Config.TargetSystemsNames.qbtarget]:AddTargetModel({GetHashKey("rtx_sempre_smoking_shisha")}, {
			options = {
				{
					name = "hookahinteract",
					event = "rtx_smoking:Global:HookahInteractTarget",
					icon = Config.TargetIcons.hookahmanage,
					label = Language[Config.Language]["hookah"],
				},	
				{
					name = "hookahgrab",
					event = "rtx_smoking:Global:HookahHoseTarget",
					icon = Config.TargetIcons.hookahgrab,
					label = Language[Config.Language]["hookahhose"],
				},
			},
			distance =  Config.HookahInteractDistance+2.5
		})				
	elseif Config.Targettype == "oxtarget" then								
		exports[Config.TargetSystemsNames.oxtarget]:addModel(GetHashKey("rtx_sempre_smoking_shisha"), {
			{
				name = "hookahinteract",
				event = "rtx_smoking:Global:HookahInteractTarget",
				icon = Config.TargetIcons.hookahmanage,
				label = Language[Config.Language]["hookah"],
			},	
			{
				name = "hookahgrab",
				event = "rtx_smoking:Global:HookahHoseTarget",
				icon = Config.TargetIcons.hookahgrab,
				label = Language[Config.Language]["hookahhose"],
			},					
		})				
	end
end