



Interaction = Interaction or {}

if IsDuplicityVersion() then return end

CreateThread(function()
    if Config.Interaction ~= "ox_lib" then return end

    ---@class InteractionOptions
    ---@field position? '"right-center"' | '"left-center"' | '"top-center"' | '"bottom-center"'
    ---@field icon? string | table
    ---@field iconColor? string
    ---@field iconAnimation? '"spin"' | '"spinPulse"' | '"spinReverse"' | '"pulse"' | '"beat"' | '"fade"' | '"beatFade"' | '"bounce"' | '"shake"'
    ---@field style? table
    ---@field alignIcon? '"top"' | '"center"'

    function Interaction.ShowTextUI(text, options)
        lib.showTextUI(text, options)
    end

    function Interaction.HideTextUI()
        lib.hideTextUI()
    end

    function Interaction.IsOpen()
        return lib.isTextUIOpen()
    end

    function Interaction.ShowQuestion(text)
        lib.showTextUI('[E] ' .. Translate('ACCEPT') .. ' | [G] ' .. Translate('DENY') .. '\n' .. text, {
            position = 'top-center',
            icon = 'question'
        })
    end

    function Interaction.HideQuestion()
        lib.hideTextUI()
    end

    function Interaction.ShowInfo(text)
        lib.showTextUI('[G] ' .. text, {
            position = 'right-center',
        })
    end

    function Interaction.HideInfo()
        lib.hideTextUI()
    end

    function Interaction.ShowHelp(toggle)
        if toggle then
            lib.showTextUI(Translate('PLACE_HELP_TEXT') or 'Use controls to adjust position', {
                position = 'left-center',
                icon = 'circle-info'
            })
        else
            lib.hideTextUI()
        end
    end

    function Interaction.HideHelp()
        lib.hideTextUI()
    end

    function Interaction.ShowEditAnim(toggle)
        if toggle then
            local controlsText = string.format(
                '[W/A/S/D] %s\n[Q/Z] %s\n[Scroll] %s\n[PgUp/PgDn] %s\n[E] %s | [ESC] %s',
                Translate('EDIT_MOVE') or 'Move',
                Translate('EDIT_HEIGHT') or 'Height',
                Translate('EDIT_ROTATE') or 'Rotate',
                Translate('EDIT_PITCH') or 'Pitch',
                Translate('EDIT_CONFIRM') or 'Confirm',
                Translate('EDIT_CANCEL') or 'Cancel'
            )
            lib.showTextUI(controlsText, {
                position = 'left-center',
                icon = 'arrows-up-down-left-right'
            })
        else
            lib.hideTextUI()
        end
    end

    function Interaction.HideEditAnim()
        lib.hideTextUI()
    end
end)
