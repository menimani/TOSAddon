local addonName = 'SHOWTARGETBUFF'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

g.settings = {
    enable = true,
    hiddenBuffList = {},
    priorBuffList = {},
    sizeScale = 1,
    position = {
        x = 1330,
        y = 372,
    },
    lowMode = false
}

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    g:LoadSettings()

    frame:Move(0, 0)
    frame:SetSkinName('none')
    frame:SetOffset(g.settings.position.x, g.settings.position.y)
    frame:SetEventScript(_G.ui.LBUTTONUP, g:GFunc(g.EndDrag))

    g:RegisterMsg('FPS_UPDATE', g.BuffUpdate)
    if g.LowMode() == false then
        g:setupEvent('TARGETBUFF_ON_MSG', g.BuffUpdate)
    end
    g:slashCommand('/showtargetbuff', g.Command)
end)

function g.BuffUpdate()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    if g.settings.enable then
        frame:ShowWindow(1)
    else
        frame:ShowWindow(0)
        return
    end
    local handle = _G.session.GetTargetHandle()
    local buffCount = _G.info.GetBuffCount(handle)
    g.Clear()
    local prior = {}
    local normal = {}
    for i = 0, buffCount - 1 do
        local curBuff = _G.info.GetBuffIndexed(handle, i)
        if g.settings.hiddenBuffList[tostring(curBuff.buffID)] == nil then
            if g.settings.priorBuffList[tostring(curBuff.buffID)] == nil then
                table.insert(normal, curBuff)
            else
                table.insert(prior, curBuff)
            end
        end
    end
    for _, curBuff in ipairs(prior) do
        g.AddBuff(curBuff)
    end
    if g.LowMode() == false then
        for _, curBuff in ipairs(normal) do
            g.AddBuff(curBuff)
        end
    end
end

function g.LowMode(enable)
    if enable == nil then
        return g.settings.lowMode
    end

    g.settings.lowMode = enable
    g:SaveSettings()

    if enable == true then
        g:UnRegisterMsg('TARGETBUFF_ON_MSG', g.BuffUpdate)
    else
        g:RegisterMsg('TARGETBUFF_ON_MSG', g.BuffUpdate)
    end
    g.BuffUpdate()
end

function g.Command(command)
    if #command == 0 then
        g.ToggleFrame()
        return
    end

    local cmd = table.remove(command, 1)
    if cmd == 'on' then
        g.AddonEnable(true)
        return
    elseif cmd == 'off' then
        g.AddonEnable(false)
        return
    elseif cmd == 'lowmode' then
        local arg = table.remove(command, 1)
        if arg == 'on' then
            g.LowMode(true)
            return
        elseif arg == 'off' then
            g.LowMode(false)
            return
        end
    end
    _G.CHAT_SYSTEM(string.format('[%s] Invalid Command', addonName))
end

-- 表示非表示切り替え処理
function g.ToggleFrame()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    g.AddonEnable(frame:IsVisible() == 0)
end

function g.AddonEnable(enable)
    g.settings.enable = enable
    g:SaveSettings()
    g.BuffUpdate()
end

function g.SizeScale(size)
    g.settings.sizeScale = tonumber(size)
    g:SaveSettings()
    g.BuffUpdate()
end

function g.Size(base)
    local scale = g.settings.sizeScale
    return math.ceil(base * scale)
end

function g.EndDrag()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    g.settings.position.x = frame:GetX()
    g.settings.position.y = frame:GetY()
    g:SaveSettings()
end

function g.Clear()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    frame:RemoveAllChild()
    frame:Resize(0, 0)
end

