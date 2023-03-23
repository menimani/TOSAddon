local addonName = 'ADJUSTLAYER'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    g:LoadSettings()
    g.settings.frames = g.settings.frames or {
        { -- 女神ガチャの設定
            name = 'godprotection',
            level = 31
        }
    }
    g:SaveSettings()

    for i = 1, #g.settings.frames do
        local frame = g.settings.frames[i]
        _G.ui.GetFrame(frame.name):SetLayerLevel(frame.level)
    end
end)
