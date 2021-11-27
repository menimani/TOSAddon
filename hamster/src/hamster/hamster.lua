local addonName = 'HAMSTER'
local addonNameLower = addonName:lower()

_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]
local acutil = require('acutil')

g.settingsFileLoc = '../addons/'..addonNameLower..'/settings.json'
g.settings = {}

_G[addonName..'_ON_INIT'] = function(addon, frame)
    g.addon = g.addon or addon
    g.frame = g.addon or frame

    addon:RegisterMsg('GAME_START_3SEC', addonName..'_START_3SEC')
end

_G[addonName..'_START_3SEC'] = function()
    if _G.ADDONS.MENIMANI.BAN.isBan() then
        return
    end

    acutil.slashCommand('/hamster', _G[addonName..'_COMMAND'])

    g.Hook
    (
        'INDUNENTER_AUTOMATCH',
        function(frame)
            g.settings.lastIndunType = frame:GetTopParentFrame():GetUserValue('INDUN_TYPE')
            g.SaveSettings()
        end
    )

    g.LoadSettings()
end

_G[addonName..'_COMMAND'] = function(command)
    if #command > 0 then
        indunType = table.remove(command, 1)
    else
        indunType = g.settings.lastIndunType
    end

    if _G.GetClassByType('Indun', indunType) == nil then
        _G.CHAT_SYSTEM('Invalid command')
        return
    end
    g.OpenIndun(indunType)
end

function g.OpenIndun(indunType)
    if _G.session.world.IsIntegrateServer() == true or IsPVPField(pc) == 1 or IsPVPServer(pc) == 1 then
        _G.ui.SysMsg(ScpArgMsg('ThisLocalUseNot'))
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
        _G.ReserveScript(addonName..'_ENTER()', 0.5)
    end
end

_G[addonName..'_ENTER'] = function()
    local frame = _G.ui.GetFrame('indunenter')
    if frame == nil then
        return
    end

    if frame:IsVisible() ~= 1 then
        return
    end

    _G.INDUNENTER_AUTOMATCH(frame, nil)
end

function g.SaveSettings()
    acutil.saveJSON(g.settingsFileLoc, g.settings)
end

function g.LoadSettings()
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings)
    if err then
        --設定ファイル読み込み失敗時処理
        _G.CHAT_SYSTEM(string.format('[%s] cannot load setting files', addonNameLower))
    else
        --設定ファイル読み込み成功時処理
        g.settings = t
    end
end

function g.Hook(oldFuncName, func)
    _G[oldFuncName..'_OLD'] = _G[oldFuncName..'_OLD'] or _G[oldFuncName]
    _G[oldFuncName] = function(...)
        func(...)
        return _G[oldFuncName..'_OLD'](...)
    end
end