local addonName = 'FASTREAD'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    g:setupHook('BEFORE_APPLIED_NON_EQUIP_ITEM_OPEN', g.QuickSlot)
end)

function g.QuickSlot(invItem)
    if invItem == nil then
        return
    end

    local invFrame = _G.ui.GetFrame("inventory")
    local itemobj = _G.GetIES(invItem:GetObject())
    if itemobj == nil then
        return
    end
    invFrame:SetUserValue("REQ_USE_ITEM_GUID", invItem:GetIESID())

    if itemobj.Script == 'SCR_SUMMON_MONSTER_FROM_CARDBOOK' then
        _G.REQUEST_SUMMON_BOSS_TX()
        return
    elseif itemobj.Script == 'SCR_QUEST_CLEAR_LEGEND_CARD_LIFT' then
        _G.REQUEST_SUMMON_BOSS_TX()
        return
    end
    return g.oldFunc['BEFORE_APPLIED_NON_EQUIP_ITEM_OPEN'](invItem)
end
