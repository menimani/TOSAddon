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

g.target = {
    _G.GetClassByType('Monster', '210000').Name, -- 追従者ジャガー
    _G.GetClassByType('Monster', '210001').Name, -- 堕落したレティアリィ
    _G.GetClassByType('Monster', '210002').Name, -- 追従者ケラウノス
    _G.GetClassByType('Monster', '210004').Name, -- 追従者カタフラクト
    _G.GetClassByType('Monster', '210005').Name, -- 追従者アバリスター
    _G.GetClassByType('Monster', '210006').Name, -- 追従者インクイジター
    _G.GetClassByType('Monster', '210007').Name, -- 追従者ジーロット
    _G.GetClassByType('Monster', '210008').Name, -- 追従者ムルミロ
}

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    local btn_close = _G.GET_CHILD_RECURSIVELY(frame, 'btn_close')
    btn_close:SetEventScript(_G.ui.LBUTTONUP, g:GFunc(g.CloseFrame))

    g:LoadSettings()

    g.CountUpdate()
    g.WarpMapUpdate()

    if g.survival <= 0 then
        -- 討伐完了時リセット
        -- 　※討伐ログ後も残像が残っているので、討伐後のロード時にリセット
        g.spotted = {} -- 発見済追従者
    end

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
            x = 10,
            y = 22 * index + 3
        }

        local icon = gbox_detail:CreateOrGetControl('picture', 'icon_' .. index, offset.x, offset.y, 15, 15)
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
    g.survival = g.popped - g.killed
    text_counter:SetTextByKey('count', g.killed..'/'..g.popped)

    if g.survival <= 0 then
        -- 討伐完了時リセット
        frame:ShowWindow(0)
        g.Reset()
    else
        -- 討伐中はウィンドウ表示
        frame:ShowWindow(1)
    end
end

function g.CloseFrame()
    _G.ui.GetFrame(g.addonNameLower):ShowWindow(0)
    g.Reset()
end

function g.Reset()
    g.popped = 0 -- 出現数
    g.killed = 0 -- 討伐数
    g.survival = 0 -- 生存数
    g.map = {} -- 出現場所
end

function g.GetSystemTime()
    local time = _G.geTime.GetServerSystemTime()
    return string.format('%02d:%02d:%02d', time.wHour, time.wMinute, time.wSecond)
end

function g.GetMapDicName(msgAppearPCMonster)
    local dicId = msgAppearPCMonster:match('%$name$%*$(.-)#@!')
    local dicKr = dicId:match("#(.-)#")
    -- Ｗ鯖統合により、仕様変更され、韓国語名のタグで送られてくることがある。
    if dicKr == nil then
        -- 韓国語ではない。従来のdicID
        return dicId
    end

    -- 突き合わせることで、韓国語名のタグからdicIDに変換。
    local plainNameTransrated = _G.dic.getTranslatedStr(dicKr)
    local clsList, size = _G.GetClassList('Map')
    for i = 0, size - 1 do
        local cls = _G.GetClassByIndexFromList(clsList, i)
        local plainName = _G.dictionary.ReplaceDicIDInCompStr(cls.Name)
        if plainName == plainNameTransrated then
            return cls.Name
        end
    end
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

function g.SpotterLoop()
    local list, count = _G.SelectObject(_G.GetMyPCObject(), 700, 'ALL')
    for i = 1, count do
        local handle = _G.GetHandle(list[i])
        if handle ~= nil and _G.info.IsPC(handle) == 1 then
            local familyName = _G.info.GetFamilyName(handle)
            if g.IsTarget(familyName) then
                local map = _G.session.GetMapName()
                local ch = _G.session.loginInfo.GetChannel() + 1
                -- 固まって出現するため、マップ＋チャンネル毎に１回のチャット出力とする
                if g.spotted['map'..map..'_ch'..ch] == nil then
                    g.spotted['map'..map..'_ch'..ch] = true
                    g.SpotterChat(handle)
                end
            end
        end
    end
end

function g.IsTarget(familyName)
    return g:Contains(g.target, familyName)
end

function g.SpotterChat(handle)
    local link = g.CreateLinkText(handle)
    local channel = _G.session.loginInfo.GetChannel() + 1
    local name = '追従者モンスター'
    local level = _G.info.GetLevel(handle)

    local msg = string.format(g.settings.message, link, channel, name, level)
    for _, type in pairs(g.settings.type) do
        if type.enable then
            _G.ui.Chat(type.command..msg)
        end
    end
end

function g.CreateLinkText(handle)
    local actor = _G.world.GetActor(handle)
    local pos = actor:GetPos()

    local prop = _G.session.GetCurrentMapProp()
    local name = prop:GetName()
    return string.format('{a SLM %d#%d#%d}{#0000FF}{img link_map 24 24}%s[%d,%d]{/}{/}{/}', prop.type, pos.x, pos.z, name, pos.x, pos.z)
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

function g.TestStart6KrMap()
    g.TestMsgAppear('|$#나하스 숲#$|')
    g.TestMsgAppear('|$#펠라인 포스트 타운#$|')
    g.TestMsgAppear('|$#엘고스 수도원 별관#$|')
    g.TestMsgAppear('|$#유데이안 숲#$|')
    g.TestMsgAppear('|$#칼레이마스 접견소#$|')
    g.TestMsgAppear('|$#칼레이마스 접견소#$|')
end

function g.TestStop6KrMap()
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
    g.TestMsgDisappear('name13')
    g.TestMsgDisappear('name14')
    g.TestMsgDisappear('name15')
    g.TestMsgDisappear('name16')
    g.TestMsgDisappear('name17')
    g.TestMsgDisappear('name18')
    g.TestMsgDisappear('name19')
    g.TestMsgDisappear('name20')
    g.TestMsgDisappear('name21')
    g.TestMsgDisappear('name22')
    g.TestMsgDisappear('name23')
    g.TestMsgDisappear('name24')
end