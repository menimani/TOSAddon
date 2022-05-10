local addonName = "SHOWTARGETBUFF"
local addonNameLower = string.lower(addonName)

_G["ADDONS"] = _G["ADDONS"] or {}
_G["ADDONS"]["MENIMANI"] = _G["ADDONS"]["MENIMANI"] or {}
_G["ADDONS"]["MENIMANI"][addonName] = _G["ADDONS"]["MENIMANI"][addonName] or {}

local g = _G["ADDONS"]["MENIMANI"][addonName]
local acutil = require("acutil")

g.settingsFileLoc = "../addons/"..addonNameLower.."/settings.json"
g.settings = {
    enable = true,
    hiddenBuffList = {},
    priorBuffList = {},
    size = 1,
    position = {
        x = 1330,
        y = 372,
    },
    lowSpecMode = false
}
-- dofile("../showtargetbuff.lua")
function _G.SHOWTARGETBUFF_ON_INIT(addon, frame)
    g.addon = addon
    g.frame = frame

    addon:RegisterMsg("GAME_START_3SEC", "SHOWTARGETBUFF_START_3SEC")
end

function _G.SHOWTARGETBUFF_START_3SEC()
    if _G.ADDONS.MENIMANI.BAN.isBan() then
        return
    end

    g.LoadSettings()
    g.SaveSettings()

    g.frame:Move(0, 0)
    g.frame:SetSkinName("none")
    g.frame:SetOffset(g.settings.position.x, g.settings.position.y)
    g.frame:SetEventScript(_G.ui.LBUTTONUP, "SHOWTARGETBUFF_END_DRAG")

    g.addon:RegisterMsg("FPS_UPDATE", "SHOWTARGETBUFF_UPDATE")
    acutil.setupEvent(g.addon, "TARGETBUFF_ON_MSG", "SHOWTARGETBUFF_ON_MSG_EVENT")
    if g.settings.lowSpecMode == true then
        _G.SHOWTARGETBUFF_ON_MSG_EVENT_OFF()
    else
        _G.SHOWTARGETBUFF_ON_MSG_EVENT_ON()
    end
    acutil.slashCommand("/"..addonNameLower, _G.SHOWTARGETBUFF_PROCESS_COMMAND)
end

function _G.SHOWTARGETBUFF_UPDATE()
    if g.settings.enable then
        g.frame:ShowWindow(1)
    else
        g.frame:ShowWindow(0)
        return
    end
    local handle = _G.session.GetTargetHandle()
    local buffCount = _G.info.GetBuffCount(handle)
    g.Drawing.Clear()
    local prior = {}
    local normal = {}
    for i = 0, buffCount - 1 do
        local buff = _G.info.GetBuffIndexed(handle, i)
        if g.settings.hiddenBuffList[tostring(buff.buffID)] == nil then
            if g.settings.priorBuffList[tostring(buff.buffID)] == nil then
                table.insert(normal, buff)
            else
                table.insert(prior, buff)
            end
        end
    end
    for _, buff in ipairs(prior) do
        g.Drawing.AddBuff(g.frame, buff)
    end
    if g.settings.lowSpecMode ~= true then
        for _, buff in ipairs(normal) do
            g.Drawing.AddBuff(g.frame, buff)
        end
    end
end

-- setupEventで紐づけた関数をオンオフする方法が思いつかなかった
function _G.SHOWTARGETBUFF_ON_MSG_EVENT()
end

-- setupEventで紐づけた関数に処理を与える
function _G.SHOWTARGETBUFF_ON_MSG_EVENT_ON()
    _G.SHOWTARGETBUFF_ON_MSG_EVENT = _G.SHOWTARGETBUFF_UPDATE
end

-- setupEventで紐づけた関数から処理を外す
function _G.SHOWTARGETBUFF_ON_MSG_EVENT_OFF()
    _G.SHOWTARGETBUFF_ON_MSG_EVENT = function() end
end

