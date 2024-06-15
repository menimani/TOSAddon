local addonName = 'ANIMUSBUGFIX'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]


_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    local type = 584103 -- アニマス
    g.Refresh(type)
end)

function g.Refresh(type)
    local slot = _G.item.GetEquipSpotNum('NECK')
    if _G.GetIES(_G.session.GetEquipItemBySpot(slot):GetObject()).ClassID ~= type then
        return
    end
    local item = _G.session.GetInvItemByType(type)
    if item ~= nil  then
        -- ２個持ちの場合（着）
        _G.item.Equip(item.invIndex)
        return
    end

    -- １個持ちの場合（脱着）
    _G.item.UnEquip(slot)
    g:ReserveScript(_G.item.Equip, {item.invIndex}, 0.5)
    g:ReserveScript(_G.item.Equip, {item.invIndex}, 1.0)
    g:ReserveScript(_G.item.Equip, {item.invIndex}, 1.5)
    g:ReserveScript(_G.item.Equip, {item.invIndex}, 2.0)
    g:ReserveScript(_G.item.Equip, {item.invIndex}, 2.5)
end
