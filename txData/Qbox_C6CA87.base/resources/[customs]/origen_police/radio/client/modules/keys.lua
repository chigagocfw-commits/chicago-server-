-- Register main radio talk keybind
RegisterKeyMapping(
    "+radiotalk_police_org",
    Config.Commands.TalkRadio.description,
    "keyboard",
    Config.Commands.TalkRadio.key
)

-- Start talking when key pressed
RegisterCommand("+radiotalk_police_org", function()
    StartTalkRadio()
end)

-- Stop talking when key released
RegisterCommand("-radiotalk_police_org", function()
    StopTalkRadio()
end)

-- Custom keybind handler (press)
RegisterCommand("+r_police_keybind", function(source, args)
    local bindKey = args[1]
    
    if bindKey and Radio.Binds[bindKey] then
        local bindAction = Radio.Binds[bindKey]
        
        -- Check if it's a frequency bind
        if Config.BindFreqs[bindAction] then
            local lastFreq = ""
            
            -- Get the last frequency in the bind
            for freq, _ in pairs(Config.BindFreqs[bindAction]) do
                lastFreq = freq
            end
            
            StartTalkRadio(Config.BindFreqs[bindAction][lastFreq])
        else
            -- Execute action (like mute)
            DoAction(bindAction)
        end
    end
end)

-- Custom keybind handler (release)
RegisterCommand("-r_police_keybind", function(source, args)
    local bindKey = args[1]
    
    if bindKey and Radio.Binds[bindKey] then
        local bindAction = Radio.Binds[bindKey]
        
        -- Only stop talking if it's a frequency bind
        if Config.BindFreqs[bindAction] then
            StopTalkRadio()
        end
    end
end)