function _G.SHOWTARGETBUFF_LOWSPECMODE_ON()
    g.settings.lowSpecMode = true
    g.SaveSettings()
    _G.SHOWTARGETBUFF_ON_MSG_EVENT_OFF()
    _G.SHOWTARGETBUFF_UPDATE()
end

function _G.SHOWTARGETBUFF_LOWSPECMODE_OFF()
    g.settings.lowSpecMode = false
    g.SaveSettings()
    _G.SHOWTARGETBUFF_ON_MSG_EVENT_ON()
    _G.SHOWTARGETBUFF_UPDATE()
end

function _G.SHOWTARGETBUFF_PROCESS_COMMAND(command)
    local cmd

    if #command > 0 then
        cmd = table.remove(command, 1)
    else
        g.ToggleFrame()
        return
    end

    if cmd == "on" then
        g.settings.enable = true
        g.SaveSettings()
        _G.SHOWTARGETBUFF_UPDATE()
        return
    elseif cmd == "off" then
        g.settings.enable = false
        g.SaveSettings()
        _G.SHOWTARGETBUFF_UPDATE()
        return
    elseif cmd == "lowmode" then
        local arg = table.remove(command, 1)
        if arg == "on" then
            _G.SHOWTARGETBUFF_LOWSPECMODE_ON()
            return
        elseif arg == "off" then
            _G.SHOWTARGETBUFF_LOWSPECMODE_OFF()
            return
        end
    end
    _G.CHAT_SYSTEM(string.format("[%s] Invalid Command", addonName))
end

-- 表示非表示切り替え処理
function g.ToggleFrame()
    if g.frame:IsVisible() == 0 then
        -- 非表示->表示
        g.settings.enable = true
    else
        -- 表示->非表示
        g.settings.enable = false
    end
    g.SaveSettings()
    _G.SHOWTARGETBUFF_UPDATE()
end

function _G.SHOWTARGETBUFF_CONTEXT_MENU(_, _, _, buffID)
    local buffName = g.GetBuffName(buffID)
    local buffIcon = g.GetBuffIcon(buffID, 24)
    local context = _G.ui.CreateContextMenu("SHOWTARGETBUFF_RBTN", buffIcon .. " " .. buffName, 0, 0, 0, 0)
    _G.ui.AddContextMenuItem(context, "非表示にする", string.format("SHOWTARGETBUFF_ADD_HIDDEN_BUFF(%d)", buffID))
    if g.settings.priorBuffList[tostring(buffID)] == nil then
        _G.ui.AddContextMenuItem(context, "優先表示にする", string.format("SHOWTARGETBUFF_TOGGLE_PRIOR_BUFF(%d)", buffID))
    else
        _G.ui.AddContextMenuItem(context, "優先表示を解除", string.format("SHOWTARGETBUFF_TOGGLE_PRIOR_BUFF(%d)", buffID))
    end

    if g.settings.lowSpecMode == true then
        _G.ui.AddContextMenuItem(context, "低スペックモードを解除", "SHOWTARGETBUFF_LOWSPECMODE_OFF()")
    else
        _G.ui.AddContextMenuItem(context, "低スペックモードにする", "SHOWTARGETBUFF_LOWSPECMODE_ON()")
    end
    local sizeContext = _G.ui.CreateContextMenu("SHOWTARGETBUFF_SUBMENU_SIZE", "", 0, 0, 0, 0)
    _G.ui.AddContextMenuItem(sizeContext, "110%", string.format("SHOWTARGETBUFF_SIZE(%f)", 1.1))
    _G.ui.AddContextMenuItem(sizeContext, "100%", string.format("SHOWTARGETBUFF_SIZE(%f)", 1))
    _G.ui.AddContextMenuItem(sizeContext, "90%", string.format("SHOWTARGETBUFF_SIZE(%f)", 0.9))
    _G.ui.AddContextMenuItem(sizeContext, "75%", string.format("SHOWTARGETBUFF_SIZE(%f)", 0.75))
    _G.ui.AddContextMenuItem(context, "サイズ設定" .. "  {img white_right_arrow 8 16}", "", nil, 0, 1, sizeContext)

    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg("Cancel"), "None")
    context:Resize(300, context:GetHeight())
    _G.ui.OpenContextMenu(context)
