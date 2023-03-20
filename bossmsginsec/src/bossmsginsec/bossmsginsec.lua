local addonName = 'BOSSMSGINSEC'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    g:RegisterMsg('NOTICE_Dm_!', g.NoticeDm)
    g:RegisterMsg('NOTICE_Dm_Global_Shout', g.NoticeDmGlobalShout)
end)

function g.GetCurrentMapName()
    local mapprop = _G.session.GetCurrentMapProp()
    return mapprop:GetName()
end

function g.GetSystemTime()
    local time = _G.geTime.GetServerSystemTime()
    return string.format('%02d:%02d:%02d', time.wHour, time.wMinute, time.wSecond)
end

function g.NoticeDm(_, _, argStr, _)
    local time = g.GetSystemTime()
    local mapName = g.GetCurrentMapName()

    -- 該当地域のフィールドボスが倒れました。
    if argStr:find('LocalFieldBossDie') then
        _G.CHAT_SYSTEM('{#00e6cf}['..time..' - '..mapName..'] '..argStr)
        return
    end

    -- フィールドボス[{name}]が討伐されました
    if argStr:find('{name}DisappearFieldBoss') then
        _G.CHAT_SYSTEM('{#00e6cf}['..time..' - '..mapName..'] '..argStr)
        return
    end
end

function g.NoticeDmGlobalShout(_, _, argStr, _)
    local time = g.GetSystemTime()

    -- 間もなくフィールドボスが登場します。 : {Name}
    if argStr:find('FieldBoss{Name}WillAppear') then
        _G.CHAT_SYSTEM('{#00e6cf}['..time..'] '..argStr)
        return
    end

    -- どこかでフィールドボス[{name}]が出現したようです
    if argStr:find('{name}AppearFieldBoss1') then
        _G.CHAT_SYSTEM('{#00e6cf}['..time..'] '..argStr)
        return
    end

    -- どこかでフィールドボス[{name}]が出現したようです
    if argStr:find('{name}AppearFieldBoss2') then
        _G.CHAT_SYSTEM('{#00e6cf}['..time..'] '..argStr)
        return
    end

    -- 魔法結社の議事堂にフィールドボス[{name}]が登場しました
    if argStr:find('AppearFieldBoss_ep14_2_d_castle_3{name}') then
        _G.CHAT_SYSTEM('{#00e6cf}['..time..'] '..argStr)
        return
    end

    -- {name}に追従者モンスター達が出現しました
    if argStr:find('AppearPCMonster{name}') then
        _G.CHAT_SYSTEM('{#00e6cf}['..time..'] '..argStr)
        return
    end

    -- 追従者が討伐されました：「{name}」
    if argStr:find('{name}DisappearPCMonster') then
        _G.CHAT_SYSTEM('{#00e6cf}['..time..'] '..argStr)
        return
    end
end
