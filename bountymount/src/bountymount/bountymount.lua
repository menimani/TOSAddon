local addonName = 'BOUNTYMOUNT'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

-- スキル：マウント召喚
local mountSkill = 100116
-- バフ：マウント搭乗中
local mountBuff = 14111

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    -- 武器スワップを「マウント召喚」に置き換え
    g:setupHook('WEAPONSWAP_HOTKEY_ENTERED', function ()
        _G.control.Skill(mountSkill)
    end)

    -- マウント搭乗中にスキル使用時、マウントから降りる
    g:setupHook('ICON_USE', function (...)
        if (g.hasBuff(mountBuff)) then
            _G.control.Skill(mountSkill)
        end
        return g.oldFunc.ICON_USE(...)
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
