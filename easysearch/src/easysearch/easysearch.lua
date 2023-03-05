local addonName = 'EASYSEARCH'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    g:setupEvent('MARKET_BUYMODE', g.MarketOpen)
    g:setupEvent('ON_OPEN_MARKET', g.MarketOpen)
    g:setupEvent('MARKET_CLOSE', g.MarketClose)
end)

function g.MarketOpen()
    _G.INVENTORY_SET_CUSTOM_RBTNDOWN(g:GFunc(g.InvRightClick))
end

function g.MarketClose()
    _G.INVENTORY_SET_CUSTOM_RBTNDOWN('None')
end

function g.InvRightClick(itemObj)
    local frame = _G.ui.GetFrame('market')
    local market_search = _G.GET_CHILD_RECURSIVELY(frame, 'itemSearchSet')
    local searchEdit = _G.GET_CHILD_RECURSIVELY(market_search, 'searchEdit')

    -- タグを無視した60バイト以下の文字列で検索
    local name = _G.dictionary.ReplaceDicIDInCompStr(itemObj.Name)
    name = name:gsub('{.-}', '')
    name = name:sub(1, 60)
    searchEdit:SetText(name)

    _G.MARKET_FIND_PAGE(frame)
end
