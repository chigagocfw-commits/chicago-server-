-- SOUH4IL-DEV Secrets & API Configuration
-- IMPORTANT: Restrict file permissions using Windows NTFS ACLs (icacls)
-- icacls "config/secrets.lua" /inheritance:r /grant:r "SYSTEM:(F)" "Administrators:(F)"

local Secrets = {}

-- External HMAC Secret used to sign periodic audit checkpoints
-- Can be overridden via system environment variable SOUH4IL_HMAC_SECRET
Secrets.HMACSecret = GetConvar('souh4il_hmac_secret', 'CHANGEME_GENERATE_SECURE_64_BYTE_HEX_KEY')

-- External Checkpoint Verification Microservice Endpoint
-- If not configured or empty, outbox will queue locally until endpoint is active
Secrets.ExternalCheckpointEndpoint = GetConvar('souh4il_checkpoint_endpoint', '')

-- Discord Webhook URL for emergency audit mirroring
-- Kept empty by default until explicitly provided by server owner
Secrets.DiscordWebhookURL = GetConvar('souh4il_discord_webhook', '')

return Secrets

