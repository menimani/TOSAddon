local addonName = 'INPUTPASS'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    g:RegisterMsg('FPS_UPDATE', g.AutoInputUpdate)
end)

function g.AutoInputUpdate()
    local frame = (function ()
        if _G.ui.GetFrame('warningmsgbox'):IsVisible() == 1 then
            return _G.ui.GetFrame('warningmsgbox')
        end

        if _G.ui.GetFrame('warningmsgbox_ex'):IsVisible() == 1 then
            return _G.ui.GetFrame('warningmsgbox_ex')
        end
    end)()

    if frame == nil then
        return
    end

    local input_frame = _G.GET_CHILD_RECURSIVELY(frame, 'input')
    if input_frame == nil then
        return
    end

    local text = (function ()
        local comparetext = _G.GET_CHILD_RECURSIVELY(frame, 'comparetext')
        if comparetext ~= nil then
            return comparetext:GetText()
        end

        local warningtext = _G.GET_CHILD_RECURSIVELY(frame, 'warningtext')
        if warningtext ~= nil then
            return warningtext:GetText()
        end
    end)()

    local input_text = string.match(text, '.+%[(%S+)%]')
    if input_text == nil then
        return
    end
    input_frame:SetText(input_text)
end
