local addonName = 'FKFUNC'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    g:LoadSettings()
    g.settings.fklist = g.settings.fklist or {
        'SYSMENU_GUILD_PROMOTE_NOTICE' -- 加入できるギルドがあります。表示関数
    }
    g:SaveSettings()

    for i = 1, #g.settings.fklist do
        g:setupHook(g.settings.fklist[i], function () end)
    end
end)
