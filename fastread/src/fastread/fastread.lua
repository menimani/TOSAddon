local addonName = 'FASTREAD'

_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

_G[addonName..'_ON_INIT'] = function(addon, frame)
    g.addon = g.addon or addon
    g.frame = g.addon or frame

    addon:RegisterMsg('GAME_START', addonName..'_START')
end

_G[addonName..'_START'] = function()
    if _G.ADDONS.MENIMANI.BAN.isBan() then
        return
    end

    local acutil = require('acutil')

    acutil.setupHook(g.QuickSlot, 'BEFORE_APPLIED_NON_EQUIP_ITEM_OPEN')
end

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
    return _G.BEFORE_APPLIED_NON_EQUIP_ITEM_OPEN(invItem)
end
