--[[ ═══════════════════════════════════════════════════════════════════════
    APEX LOADING: AI proxy (server). Escrow-ignored so owners can point it
    at any provider. The API key NEVER reaches a client: the creator sends
    prompts here, this file calls the provider, the text goes back down.

    Key resolution order:  convar `apex_loading_ai_key`  →  Config.AI.apiKey
═══════════════════════════════════════════════════════════════════════ ]]

-- ⚠ A Gemini key only reaches the models ITS project was granted, and the
-- ones a key can LIST are not always the ones it can CALL. `gemini-flash-latest`
-- is the alias that tracks whatever the current flash model is, so it keeps
-- working when Google retires a version number. If you ever get a 404 from
-- Gemini, run `apexloading_ai` in the server console: it prints the models
-- this key can actually use.
local DEFAULT_MODELS = {
    groq = 'llama-3.3-70b-versatile',
    gemini = 'gemini-flash-latest',
    openai = 'gpt-4o-mini',
    anthropic = 'claude-haiku-4-5-20251001',
}

local function aiKey()
    local k = GetConvar('apex_loading_ai_key', '')
    if k == '' then k = (Config.AI and Config.AI.apiKey) or '' end
    return k
end

function AiConfigured()
    return aiKey() ~= ''
end

local function aiModel()
    local m = (Config.AI and Config.AI.model) or ''
    if m ~= '' then return m end
    return DEFAULT_MODELS[(Config.AI and Config.AI.provider) or 'groq'] or DEFAULT_MODELS.groq
end

-- per-admin rate limiting
local buckets = {}
local function rateOk(src)
    local now = os.time()
    local b = buckets[src]
    if not b or now - b.start >= 60 then
        buckets[src] = { start = now, n = 1 }
        return true
    end
    b.n = b.n + 1
    return b.n <= ((Config.AI and Config.AI.maxPerMinute) or 6)
end
AddEventHandler('playerDropped', function() buckets[source] = nil end)

-- provider adapters: (system, user, key, model, cb(ok, textOrErr))
local function callOpenAICompat(url, system, user, key, model, cb, extraHeaders)
    local headers = { ['Content-Type'] = 'application/json', ['Authorization'] = 'Bearer ' .. key }
    for k, v in pairs(extraHeaders or {}) do headers[k] = v end
    PerformHttpRequest(url, function(status, body)
        if status ~= 200 then
            cb(false, 'provider replied ' .. tostring(status))
            return
        end
        local ok, data = pcall(json.decode, body)
        local text = ok and data and data.choices and data.choices[1]
            and data.choices[1].message and data.choices[1].message.content
        if text then cb(true, text) else cb(false, 'empty provider response') end
    end, 'POST', json.encode({
        model = model,
        messages = {
            { role = 'system', content = system },
            { role = 'user', content = user },
        },
        max_tokens = 2048,
    }), headers)
end

local function callGemini(system, user, key, model, cb)
    -- the key goes in the header, not the query string: it keeps the secret
    -- out of URL logs and works with every Google key format
    local url = ('https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent')
        :format(model)
    PerformHttpRequest(url, function(status, body)
        if status ~= 200 then
            local hint = ''
            if status == 404 then
                hint = (': the model "%s" is not available to this key. Run apexloading_ai in the server console to list the ones that are.'):format(model)
            elseif status == 400 or status == 401 or status == 403 then
                hint = ': the API key was rejected. Check Config.AI.apiKey or the apex_loading_ai_key convar.'
            end
            print(('^1[apex_loading] Gemini %s%s^0'):format(tostring(status), hint))
            if Config.Debug and body then print('[apex_loading] ' .. tostring(body):sub(1, 400)) end
            cb(false, ('provider replied %s%s'):format(tostring(status), hint))
            return
        end
        local ok, data = pcall(json.decode, body)
        local text = ok and data and data.candidates and data.candidates[1]
            and data.candidates[1].content and data.candidates[1].content.parts
            and data.candidates[1].content.parts[1] and data.candidates[1].content.parts[1].text
        if text then cb(true, text) else cb(false, 'empty provider response') end
    end, 'POST', json.encode({
        systemInstruction = { parts = { { text = system } } },
        contents = { { role = 'user', parts = { { text = user } } } },
        -- ask Gemini for JSON directly: the creator only ever wants an object,
        -- and this stops the model wrapping it in prose or code fences
        generationConfig = { maxOutputTokens = 4096, responseMimeType = 'application/json' },
    }), {
        ['Content-Type'] = 'application/json',
        ['x-goog-api-key'] = key,
    })
end

