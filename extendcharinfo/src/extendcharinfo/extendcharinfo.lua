local addonName = 'EXTENDCHARINFO'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    g:slashCommand('/charinfo', g.Command)
    g:slashCommand('/mem', g.CommandMemberInfo)

    g.isBanMode = false

    -- addon.ipf/chatframe/chatframe.lua
    g:setupHook('CHAT_RBTN_POPUP', g.AddContextForChat)

    -- addon.ipf/friend/friend.lua
    g:setupHook('POPUP_FRIEND_COMPLETE_CTRLSET', g.AddContextForFriendList)

    -- addon.ipf/partyinfo/partyinfo.lua
    g:setupHook('CONTEXT_PARTY', g.AddContextForParty)

    -- addon.ipf/guildinfo/guildinfo_member.lua
    g:setupHook('POPUP_GUILD_MEMBER', g.AddContextForGuild)
end)

function g.Command(command)
    local cmd
    if #command > 0 then
        cmd = table.remove(command, 1)
        if cmd == 'ban' then
            g.isBanMode = g.isBanMode ~= true
        end
        return
    end
end

function g.CommandMemberInfo(command)
    local cmd
    if #command > 0 then
        cmd = table.remove(command, 1)
        g.ShowMemberInfo(cmd) -- キャラ情報表示
        return
    end
end

function g.ShowMemberInfo(name)
    _G.ui.Chat('/memberinfo '..name)
end

function g.GetMyServerName()
    (function ()
        if g.serverList ~= nil then
            return
        end

        local f = io.open('../release/serverlist_recent.xml', 'rb')
        local content = f:read('*all')
        f:close()
        g.serverList = {}
        for id, name in string.gmatch(content, 'GROUP_ID="(.-)".-NAME="(.-)"') do
            g.serverList[id] = name
        end
    end)()

    function g.GetMyServerId()
        local f = io.open('../release/user.xml', 'rb')
        local content = f:read('*all')
        f:close()
        return content:match('RecentServer="(.-)"')
    end

    return g.serverList[g.GetMyServerId()]
end

-- チャット
function g.AddContextForChat(frame, chatCtrl)
    local targetName = chatCtrl:GetUserValue('TARGET_NAME')
    local splitName = string.split(targetName, ' ')
    local serverName = splitName[2]

    if serverName ~= nil and not string.find(serverName, g.GetMyServerName()) then
        -- 他サーバーのプレイヤーなら処理はしない
        return
    end

    targetName = splitName[1]
    local myName = _G.GETMYFAMILYNAME()
    if myName == targetName then
        return
    end

    -- ささやき
    local function Whisper(context)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('WHISPER'), string.format('ui.WhisperTo("%s")', targetName))
    end

    -- フレンド申請
    local function ReqAddFriend(context)
        local strRequestAddFriendScp = string.format('friends.RequestRegister("%s")', targetName)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('ReqAddFriend'), strRequestAddFriendScp)
    end

    -- 装備確認
    local function ShowInfomation(context)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('ShowInfomation'), g:FuncFormat(g.ShowMemberInfo, {'"'..targetName..'"'}))
    end

    -- パーティ招待
    local function PartyInvite(context)
        local partyinviteScp = string.format('PARTY_INVITE("%s")', targetName)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('PARTY_INVITE'), partyinviteScp)
    end

    -- 翻訳
    local function Translate(context)
        local topFrame = frame:GetTopParentFrame()
        local parentFrame = frame:GetParent()
        local topFrame_Name = topFrame:GetName()
        local parentFrame_Name = parentFrame:GetName()
        local ctrlName = frame:GetName()
        if _G.GET_PRIVATE_CHANNEL_ACTIVE_STATE() == true then
            local translateScp  = string.format('REQ_TRANSLATE_TEXT("%s","%s","%s")',topFrame_Name,parentFrame_Name,ctrlName)
            _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('TRANSLATE'),translateScp)
        end
    end

    -- プレイヤー名コピー
    local function CopyPcId(context)
        local copyPcId = string.format('COPY_PC_ID("%s")',targetName)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('CopyPcId'),copyPcId)
    end

    -- テキストコピー
    local function CopyPcSentence(context)
        local targetTxt = chatCtrl:GetUserValue('SENTENCE')
        local copyPcSentence = string.format('COPY_PC_SENTENCE("%s")',targetTxt)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('CopyPcSentence'),copyPcSentence)
    end

    -- ブロック
    local function FriendBlock(context)
        local blockScp = string.format('CHAT_BLOCK_MSG("%s")', targetName )
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('FriendBlock'), blockScp)
    end

    -- 通報
    local function ReportAutoBot(context)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('Report_AutoBot'), string.format('REPORT_AUTOBOT_MSGBOX("%s")', targetName))
    end

    -- キャンセル
    local function Cancel(context)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('Cancel'), 'None')
    end

    local context = _G.ui.CreateContextMenu('CONTEXT_CHAT_RBTN', targetName, 0, 0, 170, 100)

    if _G.session.world.IsIntegrateServer() == true then
        -- 統合サーバー内では機能制限
        Whisper(context)
        Translate(context)
        CopyPcId(context)
        CopyPcSentence(context)
        Cancel(context)
    else
        Whisper(context)
        ReqAddFriend(context)
        ShowInfomation(context)
        PartyInvite(context)
        Translate(context)
        CopyPcId(context)
        CopyPcSentence(context)
        FriendBlock(context)
        ReportAutoBot(context)
        Cancel(context)
    end

    _G.ui.OpenContextMenu(context)

