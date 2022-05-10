local currentVersion = 1.03

_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI']['BAN'] = _G['ADDONS']['MENIMANI']['BAN'] or {}

local g = _G['ADDONS']['MENIMANI']['BAN']
g.loadedVersion = g.loadedVersion or 0
if g.loadedVersion < currentVersion then
    local banGuild = {
        ['120791661042947'] = true, -- 鬼瓦海賊団
    }
    local banUser = {
        ['76561199003041695'] = true, -- 桜華夢翔
        ['76561199037802529'] = true, -- 桜華夢翔サブ(桜華夢翔)
        ['76561199005792863'] = true, -- 桜華夢翔サブ(arawagino)
        ['76561199031235017'] = true, -- 桜華夢翔サブ(ポイズン)
        ['76561199006525063'] = true, -- 桜華夢翔サブ(モブサイコ100)
        ['76561199001360031'] = true, -- アボカドディップ
        ['76561198061046959'] = true, -- ぴえろ(旧：嘆きの道化師)
        ['76561199005766201'] = true, -- ー舞折
        ['76561198097660617'] = true, -- 路地うさ
        ['76561198843189363'] = true, -- あざらしはうす
        ['76561198294814767'] = true, -- おかちゃんず
        ['76561198372617664'] = true, -- ラリア
        ['76561199006065458'] = true, -- NoLife(旧：Patas)
        ['76561199231327410'] = true, -- NoLifeサブ(YesLife)
        ['76561198888201990'] = true, -- NoLifeサブ(のららいふ)
    }
    g.banGuild = banGuild
    g.banUser = banUser
    g.loadedVersion = currentVersion

    function g.isBan()
        local function bg()
            local guild = _G.GET_MY_GUILD_INFO()
            return guild ~= nil and g.banGuild[guild.info:GetPartyID()] == true
        end
        local function bu()
            return g.banUser[_G.session.loginInfo.GetAID()] == true
        end
        return bg() or bu()
    end
end