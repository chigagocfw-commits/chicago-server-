



-- ─────────────────────────────────────────────────
-- Main server object
-- ─────────────────────────────────────────────────
Main = {
    animationList    = {},   -- flat list built in Init()
    Groups           = {},   -- active animation groups
    PendingRequests  = {},   -- shared-emote requests awaiting acceptance
    RequestTimeout   = 10000, -- ms before a pending request expires
    SyncCooldowns    = {},   -- per-player timestamp for sync rate-limiting
    SyncCooldownTime = 1000, -- minimum ms between syncs for the same player
}

-- ─────────────────────────────────────────────────
-- Main:cleanupPendingRequests()
-- Removes any pending requests that have exceeded
-- the RequestTimeout window.
-- ─────────────────────────────────────────────────
function Main:cleanupPendingRequests()
    local now = GetGameTimer()
    for key, request in pairs(self.PendingRequests) do
        if (now - request.timestamp) > self.RequestTimeout then
            self.PendingRequests[key] = nil
        end
    end
end

-- ─────────────────────────────────────────────────
-- Main:addPendingRequest(requester, target, animation)
-- Stores a pending shared-emote request keyed by
-- "requester_target". Cleans up expired entries
-- first.
-- ─────────────────────────────────────────────────
function Main:addPendingRequest(requester, target, animation)
    self:cleanupPendingRequests()
    local key = tostring(requester) .. "_" .. tostring(target)
    self.PendingRequests[key] = {
        requester = requester,
        target    = target,
        animation = animation,
        timestamp = GetGameTimer(),
    }
end

-- ─────────────────────────────────────────────────
-- Main:validateAndConsumeRequest(requester, target)
-- Returns true and removes the matching request if
-- one exists; returns false otherwise.
-- ─────────────────────────────────────────────────
function Main:validateAndConsumeRequest(requester, target)
    self:cleanupPendingRequests()
    local key = tostring(requester) .. "_" .. tostring(target)
    if self.PendingRequests[key] then
        self.PendingRequests[key] = nil
        return true
    end
    return false
end

-- ─────────────────────────────────────────────────
-- Main:canSkipRequest(animName)
-- Returns true if the animation is flagged with
-- SkipRequest / skip / Skip in any of:
--   Config.Convert.Shared[animName]
--   Config.Convert.ERP[animName]
--   self.getAnimation(animName)
-- ─────────────────────────────────────────────────
function Main:canSkipRequest(animName)
    if not animName then return false end

    -- Helper: check an AnimationOptions table for any skip flag
    local function hasSkipFlag(opts)
        return opts and (opts.SkipRequest or opts.skip or opts.Skip)
    end

    -- Check Config.Convert.Shared
    if Config.Convert and Config.Convert.Shared then
        local sharedAnim = Config.Convert.Shared[animName]
        if sharedAnim and hasSkipFlag(sharedAnim.AnimationOptions) then
            return true
        end
    end

    -- Check Config.Convert.ERP
    if Config.Convert and Config.Convert.ERP then
        local erpAnim = Config.Convert.ERP[animName]
        if erpAnim and hasSkipFlag(erpAnim.AnimationOptions) then
            return true
        end
    end

    -- Check the resolved animation entry (normalised options)
    local anim = self:getAnimation(animName)
    if anim then
        if hasSkipFlag(anim.animationOptions) then return true end
        if hasSkipFlag(anim.AnimationOptions) then return true end
    end

    return false
end

-- ─────────────────────────────────────────────────
-- Main:checkSyncCooldown(playerId)
-- Returns true and records the timestamp if the
-- player is not on cooldown; returns false if they
-- are still within SyncCooldownTime.
-- ─────────────────────────────────────────────────
function Main:checkSyncCooldown(playerId)
    local now      = GetGameTimer()
    local lastSync = self.SyncCooldowns[playerId]
    if lastSync and (now - lastSync) < self.SyncCooldownTime then
        return false
    end
    self.SyncCooldowns[playerId] = now
    return true
end

-- ─────────────────────────────────────────────────
-- Main:isValidPlayer(playerId)
-- Returns true if the player has a ped that exists
-- in the world.
-- ─────────────────────────────────────────────────
function Main:isValidPlayer(playerId)
    if not playerId then return false end
    local ped = GetPlayerPed(playerId)
    if not ped then return false end
    return DoesEntityExist(ped)
end

-- ─────────────────────────────────────────────────
-- Main:Init()
-- Builds self.animationList by walking every
-- enabled Config.Category that has a get() method,
-- creating a flat array of { name, category, label,
-- type, style? } entries.
-- ─────────────────────────────────────────────────
function Main:Init()
    local list     = {}
    local skipCats = { all = true, favorites = true }

    for _, cat in pairs(Config.Categories) do
        if not skipCats[cat.name] and cat.get then
            local catList, isDictionary = cat.get()

            if isDictionary then
                -- Sorted dictionary (e.g. Dances, Emotes)
                for key, anim in self:sortTable(catList) do
                    table.insert(list, {
                        name     = anim.name or key,
                        category = cat.name,
                        label    = anim.label or anim[3],
                        type     = cat.type,
                    })
                end
            else
                -- Array (e.g. WeaponStyles, Sequences)
                for _, anim in ipairs(catList) do
                    table.insert(list, {
                        name     = anim.name or anim[1],
                        category = cat.name,
                        label    = anim.label or anim[3],
                        type     = cat.type,
                        style    = anim.style or false,
                    })
                end
            end
        end
    end

    Main.animationList = list
end