end

-- フレンドリスト
function g.AddContextForFriendList(_, ctrlset)
    local aid = ctrlset:GetUserValue('AID')
    if aid == '' then
        return
    end
    local f = _G.session.friends.GetFriendByAID(_G.FRIEND_LIST_COMPLETE, aid)

    if f == nil then
        return
    end

    local info = f:GetInfo()
    local context = _G.ui.CreateContextMenu('FRIEND_CONTEXT', '', 0, 0, 0, 0)

    if f.mapID ~= 0 then
    local partyinviteScp = string.format('PARTY_INVITE("%s")', info:GetFamilyName())
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('PARTY_INVITE'), partyinviteScp)
    end

    local whisperScp = string.format('ui.WhisperTo("%s")', info:GetFamilyName())
    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('WHISPER'), whisperScp)

    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('ShowInfomation'), g:FuncFormat(g.ShowMemberInfo, {'"'..info:GetFamilyName()..'"'}))

    local memoScp = string.format('FRIEND_SET_MEMO("%s")',aid)
    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('FriendAddMemo'), memoScp)

    local groupnamelist = {}
    local cnt = _G.session.friends.GetFriendCount(_G.FRIEND_LIST_COMPLETE)

    for i = 0 , cnt - 1 do
        local allfriend = _G.session.friends.GetFriendByIndex(_G.FRIEND_LIST_COMPLETE, i)
        local groupname = allfriend:GetGroupName()

        if groupname ~= nil and groupname ~= '' and groupname ~= 'None' and groupname ~= f:GetGroupName() and groupnamelist[groupname] == nil then
            table.insert(groupnamelist,groupname)
        end
    end

    local subcontext = _G.ui.CreateContextMenu('SUB', '', 0, 0, 0, 0)

    for _, customgroupname in pairs(groupnamelist) do
        local groupScp = string.format('FRIEND_SET_GROUPNAME("%d","%s")',tonumber(aid), customgroupname)
        _G.ui.AddContextMenuItem(subcontext, customgroupname, groupScp)
    end

    local nowgroupname = f:GetGroupName()
    if nowgroupname ~= nil and nowgroupname ~= '' and nowgroupname ~= 'None'  then
        local groupScp = string.format('FRIEND_SET_GROUPNAME("%s","%s")',aid, '')
        _G.ui.AddContextMenuItem(subcontext, _G.ScpArgMsg(_G.FRIEND_GET_GROUPNAME(_G.FRIEND_LIST_COMPLETE)), groupScp)
    end

    local newGroupScp = string.format('FRIEND_SET_GROUP("%s")',aid)
    _G.ui.AddContextMenuItem(subcontext, _G.ScpArgMsg('FriendAddNewGroup'), newGroupScp)

    local groupScp = string.format('POPUP_FRIEND_GROUP_CONTEXTMENU("%s")',aid)
    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('FriendAddGroup'), groupScp , nil, 0, 1, subcontext)

    local blockScp = string.format('friends.RequestBlock("%s")',info:GetFamilyName())
    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('FriendBlock'), blockScp)

    local deleteScp = string.format('FRIEND_EXEC_DELETE("%s")', aid)
    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('FriendDelete'), deleteScp)

    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('Cancel'), 'None')
    _G.ui.OpenContextMenu(context)
end