-- バフ行の描画
function g.AddBuff(curBuff)
    local frame = _G.ui.GetFrame(g.addonNameLower)
    local buff = _G.GetClassByType('Buff', curBuff.buffID)

    local icon = (function --[[アイコン作成]](x, y)
        local icon = frame:CreateOrGetControl('richtext', 'icon_' .. curBuff.index, x, y, 0, 0)

        local text = (function ()
            local size = g.Size(50)
            local name = buff.Icon
            return string.format('{img icon_%s %d %d}{/}', name, size, size)
        end)()

        icon:SetText(text)
        icon:EnableHitTest(0)
        return icon
    end)(0, frame:GetHeight())

    ;(function --[[アイコンにスタック数追加]]()
        if (curBuff.over or 1) > 1 then
            local text = icon:CreateOrGetControl('richtext', 'count', 0, 0, 0, 0)
            local font = string.format('{@st41}{s%d}', g.Size(21))
            text:SetText(font .. curBuff.over)

            -- 右下揃え
            local x = icon:GetWidth() - text:GetWidth() - 5
            local y = icon:GetHeight() - text:GetHeight() - 2
            text:SetOffset(x, y)
        end
    end)()

    local textBox = (function --[[テキストボックス作成]](x, y)
        local gbox = frame:CreateOrGetControl('groupbox', 'gbox_' .. curBuff.index, x, y, 0, 0)
        _G.tolua.cast(gbox, 'ui::CGroupBox')

        gbox:SetSkinName('none')
        gbox:EnableHitTest(1)
        gbox:SetEventScript(_G.ui.RBUTTONDOWN, g:GFunc(g.ContextMenu))
        gbox:SetEventScriptArgNumber(_G.ui.RBUTTONDOWN, curBuff.buffID)

        local tooltipText = (function ()
            return
                '{@st41}{s' .. tostring(g.Size(18)) .. '}'
                ..
                (function ()
                    if (curBuff.over or 1) > 1 then
                        return buff.Name .. ' X ' .. curBuff.over
                    end
                    return buff.Name
                end)()
                .. '{nl}'
                .. buff.Group1 .. ' rank' .. buff.Lv .. '{nl}'
                .. buff.ToolTip
        end)()

        gbox:SetTextTooltip(tooltipText)
        return gbox
    end)(icon:GetWidth(), frame:GetHeight())

    ;(function ()
        local text = textBox:CreateOrGetControl('richtext', 'text_' .. curBuff.index, 0, 0, 0, 0)
        _G.tolua.cast(text, 'ui::CRichText')

        local buffText = (function --[[バフテキストまとめて取得]]()
            return
                (function --[[フォントサイズ]]()
                    return '{@st41}{s' .. tostring(g.Size(18)) .. '}'
                end)()
                ..
                (function --[[バフ残り時間]]()
                    if curBuff.time == nil or curBuff.time == 0 then
                        return ' --- '
                    end
                    return string.format('%5d', math.ceil(curBuff.time/1000))
                end)()
                ..
                (function --[[バフテキストの色]]()
                    if g.settings.priorBuffList[tostring(curBuff.buffID)] ~= nil then
                        return '{#cfe600}' -- 黄
                    elseif buff.Group1 == 'Buff' then
                        return '{#00e6cf}' -- 青
                    elseif buff.Group1 == 'Debuff' then
                        return '{#cc0000}' -- 赤
                    end
                    return '' -- 白
                end)()
                ..
                (function --[[バフ種類]]()
                    if buff.Group1 == 'Buff' then
                        return '[ BUFF ] '
                    elseif buff.Group1 == 'Debuff' then
                        return '[DEBUFF] '
                    end
                    return string.upper('[' .. buff.Group1 .. '] ')
                end)()
                ..
                (function --[[使用者のスキルレベル取得]]()
                    return string.format('Lv%2d', curBuff.arg1) .. ' '
                end)()
                ..
                (function --[[バフ名]]()
                    return buff.Name .. '  '
                end)()
        end)()

        text:SetText(buffText)
        text:EnableHitTest(0)

        -- size合わせ
        textBox:Resize(text:GetWidth(), icon:GetHeight())
        -- 左端　中段
        text:SetOffset(text:GetX(), math.ceil((textBox:GetHeight() - text:GetHeight()) / 2))
    end)()

    local width = math.max(frame:GetWidth(), icon:GetWidth() + textBox:GetWidth())
    local height = frame:GetHeight() + math.max(icon:GetHeight(), textBox:GetHeight())
    frame:Resize(width, height)
end

function g.ContextMenu(_, _, _, buffID)
    local buffName = _G.GetClassByType('Buff', buffID).Name
    local buffIcon =  (function ()
        local size = g.Size(24)
        local name = _G.GetClassByType('Buff', buffID).Icon
        return string.format('{img icon_%s %d %d}{/}', name, size, size)
    end)()

    local context = _G.ui.CreateContextMenu('SHOWTARGETBUFF_RBTN', buffIcon .. ' ' .. buffName, 0, 0, 0, 0)
    _G.ui.AddContextMenuItem(context, '非表示にする', g:FuncFormat(g.AddHiddenBuff, {buffID}))

    if g.settings.priorBuffList[tostring(buffID)] == nil then
        _G.ui.AddContextMenuItem(context, '優先表示にする', g:FuncFormat(g.TogglePriorBuff, {buffID}))
    else
        _G.ui.AddContextMenuItem(context, '優先表示を解除', g:FuncFormat(g.TogglePriorBuff, {buffID}))
    end

    if g.LowMode() == true then
        _G.ui.AddContextMenuItem(context, '低スペックモードを解除', g:FuncFormat(g.LowMode, {'false'}))
    else
        _G.ui.AddContextMenuItem(context, '低スペックモードにする', g:FuncFormat(g.LowMode, {'true'}))
    end
    local sizeContext = _G.ui.CreateContextMenu('SHOWTARGETBUFF_SUBMENU_SIZE', '', 0, 0, 0, 0)
    _G.ui.AddContextMenuItem(sizeContext, '110%', g:FuncFormat(g.SizeScale, {1.10}))
    _G.ui.AddContextMenuItem(sizeContext, '100%', g:FuncFormat(g.SizeScale, {1.00}))
    _G.ui.AddContextMenuItem(sizeContext, ' 90%', g:FuncFormat(g.SizeScale, {0.90}))
    _G.ui.AddContextMenuItem(sizeContext, ' 75%', g:FuncFormat(g.SizeScale, {0.75}))
    _G.ui.AddContextMenuItem(context, 'サイズ設定' .. '  {img white_right_arrow 8 16}', '', nil, 0, 1, sizeContext)

    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('Cancel'), 'None')
    context:Resize(300, context:GetHeight())
    _G.ui.OpenContextMenu(context)
end

function g.AddHiddenBuff(buffID)
    local buffName = _G.GetClassByType('Buff', buffID).Name
    g.settings.hiddenBuffList[tostring(buffID)] = _G.dictionary.ReplaceDicIDInCompStr(buffName)
    g:SaveSettings()
    g.BuffUpdate()
    _G.CHAT_SYSTEM(buffName .. 'を非表示にしました')
end

function g.TogglePriorBuff(buffID)
    local buffName = _G.GetClassByType('Buff', buffID).Name
    if g.settings.priorBuffList[tostring(buffID)] == nil then
        g.settings.priorBuffList[tostring(buffID)] = _G.dictionary.ReplaceDicIDInCompStr(buffName)
        _G.CHAT_SYSTEM(buffName .. 'を優先表示にしました')
    else
        g.settings.priorBuffList[tostring(buffID)] = nil
        _G.CHAT_SYSTEM(buffName .. 'の優先表示を解除しました')
    end
    g:SaveSettings()
    g.BuffUpdate()
end
