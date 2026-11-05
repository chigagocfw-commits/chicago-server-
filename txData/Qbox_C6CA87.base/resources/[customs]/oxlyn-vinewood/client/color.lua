

-- Vinewood solid-color texture banks (cleaned from decompiled output)

VinewoodSolidColor = {}
local M = VinewoodSolidColor

---------------------------------------------------------------------
-- Constants / state
---------------------------------------------------------------------
local TEX_SIZE        = 64     -- runtime textures are 64 x 64
local MAX_SLOTS       = 4
local RELINK_INTERVAL = 5000   -- ms between re-link attempts
local DIAG_DURATION   = 60000  -- ms the on-screen check stays open

local SOURCE_DICT  = Config.Solid.TextureDictionary
local RUNTIME_DICT = GetCurrentResourceName() .. "_letter_colors"

local desired          = {}    -- [slot] = descriptor (what we want uploaded)
local banks            = {}    -- [slot] = runtime bank (texture + link state)
local runtimeTxd       = nil
local sourceRequested  = false
local stopped          = false
local lastRequestTime  = -math.huge
local diagActive       = false
local diagSession      = 0

local RAINBOW = {
    "#FF405C", "#FFBD45", "#F9EF61", "#48D99B",
    "#54BAFF", "#9773FF", "#EE6BDA",
}

---------------------------------------------------------------------
-- Colour helpers
---------------------------------------------------------------------
local function hexToRGB(hex)
    if type(hex) ~= "string" or not hex:match("^#%x%x%x%x%x%x$") then
        hex = "#FFFFFF"
    end
    return {
        tonumber(hex:sub(2, 3), 16),
        tonumber(hex:sub(4, 5), 16),
        tonumber(hex:sub(6, 7), 16),
    }
end

-- Build a descriptor { key, stops, horizontal } from a text layer
local function buildDescriptor(layer)
    local fillMode = layer.fillMode or "solid"

    local colors
    if fillMode == "rainbow" then
        colors = RAINBOW
    else
        colors = { layer.color or "#FFFFFF" }
    end

    if fillMode == "gradient" then
        colors[2] = layer.gradientColor or "#6FA8FF"
    end

    local direction = (layer.gradientDirection == "horizontal") and "horizontal" or "vertical"

    local stops = {}
    for i, hex in ipairs(colors) do
        stops[i] = hexToRGB(hex)
    end

    return {
        key        = fillMode .. ":" .. direction .. ":" .. table.concat(colors, ","),
        stops      = stops,
        horizontal = direction == "horizontal",
    }
end

-- Interpolate the descriptor's stops into TEX_SIZE RGB entries
local function buildGradientLine(desc)
    local line  = {}
    local count = #desc.stops

    for i = 0, TEX_SIZE - 1 do
        local pos = (i / (TEX_SIZE - 1)) * (count - 1)
        local idx = math.min(count, math.floor(pos) + 1)
        local a   = desc.stops[idx]
        local b   = desc.stops[math.min(count, idx + 1)]
        local t   = pos - (idx - 1)

        local rgb = {}
        for c = 1, 3 do
            rgb[c] = math.floor(a[c] + (b[c] - a[c]) * t + 0.5)
        end
        line[i + 1] = rgb
    end

    return line
end

---------------------------------------------------------------------
-- Resolution helpers
---------------------------------------------------------------------
local function getTextureResolution(dict, name, created)
    if not created then
        return { available = false, reason = "not_created" }
    end
    if type(GetTextureResolution) ~= "function" then
        return { available = false, reason = "native_unavailable" }
    end

    local ok, res = pcall(GetTextureResolution, dict, name)
    if not ok or not res then
        return { available = false, reason = "query_failed" }
    end

    local okXY, w, h = pcall(function() return res.x, res.y end)
    if okXY
        and type(w) == "number" and type(h) == "number"
        and w == w and h == h            -- NaN check
        and w >= 0 and h >= 0
        and w ~= math.huge and h ~= math.huge then
        return { available = true, width = w, height = h }
    end

    return { available = false, reason = "invalid_result" }
end

local function formatResolution(r)
    if r.available then
        return ("%g x %g"):format(r.width, r.height)
    end
    return "unknown"
end

-- Same, but uses the locale string for the NUI toast
local function formatResolutionLocalized(r)
    if r.available then
        return ("%g x %g"):format(r.width, r.height)
    end
    return L("color_dimensions_unknown")
end

