local addonName = 'CHASER'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

-- マップ毎の追従者出現数
local APPEAR_MONSTERS_PER_MAP = 4

g.popped = 0 -- 出現数
g.killed = 0 -- 討伐数
g.survival = 0 -- 生存数

g.map = {} -- 出現場所
g.spotted = {} -- 発見済追従者

g.settings = {
    type = {
        party = {
            enable = true,
            command = '/p '
        },
        guild = {
            enable = false,
            command = '/g '
        }
    },
    message = '%s %dch %s(Lv%d)を発見'
}

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    local btn_close = _G.GET_CHILD_RECURSIVELY(frame, 'btn_close')
    btn_close:SetEventScript(_G.ui.LBUTTONUP, g:GFunc(g.CloseFrame))

    g:LoadSettings()

    g.CountUpdate()
    g.WarpMapUpdate()

    g:RegisterMsg('NOTICE_Dm_Global_Shout', g.NoticeDmGlobalShout)
    g:RegisterMsg('FPS_UPDATE', g.TokenWarpCdUpdate)
    g:RegisterMsg('FPS_UPDATE', g.SpotterLoop)

    g:slashCommand('/chaser', g.Command)
end)

function g.NoticeDmGlobalShout(_, _, argStr, _)
    local time = g.GetSystemTime()

    -- {name}に追従者モンスター達が出現しました
    if argStr:find('AppearPCMonster{name}') then
        _G.CHAT_SYSTEM('{#00e6cf}['..time..'] '..argStr)
        table.insert(g.map, g.GetMapDicName(argStr))

        g.popped = g.popped + APPEAR_MONSTERS_PER_MAP
        g.CountUpdate()
        g.WarpMapUpdate()
        return
    end

    -- 追従者が討伐されました：「{name}」
    if argStr:find('{name}DisappearPCMonster') then
        _G.CHAT_SYSTEM('{#00e6cf}['..time..'] '..argStr)

        g.killed = g.killed + 1
        g.CountUpdate()
        return
    end
end

function g.WarpMapUpdate()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    local gbox_detail = _G.GET_CHILD_RECURSIVELY(frame, 'gbox_detail')

    gbox_detail:RemoveAllChild()

    for k, v in ipairs(g.map) do
        local index = k - 1
        local mapCls = _G.GetClassByStrProp('Map', 'Name', v)

        local offset = {
            x = 20,
            y = 45 * index + 6
        }

        local icon = gbox_detail:CreateOrGetControl('picture', 'icon_' .. index, offset.x, offset.y, 30, 30)
        _G.tolua.cast(icon, 'ui::CPicture')
        icon:SetImage('questinfo_return')
        icon:SetEventScript(_G.ui.LBUTTONUP, g:GFunc(g.TokenWarp))
        icon:SetEventScriptArgString(_G.ui.LBUTTONUP, mapCls.ClassName)
        icon:SetEnableStretch(1)
        icon:EnableHitTest(1)
        icon:SetAngleLoop(-3)

        local text = gbox_detail:CreateOrGetControl('richtext', 'text_' .. index, offset.x + icon:GetWidth(), offset.y, 0, 0)
        _G.tolua.cast(text, 'ui::CRichText')
        text:SetText(mapCls.Name)
        text:EnableHitTest(0)

        -- 左端　中段
        text:SetOffset(offset.x + icon:GetWidth(), offset.y + math.ceil((icon:GetHeight() - text:GetHeight()) / 2))
    end
end

function g.TokenWarpCdUpdate()
    local function ToMMSS(cd)
        local mm = math.floor(cd / 60)
        local ss = cd % 60
        return string.format('%02d:%02d', mm, ss)
    end

    local cd = _G.GET_TOKEN_WARP_COOLDOWN()
    local maxCd = _G.TOKEN_WARP_COOLTIME

    local frame = _G.ui.GetFrame(g.addonNameLower)
    local text_counter = _G.GET_CHILD_RECURSIVELY(frame, 'text_timer')
    text_counter:SetTextByKey('time', ToMMSS(cd))

    local gauge_timer = _G.GET_CHILD_RECURSIVELY(frame, 'gauge_timer')
    gauge_timer:SetMaxPointWithTime(cd / 1000, maxCd / 1000, 0.1, 0.5)
end

function g.CountUpdate()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    local text_counter = _G.GET_CHILD_RECURSIVELY(frame, 'text_counter')
    text_counter:SetTextByKey('text', '討伐状況')
    g.remaining = g.popped - g.killed
    text_counter:SetTextByKey('count', g.killed..'/'..g.popped)

    if g.remaining <= 0 then
        -- 討伐完了時リセット
        frame:ShowWindow(0)
        g.popped = 0 -- 出現数
        g.killed = 0 -- 討伐数
        g.survival = 0 -- 生存数
        g.map = {} -- 出現場所
    else
        -- 討伐中はウィンドウ表示
        frame:ShowWindow(1)
    end