local function callAnthropic(system, user, key, model, cb)
    PerformHttpRequest('https://api.anthropic.com/v1/messages', function(status, body)
        if status ~= 200 then cb(false, 'provider replied ' .. tostring(status)) return end
        local ok, data = pcall(json.decode, body)
        local text = ok and data and data.content and data.content[1] and data.content[1].text
        if text then cb(true, text) else cb(false, 'empty provider response') end
    end, 'POST', json.encode({
        model = model,
        system = system,
        max_tokens = 2048,
        messages = { { role = 'user', content = user } },
    }), {
        ['Content-Type'] = 'application/json',
        ['x-api-key'] = key,
        ['anthropic-version'] = '2023-06-01',
    })
end

local function callProvider(system, user, cb)
    local key = aiKey()
    if key == '' then cb(false, 'no API key configured') return end
    local provider = (Config.AI and Config.AI.provider) or 'groq'
    local model = aiModel()
    if provider == 'groq' then
        callOpenAICompat('https://api.groq.com/openai/v1/chat/completions', system, user, key, model, cb)
    elseif provider == 'openai' then
        callOpenAICompat('https://api.openai.com/v1/chat/completions', system, user, key, model, cb)
    elseif provider == 'gemini' then
        callGemini(system, user, key, model, cb)
    elseif provider == 'anthropic' then
        callAnthropic(system, user, key, model, cb)
    elseif provider == 'custom' and Config.AI.customUrl and Config.AI.customUrl ~= '' then
        callOpenAICompat(Config.AI.customUrl, system, user, key, model, cb)
    else
        cb(false, 'unknown provider')
    end
end

-- Server console only: says what the AI is configured with and, for Gemini,
-- asks Google which models the key can actually call. Turns "the AI does not
-- work" into a five-second answer.
RegisterCommand('apexloading_ai', function(src)
    if src ~= 0 then return end
    local provider = (Config.AI and Config.AI.provider) or 'groq'
    local key = aiKey()
    print(('^5[apex_loading] provider=%s  model=%s  key=%s^0'):format(
        provider, aiModel(), key ~= '' and ('set (' .. #key .. ' chars)') or '^1MISSING^0'))
    if key == '' then
        print('^3[apex_loading] set the key in Config.AI.apiKey or: set apex_loading_ai_key "..."^0')
        return
    end
    if provider ~= 'gemini' then
        print('[apex_loading] model listing is only implemented for gemini.')
        return
    end
    PerformHttpRequest('https://generativelanguage.googleapis.com/v1beta/models', function(status, body)
        if status ~= 200 then
            print(('^1[apex_loading] listing models failed: %s^0'):format(tostring(status)))
            if body then print(tostring(body):sub(1, 300)) end
            return
        end
        local ok, data = pcall(json.decode, body)
        if not ok or not data or not data.models then print('^1[apex_loading] unreadable model list^0') return end
        print('^2[apex_loading] models this key can use for generateContent:^0')
        for _, m in ipairs(data.models) do
            local can = false
            for _, meth in ipairs(m.supportedGenerationMethods or {}) do
                if meth == 'generateContent' then can = true break end
            end
            if can then print('   ' .. tostring(m.name):gsub('^models/', '')) end
        end
        print('[apex_loading] put one of these in Config.AI.model (empty = ' .. aiModel() .. ').')
    end, 'GET', '', { ['x-goog-api-key'] = key })
end, true)

RegisterNetEvent('apex_loading:server:AiAsk', function(id, system, user)
    local src = source
    if type(id) ~= 'string' or type(system) ~= 'string' or type(user) ~= 'string' then return end
    if #id > 64 then return end
    local function refuse(why)
        TriggerClientEvent('apex_loading:client:AiReply', src, { id = id, ok = false, error = why })
    end
    -- the creator leaves uploaded images out of what it sends, so the design
    -- is a few KB; anything this big would not have reached us anyway
    if #system > 8000 or #user > 200000 then
        refuse('the request was too large to send to the AI')
        return
    end
    if not (Config.AI and Config.AI.enabled ~= false) then
        refuse('the AI assistant is disabled in the config')
        return
    end
    if not Access.Check(src, 'creator') then
        refuse('you do not have access to the creator')
        return
    end
    if not rateOk(src) then
        TriggerClientEvent('apex_loading:client:AiReply', src, { id = id, ok = false, error = 'rate limit: wait a moment' })
        return
    end
    callProvider(system, user, function(ok, textOrErr)
        TriggerClientEvent('apex_loading:client:AiReply', src, {
            id = id,
            ok = ok,
            text = ok and textOrErr or nil,
            error = ok and nil or textOrErr,
        })
    end)
end)