---------------------------------------------------------------------
-- Uploading pixels into a runtime texture
---------------------------------------------------------------------
local function uploadBank(bank, desc)
    if bank.key == desc.key then return end

    local line  = buildGradientLine(desc)
    local pitch = (GetRuntimeTexturePitch and GetRuntimeTexturePitch(bank.texture)) or (TEX_SIZE * 4)
    local rowBytes = TEX_SIZE * 4
    local bulkOk = false

    -- Fast path: one bulk ARGB upload
    if SetRuntimeTextureArgbData
        and pitch >= rowBytes
        and pitch <= rowBytes + 4096
        and pitch % 4 == 0 then

        local padding = string.rep("\0", pitch - rowBytes)
        local rows = {}

        if desc.horizontal then
            -- every row is identical: colour varies along X
            local px = {}
            for x = 1, TEX_SIZE do
                local c = line[x]
                px[x] = string.char(c[3], c[2], c[1], 255) -- BGRA
            end
            rows[1] = string.rep(table.concat(px) .. padding, TEX_SIZE)
        else
            -- colour varies along Y: each row is a single repeated colour
            for y = 1, TEX_SIZE do
                local c = line[y]
                rows[y] = string.rep(string.char(c[3], c[2], c[1], 255), TEX_SIZE) .. padding
            end
        end

        local data = table.concat(rows)
        bulkOk = SetRuntimeTextureArgbData(bank.texture, data, #data) == true
    end

    -- Slow path: per-pixel + commit
    if not bulkOk then
        for y = 0, TEX_SIZE - 1 do
            for x = 0, TEX_SIZE - 1 do
                local c = line[(desc.horizontal and x or y) + 1]
                SetRuntimeTexturePixel(bank.texture, x, y, c[1], c[2], c[3], 255)
            end
        end
        CommitRuntimeTexture(bank.texture)
    end

    bank.key          = desc.key
    bank.uploadMethod = bulkOk and "bulk_argb" or "pixels_commit"
    bank.uploadPitch  = pitch
    bank.linked       = false
    bank.nextLinkAt   = 0
end

---------------------------------------------------------------------
-- Public: set layers
---------------------------------------------------------------------
-- layers  : array of layer definitions
-- slotMap : [layer.id] = slot index (1..MAX_SLOTS)
function M.SetLayers(layers, slotMap)
    if stopped then return end

    local newDesired = {}
    for _, layer in ipairs(layers) do
        local slot = slotMap[layer.id]
        if slot and slot >= 1 and slot <= MAX_SLOTS
            and layer.type == "text" and layer.renderMode == "solid" then
            newDesired[slot] = buildDescriptor(layer)
        end
    end
    desired = newDesired

    for slot, bank in pairs(banks) do
        if desired[slot] then
            uploadBank(bank, desired[slot])
        end
    end
end

---------------------------------------------------------------------
-- Validation + linking (AddReplaceTexture)
---------------------------------------------------------------------
-- Returns true when source and runtime textures are both 64x64 (or unknown)
local function validateBank(bank)
    local src = getTextureResolution(SOURCE_DICT, bank.source, true)
    local run = getTextureResolution(RUNTIME_DICT, bank.target, true)
    bank.sourceDimensions  = src
    bank.runtimeDimensions = run

    local srcBad = src.available and src.width ~= TEX_SIZE
    local runBad = run.available and run.width ~= TEX_SIZE

    if not srcBad and not runBad then
        bank.consoleWarningKey = nil
        bank.toastWarningKey   = nil
        return true
    end

    local warnKey = formatResolution(src) .. "/" .. formatResolution(run)
    local msg = ("3D color material mismatch (%s: source %s, runtime %s; expected 64 x 64). Use oxvw_colorcheck for details.")
        :format(bank.source, formatResolution(src), formatResolution(run))

    if bank.consoleWarningKey ~= warnKey then
        print("[oxlyn-vinewood] " .. msg)
        bank.consoleWarningKey = warnKey
    end

    if VinewoodEditor and VinewoodEditor.Active
        and type(SendNUIMessage) == "function"
        and bank.toastWarningKey ~= warnKey then
        SendNUIMessage({
            action  = "toast",
            kind    = "error",
            message = L("color_material_mismatch", {
                source      = bank.source,
                original    = formatResolutionLocalized(src),
                replacement = formatResolutionLocalized(run),
            }),
        })
        bank.toastWarningKey = warnKey
    end

    return false
end

local function linkBank(bank, now)
    if not validateBank(bank) then
        bank.linked     = false
        bank.nextLinkAt = now + RELINK_INTERVAL
        return false
    end

    AddReplaceTexture(SOURCE_DICT, bank.source, RUNTIME_DICT, bank.target)
    bank.linked                = true
    bank.replacementRegistered = true
    bank.linkAttempts          = (bank.linkAttempts or 0) + 1
    bank.nextLinkAt            = now + RELINK_INTERVAL
    return true
end

---------------------------------------------------------------------
-- Public: Ensure (call every frame/tick while letters are visible)
---------------------------------------------------------------------
-- Returns true when everything is set up (or there is nothing to do)
function M.Ensure()
    if stopped then return false end
    if not next(desired) then return true end

    -- Runtime TXD
    if not runtimeTxd then
        runtimeTxd = CreateRuntimeTxd(RUNTIME_DICT)
        if not runtimeTxd or runtimeTxd == 0 then
            runtimeTxd = nil
            return false
        end
    end

    -- Runtime textures
    for slot, desc in pairs(desired) do
        local bank = banks[slot]
        if not bank then
            local tex = CreateRuntimeTexture(runtimeTxd, "color" .. slot, TEX_SIZE, TEX_SIZE)
            if not tex or tex == 0 then
                return false
            end
            bank = {
                texture = tex,
                source  = ("oxvw_col%02d"):format(slot),
                target  = "color" .. slot,
                linked  = false,
            }
            banks[slot] = bank
        end
        uploadBank(bank, desc)
    end

    -- Source dictionary
    if not sourceRequested then
        RequestStreamedTextureDict(SOURCE_DICT, false)
        sourceRequested = true
        lastRequestTime = GetGameTimer()
    end

    if not HasStreamedTextureDictLoaded(SOURCE_DICT) then
        -- dictionary unloaded: drop replacements so they get re-linked later
        for _, bank in pairs(banks) do
            if bank.replacementRegistered then
                RemoveReplaceTexture(SOURCE_DICT, bank.source)
                bank.replacementRegistered = false
            end
            bank.linked     = false
            bank.nextLinkAt = 0
        end

        local now = GetGameTimer()
        if now - lastRequestTime >= 500 then
            RequestStreamedTextureDict(SOURCE_DICT, false)
            lastRequestTime = now
        end
        return false
    end

    -- Link (or re-link) banks
    local now = GetGameTimer()
    for slot, bank in pairs(banks) do
        if desired[slot] and now >= (bank.nextLinkAt or 0) then
            linkBank(bank, now)
        end
    end

    return true
end

---------------------------------------------------------------------
-- Diagnostics
---------------------------------------------------------------------
function M.Diagnostics()
    local sourceLoaded = false
    if type(HasStreamedTextureDictLoaded) == "function" then
        local ok, res = pcall(HasStreamedTextureDictLoaded, SOURCE_DICT)
        sourceLoaded = ok and res == true
    end

    local info = {
        active           = diagActive,
        stopped          = stopped,
        source           = SOURCE_DICT,
        runtime          = RUNTIME_DICT,
        sourceLoaded     = sourceLoaded,
        sourceRequested  = sourceRequested,
        runtimeCreated   = runtimeTxd ~= nil,
        banks            = {},
    }

    for slot = 1, MAX_SLOTS do
        local desc = desired[slot]
        if desc then
            local bank       = banks[slot]
            local sourceName = ("oxvw_col%02d"):format(slot)
            local first      = desc.stops[1]

            info.banks[#info.banks + 1] = {
                slot                  = slot,
                desiredKey            = desc.key,
                expectedRGB           = { first[1], first[2], first[3] },
                sourceTexture         = sourceName,
                runtimeTexture        = "color" .. slot,
                sourceResolution      = getTextureResolution(SOURCE_DICT, sourceName, true),
                runtimeResolution     = getTextureResolution(RUNTIME_DICT, "color" .. slot, bank ~= nil),
                created               = bank ~= nil,
                replacementAttempted  = bank ~= nil and bank.linked == true,
                rendererSuccessVerified = false,
                linkAttempts          = (bank and bank.linkAttempts) or 0,
                uploadedKey           = (bank and bank.key) or false,
                uploadMethod          = (bank and bank.uploadMethod) or "none",
                uploadPitch           = (bank and bank.uploadPitch) or false,
            }
        end
    end

    return info
end

local function closeDiagnostics()
    diagActive  = false
    diagSession = diagSession + 1
end

---------------------------------------------------------------------
-- On-screen colour check overlay
---------------------------------------------------------------------
local function drawText(text, x, y)
    SetTextFont(0)
    SetTextScale(0.0, 0.25)
    SetTextColour(235, 239, 248, 255)
    SetTextCentre(false)
    SetTextOutline()
    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

local function drawDiagnostics(info)
    DrawRect(0.5, 0.785, 0.47, 0.39, 12, 16, 23, 230)
    drawText("OXLYN COLOR CHECK | /oxvw_colorcheck to close | 60 seconds", 0.28, 0.6)
    drawText("Expected first color", 0.392, 0.632)
    drawText("Runtime texture",      0.505, 0.632)
    drawText("Source texture",       0.618, 0.632)

    if #info.banks == 0 then
        drawText("No active physical color banks. Move near the letters.", 0.3, 0.7)
        return
    end

    for i, b in ipairs(info.banks) do
        local y   = 0.69 + (i - 1) * 0.073
        local rgb = b.expectedRGB

        drawText("Bank " .. b.slot, 0.28, y - 0.019)

        DrawRect(0.432, y, 0.078, 0.041, rgb[1], rgb[2], rgb[3], 255)
        DrawRect(0.545, y, 0.078, 0.041, 30, 34, 43, 255)
        DrawRect(0.658, y, 0.078, 0.041, 30, 34, 43, 255)

        if b.created then
            DrawSprite(RUNTIME_DICT, b.runtimeTexture, 0.545, y, 0.078, 0.041, 0.0, 255, 255, 255, 255)
        end
        if info.sourceLoaded then
            DrawSprite(SOURCE_DICT, b.sourceTexture, 0.658, y, 0.078, 0.041, 0.0, 255, 255, 255, 255)
        end

        drawText(("#%02X%02X%02X"):format(rgb[1], rgb[2], rgb[3]), 0.392, y + 0.02)
        drawText(formatResolution(b.runtimeResolution),            0.505, y + 0.02)
        drawText(formatResolution(b.sourceResolution),             0.618, y + 0.02)
    end
end

local function logDiagnostics(info, tag)
    local encoded = json.encode(info)
    print(("[oxlyn-vinewood:colorcheck] %s %s"):format(tag, encoded))
    return encoded
end

local function openDiagnostics()
    if stopped then return end

    diagActive  = true
    diagSession = diagSession + 1
    local session   = diagSession
    local startTime = GetGameTimer()

    local info        = M.Diagnostics()
    local lastEncoded = logDiagnostics(info, "start")

    CreateThread(function()
        local lastPoll = startTime

        while diagActive
            and diagSession == session
            and not stopped
            and (GetGameTimer() - startTime) < DIAG_DURATION do

            local now = GetGameTimer()
            if now - lastPoll >= 500 then
                info     = M.Diagnostics()
                lastPoll = now

                local encoded = json.encode(info)
                if encoded ~= lastEncoded then
                    lastEncoded = logDiagnostics(info, "change")
                end
            end

            drawDiagnostics(info)
            Wait(0)
        end

        if diagSession == session then
            closeDiagnostics()
        end
    end)
end

---------------------------------------------------------------------
-- /oxvw_colorcheck [rebind]
---------------------------------------------------------------------
if type(RegisterCommand) == "function" then
    RegisterCommand("oxvw_colorcheck", function(_, args)
        if stopped then return end

        local sub = args and args[1]
        if sub and sub ~= "" and sub ~= "rebind" then
            print("[oxlyn-vinewood:colorcheck] Usage: oxvw_colorcheck [rebind]")
            return
        end

        if sub == "rebind" then
            local info    = M.Diagnostics()
            local rebound = 0

            if info.sourceLoaded then
                for slot, bank in pairs(banks) do
                    if desired[slot] and linkBank(bank, GetGameTimer()) then
                        rebound = rebound + 1
                    end
                end
            end

            print(("[oxlyn-vinewood:colorcheck] Explicit rebind of %d existing texture pair(s)."):format(rebound))

            if diagActive then
                logDiagnostics(M.Diagnostics(), "rebind")
            else
                openDiagnostics()
            end
        else
            if diagActive then
                closeDiagnostics()
                print("[oxlyn-vinewood:colorcheck] Closed.")
            else
                openDiagnostics()
            end
        end
    end, false)
end

---------------------------------------------------------------------
-- Cleanup
---------------------------------------------------------------------
if type(AddEventHandler) == "function" then
    AddEventHandler("onResourceStop", function(resourceName)
        if resourceName == GetCurrentResourceName() then
            closeDiagnostics()
        end
    end)
end

function M.Stop()
    if stopped then return end
    stopped = true

    closeDiagnostics()

    for _, bank in pairs(banks) do
        if bank.replacementRegistered then
            RemoveReplaceTexture(SOURCE_DICT, bank.source)
            bank.replacementRegistered = false
        end
    end

    if sourceRequested then
        SetStreamedTextureDictAsNoLongerNeeded(SOURCE_DICT)
    end

    desired = {}
end

