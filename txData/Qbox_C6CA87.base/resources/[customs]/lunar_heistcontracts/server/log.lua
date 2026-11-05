function LogNormal(source, message)
    if SvConfig.webhook and SvConfig.webhook ~= "WEBHOOK_HERE" then
        Utils.logToDiscord(source, SvConfig.webhook, message)
    end
end

function LogItem(source, message)
    if SvConfig.itemWebhook and SvConfig.itemWebhook ~= "WEBHOOK_HERE" then
        Utils.logToDiscord(source, SvConfig.itemWebhook, message)
    end
end