-- ギルド
function g.AddContextForGuild(parent, ctrl)
    local aid = parent:GetUserValue('AID')
    if aid == 'None' then
        aid = ctrl:GetUserValue('AID')
    end

    local memberInfo = _G.session.party.GetPartyMemberInfoByAID(_G.PARTY_GUILD, aid)
    local isLeader = _G.AM_I_LEADER(_G.PARTY_GUILD)
    local myAid = _G.session.loginInfo.GetAID()

    local name = memberInfo:GetName()

    local context = _G.ui.CreateContextMenu('PC_CONTEXT_MENU', name, 0, 0, 170, 100)

    if aid ~= myAid then
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('WHISPER'), string.format('ui.WhisperTo("%s")', name))
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('ReqAddFriend'), string.format('friends.RequestRegister("%s")', name))
    end

    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('ShowInfomation'), g:FuncFormat(g.ShowMemberInfo, {'"'..name..'"'}))

    if aid ~= myAid then
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('PARTY_INVITE'), string.format('PARTY_INVITE("%s")', name))
    end

    if isLeader == 1 or _G.HAS_KICK_CLAIM() then
        if g.isBanMode then
            _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('Ban'), string.format('GUILD_BAN("%s")', aid))
        end
    end

    if isLeader == 1 and aid ~= myAid then
        local mapName = _G.session.GetMapName()
        if mapName == 'guild_agit_1' then
            _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('GiveGuildLeaderPermission'), string.format('SEND_REQ_GUILD_MASTER("%s")', name))
        end
    end

    if isLeader == 1 then
        local list = _G.session.party.GetPartyMemberList(_G.PARTY_GUILD)
        if list:Count() == 1 then
            _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('Disband'), 'DESTROY_GUILD()')
        end
    else
        if aid == myAid then
            _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('GULID_OUT'), 'OUT_GUILD_CHECK()')
        end
    end

    if isLeader == 1 and aid ~= myAid then
        local summonSkl = _G.GetClass('Skill', 'Templer_SummonGuildMember')
        _G.ui.AddContextMenuItem(context, summonSkl.Name, string.format('SUMMON_GUILD_MEMBER("%s")', aid))
    end

    if isLeader == 1 and aid ~= myAid then
        local goSkl = _G.GetClass('Skill', 'Templer_WarpToGuildMember')
        _G.ui.AddContextMenuItem(context, goSkl.Name, string.format('WARP_GUILD_MEMBER("%s")', aid))
    end
    _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('Cancel'), 'None')
    _G.ui.OpenContextMenu(context)
end

-- パーティ
function g.AddContextForParty(_, _, aid)
    local myAid = _G.session.loginInfo.GetAID()

    local pcparty = _G.session.party.GetPartyInfo()
    local iamLeader = false

    if pcparty.info:GetLeaderAID() == myAid then
        iamLeader = true
    end

    local memberInfo = _G.session.party.GetPartyMemberInfoByAID(_G.PARTY_NORMAL, aid)

    -- ささやき
    local function Whisper(context)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('WHISPER'), string.format('ui.WhisperTo("%s")', memberInfo:GetName()))
    end

    -- フレンド申請
    local function ReqAddFriend(context)
        local strRequestAddFriendScp = string.format('friends.RequestRegister("%s")', memberInfo:GetName())
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('ReqAddFriend'), strRequestAddFriendScp)
    end

    -- 装備確認
    local function ShowInfomation(context)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('ShowInfomation'), g:FuncFormat(g.ShowMemberInfo, {'"'..memberInfo:GetName()..'"'}))
    end

    -- 権限委譲
    local function GiveLeaderPermission(context)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('GiveLeaderPermission'), string.format('GIVE_PARTY_LEADER("%s")', memberInfo:GetName()))
    end

    -- 追放
    local function Ban(context)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('Ban'), string.format('BAN_PARTY_MEMBER("%s")', memberInfo:GetName()))
    end

    -- 通報
    local function IndunBadPlayerReport(context)
        if _G.session.world.IsDungeon() and _G.session.world.IsIntegrateIndunServer() == true then
            local serverName = _G.GetServerNameByGroupID(_G.GetServerGroupID())
            local playerName = memberInfo:GetName()
            local scp = string.format('SHOW_INDUN_BADPLAYER_REPORT("%s", "%s", "%s")', aid, serverName, playerName)
            _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('IndunBadPlayerReport'), scp)
        end
    end

    -- 脱退
    local function WithdrawParty(context)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('WithdrawParty'), 'OUT_PARTY()')
    end

    -- 観戦
    local function Observe(context)
        local execScp = string.format('ui.Chat("/changePVPObserveTarget %d 0")', memberInfo:GetHandle())
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('Observe{PC}', 'PC',memberInfo:GetName()), execScp)
    end

    -- キャンセル
    local function Cancel(context)
        _G.ui.AddContextMenuItem(context, _G.ScpArgMsg('Cancel'), 'None')
    end

    local context = _G.ui.CreateContextMenu('CONTEXT_PARTY', '', 0, 0, 170, 100)

    if _G.session.world.IsIntegrateServer() == true and _G.session.world.IsIntegrateIndunServer() == false then
        -- 1. PVPマップ
        Observe(context)
    elseif aid == myAid then
        -- 2. 自分自身
        WithdrawParty(context)
        Cancel(context)
    elseif iamLeader == true then
        -- 3. リーダー
        Whisper(context)
        ReqAddFriend(context)
        ShowInfomation(context)
        GiveLeaderPermission(context)
        Ban(context)
        IndunBadPlayerReport(context)
        Cancel(context)
    else
        -- 4. メンバー
        Whisper(context)
        ReqAddFriend(context)
        ShowInfomation(context)
        IndunBadPlayerReport(context)
        Cancel(context)
    end

    _G.ui.OpenContextMenu(context)
end
