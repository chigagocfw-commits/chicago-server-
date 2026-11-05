-- APEX LOADING: the YouTube referrer bridge, server side.
--
-- A loading screen is served from nui://, which sends no Referer header, and
-- YouTube refuses referrer-less embeds ("Error 153"). The fix is a tiny
-- bridge page (web/yt.html) that runs the official player from a real
-- http(s) origin; the loading screen embeds it as an <iframe>. Two origins
-- can serve that page:
--
--   1. https://cfx-nui-<resource>/web/yt.html: the resource's own NUI host.
--      Needs nothing from this file (the page ships in files{}); this is the
--      origin the loading screen tries first.
--   2. https://<web_baseUrl>/<resource>/yt.html: the server's public cfx.re
--      reverse-proxy URL, served by the HTTP handler below. web_baseUrl is
--      set by FXServer itself once the server is listed; this is the backup
--      for any build where the loadscreen cannot reach the cfx-nui host.
--
-- A custom domain or reverse proxy can override the backup completely:
--     set apex_loading_yt_bridge "https://your.domain/apex_loading/yt.html"

local RESOURCE = GetCurrentResourceName()

function YtBridgeUrl()
    local override = GetConvar('apex_loading_yt_bridge', '')
    if override ~= '' then return override end
    local base = GetConvar('web_baseUrl', '')
    if base == '' then return nil end
    if not base:find('^https?://') then base = 'https://' .. base end
    return ('%s/%s/yt.html'):format(base, RESOURCE)
end

SetHttpHandler(function(req, res)
    local path = (req.path or ''):gsub('%?.*$', '')
    if req.method == 'GET' and (path == '/yt.html' or path == '/yt') then
        local body = LoadResourceFile(RESOURCE, 'web/yt.html')
        if body then
            res.writeHead(200, {
                ['Content-Type'] = 'text/html; charset=utf-8',
                ['Cache-Control'] = 'no-store',
            })
            res.send(body)
            return
        end
    end
    res.writeHead(404, { ['Content-Type'] = 'text/plain' })
    res.send('not found')
end)