end

function _G.SHOWTARGETBUFF_ADD_HIDDEN_BUFF(buffID)
    local buffName = g.GetBuffName(buffID)
    g.settings.hiddenBuffList[tostring(buffID)] = _G.dictionary.ReplaceDicIDInCompStr(buffName)
    g.SaveSettings()
    _G.SHOWTARGETBUFF_UPDATE()
    _G.CHAT_SYSTEM(buffName .. "を非表示にしました")
end

function _G.SHOWTARGETBUFF_TOGGLE_PRIOR_BUFF(buffID)
    local buffName = g.GetBuffName(buffID)
    if g.settings.priorBuffList[tostring(buffID)] == nil then
        g.settings.priorBuffList[tostring(buffID)] = _G.dictionary.ReplaceDicIDInCompStr(buffName)
        _G.CHAT_SYSTEM(buffName .. "を優先表示にしました")
    else
        g.settings.priorBuffList[tostring(buffID)] = nil
        _G.CHAT_SYSTEM(buffName .. "の優先表示を解除しました")
    end
    g.SaveSettings()
    _G.SHOWTARGETBUFF_UPDATE()
end

function _G.SHOWTARGETBUFF_SIZE(size)
    g.settings.size = tonumber(size)
    g.SaveSettings()
    _G.SHOWTARGETBUFF_UPDATE()
end

function _G.SHOWTARGETBUFF_END_DRAG()
    g.settings.position.x = g.frame:GetX()
    g.settings.position.y = g.frame:GetY()
    g.SaveSettings()
end

function g.SaveSettings()
    acutil.saveJSON(g.settingsFileLoc, g.settings)
end

function g.LoadSettings()
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings)
    if err then
        --設定ファイル読み込み失敗時処理
        _G.CHAT_SYSTEM(string.format("[%s] cannot load setting files", addonNameLower))
    else
        --設定ファイル読み込み成功時処理
        g.settings = t
    end
end

-- バフテキストまとめて取得
function g.GetCurBuffText(buff)
    local font = "{@st41}{s" .. tostring(math.ceil(18 * g.settings.size)) .. "}"
    local text = font
    text = text .. g.GetBuffTime(buff) .. " "
    if g.settings.priorBuffList[tostring(buff.buffID)] == nil then
        text = text .. g.GetBuffTypeColor(buff.buffID)
    else
        text = text .. "{#cfe600}"
    end
    text = text .. g.GetBuffTypeText(buff.buffID) .. "  "
    text = text .. g.GetBuffSLvText(buff) .. " "
    text = text .. g.GetBuffName(buff.buffID) .. "  "
    return text
end

function g.GetBuffTooltipText(buff)
    local buffCls = _G.GetClassByType("Buff", buff.buffID)
    local font = "{@st41}{s" .. tostring(math.ceil(18 * g.settings.size)) .. "}"
    local text = font
    text = text .. buffCls.Name
    if buff.over ~= nil and buff.over > 1 then
        text = text .. " X " .. buff.over
    end
    text = text .. "{nl}"
    text = text .. buffCls.Group1 .. " rank" .. buffCls.Lv .. "{nl}"
    text = text .. buffCls.ToolTip
    return text
end

function g.GetBuffIcon(buffID, size)
    local iconSize = size or math.ceil(g.settings.size * 50)
    local iconName = _G.GetClassByType("Buff", buffID).Icon
    return string.format("{img icon_%s %d %d}{/}", iconName, iconSize, iconSize)
end

function g.GetBuffTime(buff)
    if buff.time == nil or buff.time == 0 then
        return " --- "
    end
    return string.format("%5d", math.ceil(buff.time/1000))
end

function g.GetBuffTypeText(buffID)
    local buffType = _G.GetClassByType("Buff", buffID).Group1
    if buffType == "Buff" then
        return "[ BUFF ]"
    elseif buffType == "Debuff" then
        return "[DEBUFF]"
    end
    return string.upper("[" .. buffType .. "]")