end

function g.CloseFrame()
    _G.ui.GetFrame(g.addonNameLower):ShowWindow(0)
end

function g.GetSystemTime()
    local time = _G.geTime.GetServerSystemTime()
    return string.format('%02d:%02d:%02d', time.wHour, time.wMinute, time.wSecond)
end

function g.GetMapDicName(msgAppearPCMonster)
    return msgAppearPCMonster:match('%$name$%*$(.-)#@!')
end

function g.TokenWarp(_, _, className, _)
    _G.WORLDMAP2_TOKEN_WARP(className)
end

function g.Command(command)
    if #command == 0 then
        return
    end

    local cmd = table.remove(command, 1)

    if g.settings.type[cmd] ~= nil and #command > 0 then
        --チャット種別の選択
        local arg = table.remove(command, 1)
        --オンオフ
        if arg == 'on' then
            g.settings.type[cmd].enable = true
            _G.CHAT_SYSTEM(string.format('[Chaser] %s is enable', cmd))
            g:SaveSettings()
            return
        elseif arg == 'off' then
            g.settings.type[cmd].enable = false
            _G.CHAT_SYSTEM(string.format('[Chaser] %s is disable', cmd))
            g:SaveSettings()
            return
        end
    end
    _G.CHAT_SYSTEM('[Chaser] Invalid Command')
end

-- 一定時間間隔で実行する
function g.SpotterLoop()
    local FoundList, FoundCount = _G.SelectBaseObject(_G.GetMyPCObject(), 700, 'ENEMY')
    for i = 1 , FoundCount do
        local FoundItem = FoundList[i]
        local actor = _G.tolua.cast(FoundItem, 'CFSMActor')
        if actor:GetObjType() == _G.GT_MONSTER then
            local monCls = _G.GetClassByType('Monster', actor:GetType())
            local monName = _G.dictionary.ReplaceDicIDInCompStr(monCls.Name)
            if string.find(monName, '追従者') then
                local handle = actor:GetHandleVal()
                if g.spotted[tostring(handle)] ~= true then
                    g.spotted[tostring(handle)] = true
                    g.SpotterChat(actor)
                end
            end
        end
    end
end

function g.SpotterChat(actor)
    local monCls = _G.GetClassByType('Monster', actor:GetType())
    local channel = _G.session.loginInfo.GetChannel()
    local actorPos = actor:GetPos()
    local level = actor:GetLv()
    local place = _G.MAKE_LINK_MAP_TEXT(_G.session.GetMapName(), actorPos.x, actorPos.z)
    local message = g.settings.message

    for _, type in pairs(g.settings.type) do
        if type.enable then
            local chat = string.format(type.command..message, place, channel+1, monCls.Name, level)
            _G.ui.Chat(chat)
        end
    end
end

--[[
    デバッグ用コード
]]
function g.TestMsgAppear(name)
    _G.imcAddOn.BroadMsg('NOTICE_Dm_Global_Shout', _G.ScpArgMsg('AppearPCMonster{name}', 'name', name), 1)
end

function g.TestMsgDisappear(name)
    _G.imcAddOn.BroadMsg('NOTICE_Dm_Global_Shout', _G.ScpArgMsg('{name}DisappearPCMonster', 'name', name), 1)
end

function g.TestStart3Map()
    g.TestMsgAppear('@dicID_^*$ETC_20150714_011746$*^')
    g.TestMsgAppear('@dicID_^*$ETC_20151223_017969$*^')
    g.TestMsgAppear('@dicID_^*$ETC_20150804_014153$*^')
end

function g.TestStop3Map()
    g.TestMsgDisappear('name01')
    g.TestMsgDisappear('name02')
    g.TestMsgDisappear('name03')
    g.TestMsgDisappear('name04')
    g.TestMsgDisappear('name05')
    g.TestMsgDisappear('name06')
    g.TestMsgDisappear('name07')
    g.TestMsgDisappear('name08')
    g.TestMsgDisappear('name09')
    g.TestMsgDisappear('name10')
    g.TestMsgDisappear('name11')
    g.TestMsgDisappear('name12')
end

function g.TestStart2Map()
    g.TestMsgAppear('@dicID_^*$ETC_20150714_011746$*^')
    g.TestMsgAppear('@dicID_^*$ETC_20151223_017969$*^')
end

function g.TestStop2Map()
    g.TestMsgDisappear('name01')
    g.TestMsgDisappear('name02')
    g.TestMsgDisappear('name03')
    g.TestMsgDisappear('name04')
    g.TestMsgDisappear('name05')
    g.TestMsgDisappear('name06')
    g.TestMsgDisappear('name07')
    g.TestMsgDisappear('name08')
end
