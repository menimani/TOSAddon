local addonName = 'HAMSTER'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    g:slashCommand('/hamster', g.Command)

    g:setupHook('INDUNENTER_AUTOMATCH', function(frame)
        g.settings.lastIndunType = frame:GetTopParentFrame():GetUserValue('INDUN_TYPE')
        g:SaveSettings()
        return g.oldFunc['INDUNENTER_AUTOMATCH'](frame)
    end)

    g:LoadSettings()
end)

function g.Command(command)
    local indunType = g.settings.lastIndunType
    if #command > 0 then
        indunType = table.remove(command, 1)
    end

    if _G.GetClassByType('Indun', indunType) == nil then
        _G.CHAT_SYSTEM('Invalid command')
        return
    end
    g.OpenIndun(indunType)
end

function g.OpenIndun(indunType)
    if _G.session.world.IsIntegrateServer() == true or _G.IsPVPField(_G.pc) == 1 or _G.IsPVPServer(_G.pc) == 1 then
        _G.ui.SysMsg(_G.ScpArgMsg('ThisLocalUseNot'))
        return
    end

    local frame = _G.ui.GetFrame('induninfo')
    local indunCls = _G.GetClassByType('Indun', indunType)
    local btnInfoCls = _G.INDUNINFO_SET_BUTTONS_FIND_CLASS(indunCls, true)
    local redButtonScp = _G.TryGetProp(btnInfoCls, 'RedButtonScp')

    if _G[redButtonScp] == nil then
        return
    end

    local buttonBox = _G.GET_CHILD_RECURSIVELY(frame, 'buttonBox')
    local redButton = _G.GET_CHILD_RECURSIVELY(buttonBox,'RedButton')

    redButton:SetUserValue('MOVE_INDUN_CLASSID', indunCls.ClassID)

    if _G[redButtonScp] ~= nil then
        _G[redButtonScp](frame, redButton)
        g:ReserveScript(g.IndunEnter, {}, 0.5)
    end
end

function g.IndunEnter()
    local frame = _G.ui.GetFrame('indunenter')
    if frame == nil then
        return
    end

    if frame:IsVisible() ~= 1 then
        return
    end

    _G.INDUNENTER_AUTOMATCH(frame, nil)
end
