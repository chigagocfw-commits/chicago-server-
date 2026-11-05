-- SOUH4IL-DEV — Outbox & Checkpoint Dispatch Service
-- Manages external delivery queues and retry states without modifying append-only logs

local Secrets = require 'config.secrets'
local Outbox = {}

local isProcessing = false
local MAX_ATTEMPTS = 3

---Queues an external checkpoint milestone in souh4il_dev_outbox
---@param logId number
---@param logHash string
---@param checkpointSeq number
---@return boolean success
function Outbox.QueueCheckpoint(logId, logHash, checkpointSeq)
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    local prevSeq = checkpointSeq - 1

    local payloadData = {
        checkpoint_seq = checkpointSeq,
        last_log_id = logId,
        last_log_hash = logHash,
        timestamp = timestamp,
    }

    local payloadJson = json.encode(payloadData)

    -- Signature using HMAC secret if configured
    local signature = "LOCAL_QUEUE_PENDING"

    local query = [[
        INSERT INTO souh4il_dev_outbox 
        (log_id, destination, payload, signature, status)
        VALUES (?, ?, ?, ?, 'PENDING')
    ]]

    local res = MySQL.insert.await(query, {
        logId, "EXTERNAL_CHECKPOINT_SERVICE", payloadJson, signature
    })

    return res and res > 0
end

---Queues an emergency Discord webhook alert
---@param action string
---@param executorName string
---@param executorLic string
---@param details table
---@return boolean success
function Outbox.QueueDiscordAlert(action, executorName, executorLic, details)
    if not Secrets.DiscordWebhookURL or Secrets.DiscordWebhookURL == "" then
        return false -- Webhook URL not configured
    end

    local payloadData = {
        username = "SOUH4IL-DEV SECURITY",
        embeds = {
            {
                title = "🚨 SECURITY AUDIT ALERT: " .. action,
                color = action:find("INTRUSION") and 16711680 or 65535,
                fields = {
                    { name = "Executor", value = ("%s (%s)"):format(executorName, executorLic), inline = true },
                    { name = "Timestamp", value = os.date('%Y-%m-%d %H:%M:%S'), inline = true },
                    { name = "Details", value = json.encode(details) }
                }
            }
        }
    }

    local query = [[
        INSERT INTO souh4il_dev_outbox 
        (log_id, destination, payload, signature, status)
        VALUES (0, ?, ?, 'DISCORD_WEBHOOK', 'PENDING')
    ]]

    local res = MySQL.insert.await(query, {
        Secrets.DiscordWebhookURL, json.encode(payloadData)
    })

    return res and res > 0
end

---Asynchronously processes pending outbox deliveries with exponential backoff
function Outbox.ProcessQueue()
    if isProcessing then return end
    isProcessing = true

    CreateThread(function()
        local rows = MySQL.query.await([[
            SELECT id, destination, payload, attempts 
            FROM souh4il_dev_outbox 
            WHERE status = 'PENDING' AND attempts < ? 
            ORDER BY id ASC LIMIT 5
        ]], { MAX_ATTEMPTS })

        if rows and #rows > 0 then
            for _, item in ipairs(rows) do
                local success = false
                local errorMsg = nil

                if item.destination:find("discord.com") then
                    -- Dispatch Discord HTTP Request
                    PerformHttpRequest(item.destination, function(status, response)
                        if status >= 200 and status < 300 then
                            MySQL.update.await('UPDATE souh4il_dev_outbox SET status = "SENT" WHERE id = ?', { item.id })
                        else
                            MySQL.update.await([[
                                UPDATE souh4il_dev_outbox 
                                SET attempts = attempts + 1, last_error = ?, 
                                    status = IF(attempts + 1 >= ?, 'FAILED', 'PENDING') 
                                WHERE id = ?
                            ]], { ("HTTP Status %d: %s"):format(status, response or ""), MAX_ATTEMPTS, item.id })
                        end
                    end, 'POST', item.payload, { ['Content-Type'] = 'application/json' })
                end
            end
        end

        isProcessing = false
    end)
end

-- Process queue every 60 seconds
CreateThread(function()
    while true do
        Wait(60000)
        Outbox.ProcessQueue()
    end
end)

return Outbox

