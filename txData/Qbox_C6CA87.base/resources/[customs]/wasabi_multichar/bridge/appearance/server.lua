-----------------For support, scripts, and more----------------
--------------- https://discord.gg/wasabiscripts  -------------
---------------------------------------------------------------
---@diagnostic disable: undefined-global

local Appearance = {}

---Get ped preview skin and model for a character.
---Checks rcore_clothing first, then falls back to framework-specific DB queries.
---@param characterId string Character identifier (citizenid for QB/QBX, full identifier for ESX)
---@return table|nil skin
---@return string model
function Appearance.getPedPreview(characterId)
    if not characterId then
        return nil, 'mp_m_freemode_01'
    end

    -- rcore_clothing: framework-agnostic, check first
    if GetResourceState('rcore_clothing') == 'started' then
        local skin = exports['rcore_clothing']:getSkinByIdentifier(characterId)
        if skin then
            return skin, skin.ped_model or 'mp_m_freemode_01'
        end
    end

    local bridge    = Modules.require('bridge')
    local framework = bridge and bridge.framework or 'custom'

    -- QB / QBX: playerskins table (citizenid)
    if framework == 'qb' or framework == 'qbx' then
        local result = MySQL.query.await([[
            SELECT model, skin FROM playerskins WHERE citizenid = ? AND active = 1 LIMIT 1
        ]], { characterId })

        if result and result[1] then
            local model = result[1].model or 'mp_m_freemode_01'
            local skin  = result[1].skin
            if type(skin) == 'string' then skin = json.decode(skin) end
            return skin, model
        end

        return nil, 'mp_m_freemode_01'
    end

    -- ESX: users table (identifier), skin in users.skin column
    if framework == 'esx' then
        local result = MySQL.single.await('SELECT skin, sex FROM users WHERE identifier = ? LIMIT 1', { characterId })

        if result then
            local skin  = (result.skin and json.decode(result.skin)) or nil
            local model = (skin and skin.model) or
                          ((result.sex == 'f' or result.sex == 'female') and 'mp_f_freemode_01' or 'mp_m_freemode_01')
            return skin, model
        end

        return nil, 'mp_m_freemode_01'
    end

    -- Custom / unknown framework: return default
    return nil, 'mp_m_freemode_01'
end

Modules.register('Appearance', Appearance)