end

function g.GetBuffTypeColor(buffID)
    local buffType = _G.GetClassByType("Buff", buffID).Group1
    if buffType == "Buff" then
        return "{#00e6cf}"
    elseif buffType == "Debuff" then
        return "{#cc0000}"
    end
    return ""
end

-- 使用者のスキルレベル取得
function g.GetBuffSLvText(buff)
    return string.format("Lv%2d", buff.arg1)
end

function g.GetBuffName(buffID)
    return _G.GetClassByType("Buff", buffID).Name
end

-- 描画処理
g.Drawing = {}

function g.Drawing.SetStackBuff(parent, buff)
    if buff.over == nil then
        return
    end
    if parent == nil then
        return
    end
    -- デプロテクテッドゾーン等の重複するバフのスタック数表示
    if buff.over > 1 then
        local text = parent:CreateOrGetControl("richtext", "count", 0, 0, 0, 0)
        local font = string.format("{@st41}{s%d}", math.ceil(21 * g.settings.size))
        text:SetText(font .. buff.over)

        local x = parent:GetWidth() - text:GetWidth() - 5
        local y = parent:GetHeight() - text:GetHeight() - 2
        text:SetOffset(x, y)
    end
end

function g.Drawing.Clear()
    g.frame:RemoveAllChild()
    g.frame:Resize(0, 0)
end

function g.Drawing.AddBuff(frame, buff)
    local Bottom = frame:GetHeight()
    local Width = 0
    local Height = 0

    local icon = g.Drawing.CreateIcon(frame, buff, Width, Bottom)
    Width = icon:GetWidth()
    Height = icon:GetHeight()

    local gbox = g.Drawing.CreateContextMenuBox(frame, buff, Width, Bottom)
    local text = g.Drawing.CreateText(gbox, buff)
    gbox:Resize(text:GetWidth(), Height)
    -- 左端　中段
    text:SetOffset(text:GetX(), math.ceil((gbox:GetHeight() - text:GetHeight()) / 2))

    Width = Width + gbox:GetWidth()
    if Height < gbox:GetHeight() then
        Height = gbox:GetHeight()
    end

    if frame:GetWidth() < Width then
        frame:Resize(Width, Bottom + Height)
    else
        frame:Resize(frame:GetWidth(), Bottom + Height)
    end
end

function g.Drawing.CreateIcon(parent, buff, x, y)
    x = x or 0
    y = y or parent:GetHeight()

    local icon = parent:CreateOrGetControl("richtext", "icon_" .. buff.index, x, y, 0, 0)
    local buffIcon = g.GetBuffIcon(buff.buffID)
    icon:SetText(buffIcon)
    icon:EnableHitTest(0)
    g.Drawing.SetStackBuff(icon, buff)
    return icon
end

function g.Drawing.CreateText(parent, buff, x, y)
    x = x or 0
    y = y or parent:GetHeight()

    local text = parent:CreateOrGetControl("richtext", "text_" .. buff.index, 0, 0, 0, 0)
    _G.tolua.cast(text, "ui::CRichText")
    local buffText = g.GetCurBuffText(buff)
    text:SetText(buffText)
    text:EnableHitTest(0)
    return text
end

function g.Drawing.CreateContextMenuBox(parent, buff, x, y)
    x = x or 0
    y = y or parent:GetHeight()

    local gbox = parent:CreateOrGetControl("groupbox", "gbox_" .. buff.index, x, y, 0, 0)
    _G.tolua.cast(gbox, "ui::CGroupBox")
    gbox:SetSkinName("none")
    gbox:EnableHitTest(1)
    gbox:SetEventScript(_G.ui.RBUTTONDOWN, "SHOWTARGETBUFF_CONTEXT_MENU")
    gbox:SetEventScriptArgNumber(_G.ui.RBUTTONDOWN, buff.buffID)
    gbox:SetTextTooltip(g.GetBuffTooltipText(buff))
    return gbox
end