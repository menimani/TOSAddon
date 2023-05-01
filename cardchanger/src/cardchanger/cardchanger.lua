local addonName = 'CARDCHANGER'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

g.static = g.static or {}
g.static.group = {
    ['ATK'] = {
        startIndex = 0 * _G.MONSTER_CARD_SLOT_COUNT_PER_TYPE
    },
    ['DEF'] = {
        startIndex = 1 * _G.MONSTER_CARD_SLOT_COUNT_PER_TYPE
    },
    ['UTIL'] = {
        startIndex = 2 * _G.MONSTER_CARD_SLOT_COUNT_PER_TYPE
    },
    ['STAT'] = {
        startIndex = 3 * _G.MONSTER_CARD_SLOT_COUNT_PER_TYPE
    },
    ['LEG'] = {
        startIndex = 4 * _G.MONSTER_CARD_SLOT_COUNT_PER_TYPE
    }
}

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    local frame = _G.ui.GetFrame('inventory')
    local invenTab = _G.GET_CHILD_RECURSIVELY(frame, 'inventype_Tab')
    if invenTab == nil then
        return
    end
    invenTab:SetEventScript(_G.ui.LBUTTONUP, g:GFunc(g.ChangeTab))
end)

function g.ChangeTab()
    local frame = _G.ui.GetFrame('inventory')
    local invenTab = _G.GET_CHILD_RECURSIVELY(frame, 'inventype_Tab')
    if invenTab == nil then
        return
    end

    local tabIndex = invenTab:GetSelectItemIndex()
    local cardTabIndex = 4
    if tabIndex == cardTabIndex then
        g.ModeOn()
    else
        g.ModeOff()
    end
end

function g.ModeOn()
    _G.INVENTORY_SET_CUSTOM_RBTNDOWN(g:GFunc(g.InvRightClick))
end

function g.ModeOff()
    _G.INVENTORY_SET_CUSTOM_RBTNDOWN('None')
end

function g.InvRightClick(itemObj, _, itemGuid)
    print('InvRightClick')
    if itemObj.GroupName ~= 'Card' then
        return
    end
    print(itemGuid)

    local moncardFrame = _G.ui.GetFrame('monstercardslot')
    _G.imcSound.PlaySoundEvent('icon_get_down')
    local cardGroupName = itemObj.CardGroupName
    -- 強化用カード着用不可（レジェ）
    if cardGroupName == 'REINFORCE_CARD' then
        _G.ui.SysMsg(_G.ClMsg('LegendReinforceCard_Not_Equip'))
        return
    end
    -- 強化用カード着用不可（女神）
    if cardGroupName == 'REINFORCE_GODDESS_CARD' then
        _G.ui.SysMsg(_G.ClMsg('GoddessReinforceCard_Not_Equip'))
        return
    end
    -- カード装備（通常・レジェ）
    if moncardFrame ~= nil then
        g.EquipSimilarCard(cardGroupName, itemGuid)
    end
end

-- 同名カードを装備
function g.EquipSimilarCard(cardGroupName, itemGuid)
    local invItem = _G.session.GetInvItemByGuid(itemGuid)
    local iesObj = _G.GetIES(invItem:GetObject())
    local frame = _G.ui.GetFrame('monstercardslot')

    frame:SetUserValue('cardchanger_cardGroupName', cardGroupName)
    frame:SetUserValue('cardchanger_classID', iesObj.ClassID)
    frame:SetUserValue('cardchanger_lv', _G.TryGetProp(iesObj, 'Level', 1))
    frame:SetUserValue('cardchanger_mode', 'UNEQUIP')
    frame:ShowWindow(1)
    frame:RunUpdateScript(g:GFunc(g.Update), 0.2)
end

-- 同名カード取得
function g.GetCardInvItem(classId, lv)
    local itemList = _G.session.GetInvItemList()
    local guidList = itemList:GetGuidList()
    local cnt = guidList:Count()
    for i = 0, cnt - 1 do
        local guid = guidList:Get(i)
        local invItem = _G.session.GetInvItemByGuid(guid)
        local actualObject = _G.GetIES(invItem:GetObject())
        local itemType = actualObject.ClassID
        if tostring(itemType) == tostring(classId) then
            local cardLevel = _G.TryGetProp(actualObject, 'Level', 1)
            if cardLevel == lv then
                return invItem
            end
        end
    end
    return nil
end

function g.Update(frame)
    local cardGroupName = frame:GetUserValue('cardchanger_cardGroupName')
    local classId = frame:GetUserIValue('cardchanger_classID')
    local lv = frame:GetUserIValue('cardchanger_lv')
    local mode = frame:GetUserValue('cardchanger_mode')

    local gbox =  _G.GET_CHILD_RECURSIVELY(frame, cardGroupName .. 'cardGbox')
    local slotset =  _G.GET_CHILD_RECURSIVELY(gbox, cardGroupName .. 'card_slotset')

    if mode == 'UNEQUIP' then
        if cardGroupName == 'LEG' then
            local slotIndex = g.GetSlotIndex(cardGroupName, 0)
            g.UnEquipCard(slotIndex)
        else
            for i = 0, 2 do
                local slot = slotset:GetSlotByIndex(i)
                local icon = slot:GetIcon()
                if icon ~= nil then
                    local slotIndex = g.GetSlotIndex(cardGroupName, i)
                    g.UnEquipCard(slotIndex)
                    return 1
                end
            end
        end
        -- カード全解除完了したので、装備モードに移行
        frame:SetUserValue('cardchanger_mode', 'EQUIP')
        return 1
    elseif mode == 'EQUIP' then
        for i = 0, 2 do
            local slot = slotset:GetSlotByIndex(i)
            local icon = slot:GetIcon()
            if icon == nil or cardGroupName == 'LEG' then
                local invItem = g.GetCardInvItem(classId, lv)
                if (invItem == nil) then
                    -- 同名カードがインベントリに無い
                    frame:SetUserValue('cardchanger_cardGroupName', '')
                    frame:SetUserValue('cardchanger_classID', '')
                    frame:SetUserValue('cardchanger_lv', '')
                    frame:SetUserValue('cardchanger_mode', '')
                    frame:ShowWindow(0)
                    return 0
                end

                local slotIndex = g.GetSlotIndex(cardGroupName, i)
                g.EquipCard(slotIndex, invItem:GetIESID())
                return 1
            end
        end
    else
        frame:SetUserValue('cardchanger_cardGroupName', '')
        frame:SetUserValue('cardchanger_classID', '')
        frame:SetUserValue('cardchanger_lv', '')
        frame:SetUserValue('cardchanger_mode', '')
        frame:ShowWindow(0)
        return 0
    end
    frame:ShowWindow(0)
    return 0
end

-- カード装備
function g.EquipCard(slotIndex, itemGuid)
    local argStr = string.format('%d#%s', slotIndex, tostring(itemGuid))
    _G.pc.ReqExecuteTx('SCR_TX_EQUIP_CARD_SLOT', argStr)
end

-- カード装備解除
function g.UnEquipCard(slotIndex)
    local argStr = string.format('%d 1', slotIndex)
    _G.pc.ReqExecuteTx_NumArgs('SCR_TX_UNEQUIP_CARD_SLOT', argStr)
end

function g.GetSlotIndex(cardGroupName, cardSlotIndex)
    local startIndex = g.static.group[cardGroupName].startIndex
    return startIndex + cardSlotIndex
end
