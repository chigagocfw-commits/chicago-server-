CreateThread(function()
    while true do
        Wait(0)
        local isSessionActive = NetworkIsSessionActive()
        local isPlayerActive = NetworkIsPlayerActive(PlayerId())
        local isSessionStarted = NetworkIsSessionStarted()

        if isSessionActive or isPlayerActive or isSessionStarted then
            DisplayRadar(false)
            DoScreenFadeOut(1000)
            TriggerEvent("wasabi_multichar:openUI")
            break
        end
    end
end)

Modules.resolveEntry("session")