-- ─────────────────────────────────────────────────
-- Main:getAnimation(animName)
-- Searches animationList for an entry matching
-- animName, then fetches the full data from the
-- appropriate Config category.
-- Returns the animation table or nil.
-- ─────────────────────────────────────────────────
function Main:getAnimation(animName)
    for _, entry in ipairs(self.animationList) do
        if entry.name == animName then
            -- Find the matching category
            for _, cat in pairs(Config.Categories) do
                if cat.name == entry.category then
                    local catList, isDictionary = cat.get()
                    if isDictionary then
                        return catList[animName]
                    else
                        for i, anim in ipairs(catList) do
                            if anim.name == animName then
                                anim.type = anim.type or cat.type or "animation"
                                return anim
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ─────────────────────────────────────────────────
-- Main:sortTable(tbl, compareFn)
-- Returns a stateful iterator that yields
-- key, value pairs of `tbl` in sorted key order.
-- ─────────────────────────────────────────────────
function Main:sortTable(tbl, compareFn)
    local keys = {}
    for k in pairs(tbl) do table.insert(keys, k) end
    table.sort(keys, compareFn)

    local i = 0
    return function()
        i = i + 1
        if keys[i] == nil then return nil end
        return keys[i], tbl[keys[i]]
    end
end

-- ─────────────────────────────────────────────────
-- Main:getGroup(leaderId)
-- Returns the group table for leaderId.
-- If no group exists yet, creates one with the
-- leader as the sole member.
-- Returns: groupTable, alreadyInGroupId
-- ─────────────────────────────────────────────────
function Main:getGroup(leaderId)
    local group = self.Groups[leaderId]

    if not group then
        -- Create a fresh group with the leader as member [1]
        local newGroup = {
            { id = leaderId, name = Framework:getPlayerName(leaderId) },
        }
        -- Return the new group and any existing membership info
        local existingGroupId = self:isPlayerInGroup(leaderId)
        return newGroup, existingGroupId
    end

    -- Group already exists
    local existingGroupId = self:isPlayerInGroup(leaderId)
    return group, existingGroupId
end

-- ─────────────────────────────────────────────────
-- Main:isPlayerInGroup(playerId)
-- Scans all groups for playerId (by numeric and
-- string comparison). Returns the group leader ID
-- if found, or 0 if the player is in no group.
-- ─────────────────────────────────────────────────
function Main:isPlayerInGroup(playerId)
    for leaderId, members in pairs(self.Groups) do
        for _, member in pairs(members) do
            if tostring(member.id) == tostring(playerId) then
                return leaderId
            end
        end
    end
    return 0
end

-- ─────────────────────────────────────────────────
-- Main:setPlayerGroup(leaderId, playerId)
-- Adds playerId to leaderId's group, creating the
-- group if it doesn't exist yet.
-- Returns true on success.
-- ─────────────────────────────────────────────────
function Main:setPlayerGroup(leaderId, playerId)
    -- Create the group if it doesn't exist
    if not self.Groups[leaderId] then
        self.Groups[leaderId] = {
            { id = leaderId, name = Framework:getPlayerName(leaderId) },
        }
    end

    -- Append the new member
    table.insert(self.Groups[leaderId], {
        id   = playerId,
        name = Framework:getPlayerName(playerId),
    })

    return true
end

-- ─────────────────────────────────────────────────
-- Main:leaveGroup(playerId)
-- Removes playerId from whatever group they are
-- in. If only the leader remains, disbands the
-- group. Notifies all remaining group members.
-- ─────────────────────────────────────────────────
function Main:leaveGroup(playerId)
    for leaderId, members in pairs(self.Groups) do
        for index, member in pairs(members) do
            if tostring(member.id) == tostring(playerId) then
                -- Remove this member
                table.remove(self.Groups[leaderId], index)

                -- Disband the group if only the leader is left
                if #self.Groups[leaderId] == 1 then
                    self.Groups[leaderId] = nil
                end

                -- Notify remaining members
                local leavingName = Framework:getPlayerName(playerId)
                TriggerClientEvent(
                    eventName .. "client:notify",
                    leaderId,
                    Translate("PLAYER_LEFT_GROUP", { leavingName })
                )
                return
            end
        end
    end
end

-- ─────────────────────────────────────────────────
-- Main:getClosestPlayers(playerId, excludeList)
-- Returns up to 10 players within 5 units of
-- playerId, excluding players in excludeList.
-- Each entry: { id, name }
-- ─────────────────────────────────────────────────
function Main:getClosestPlayers(playerId, excludeList)
    playerId = tonumber(playerId)

    local sourcePed = GetPlayerPed(playerId)
    if not sourcePed or sourcePed == 0 then return {} end

    local sourceCoords = GetEntityCoords(sourcePed)
    local nearby       = {}
    local maxCount     = 10
    local radius       = 5.0
    local radiusSq     = radius * radius

    -- Build a lookup of players to exclude (self + current group)
    local excluded = { [playerId] = true }
    if excludeList then
        for _, entry in ipairs(excludeList) do
            excluded[tonumber(entry.id)] = true
        end
    end

    local allPlayers = GetPlayers()
    if not allPlayers or #allPlayers == 0 then return {} end

    for _, otherIdStr in ipairs(allPlayers) do
        local otherId = tonumber(otherIdStr)
        if not excluded[otherId] then
            local otherPed = GetPlayerPed(otherIdStr)
            if otherPed and otherPed ~= 0 then
                local otherCoords = GetEntityCoords(otherPed)
                local distSq      = #(sourceCoords - otherCoords)
                -- #vector3 returns the magnitude, so compare magnitude^2 against radiusSq
                if (distSq * distSq) < radiusSq then
                    table.insert(nearby, {
                        id   = otherIdStr,
                        name = Framework:getPlayerName(otherIdStr),
                    })
                    if #nearby >= maxCount then break end
                end
            end
        end
    end

    return nearby
end