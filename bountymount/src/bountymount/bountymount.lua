local addonName = 'BOUNTYMOUNT'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local M2UTIL = _G['ADDONS']['MENIMANI']['M2UTIL']
local g = _G['ADDONS']['MENIMANI'][addonName]

-- スキル：マウント召喚
local mountSkill = 100116
-- バフ：マウント搭乗中
local mountBuff = 14111

M2UTIL.OnInit(addonName, function()
    -- 武器スワップを「マウント召喚」に置き換え
    M2UTIL:setupHook('WEAPONSWAP_HOTKEY_ENTERED', function ()
        _G.control.Skill(mountSkill)
    end)

    -- マウント搭乗中にスキル使用時、マウントから降りる
    M2UTIL:setupHook('ICON_USE', function (...)
        if (g.hasBuff(mountBuff)) then
            _G.control.Skill(mountSkill)
        end
        return M2UTIL.oldFunc.ICON_USE(...)
    end)
end)

function g.hasBuff(buffID)
    local handle = _G.session.GetMyHandle()
    local buffCount = _G.info.GetBuffCount(handle)
    for i = 0, buffCount - 1 do
        local buff = _G.info.GetBuffIndexed(handle, i)
        if (buff.buffID == buffID) then
            return true
        end
    end
    return false
end
