_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI']['M2UTIL'] = _G['ADDONS']['MENIMANI']['M2UTIL'] or {}

local M2UTIL = _G['ADDONS']['MENIMANI']['M2UTIL']
local acutil = require('acutil')

local globalFuncList = {}
local function GFuncReset()
    for i = 1, #globalFuncList do
        _G[globalFuncList[i]] = nil
    end
    globalFuncList = {}
end

M2UTIL.OnInit = function(addonName, onInitFunc)
    _G['ADDONS'] = _G['ADDONS'] or {}
    _G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
    _G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

    local g = _G['ADDONS']['MENIMANI'][addonName]
    g.addonName = addonName
    g.addonNameLower = addonName:lower()

    _G[addonName..'_ON_INIT'] = function(addon, frame)
        g.addon = g.addon or addon
        g.frame = g.frame or frame
        addon:RegisterMsg('GAME_START', addonName..'_START')
    end

    _G[addonName..'_START'] = function()
        if _G.ADDONS.MENIMANI.BAN.isBan() then
            return
        end
        onInitFunc(g.addon, g.frame)
    end

    setmetatable(g, {__index = M2UTIL})
    return g
end

function M2UTIL.SaveSettings(self, fileName)
    local settingsFileLoc = string.format('../addons/%s/%s.json', self.addonNameLower, fileName or 'settings')
    self.settings = self.settings or {}
    acutil.saveJSON(settingsFileLoc, self.settings)
end

function M2UTIL.LoadSettings(self, fileName)
    local settingsFileLoc = string.format('../addons/%s/%s.json', self.addonNameLower, fileName or 'settings')
    self.settings = self.settings or {}
    local t, err = acutil.loadJSON(settingsFileLoc, self.settings)
    if err then
        _G.CHAT_SYSTEM(string.format('[%s] cannot load setting files', self.addonNameLower))
    else
        self.settings = t
    end
end

function M2UTIL.GFunc(self, func)
    local globalFuncName = tostring(func):gsub('function: ', self.addonName)
    table.insert(globalFuncList, globalFuncName)
    _G[globalFuncName] = _G[globalFuncName] or func
    return globalFuncName
end

function M2UTIL.setupHook(self, oldFuncName, func)
    self.oldFunc = self.oldFunc or {}
    self.oldFunc[oldFuncName] = self.oldFunc[oldFuncName] or _G[oldFuncName]
    _G[oldFuncName] = func
end

function M2UTIL.slashCommand(_, cmd, func)
    acutil.slashCommand(cmd, func)
end

function M2UTIL.ReserveScript(self, funcTbl, sec)
    local func = table.remove(funcTbl, 1)
    local args = table.concat(funcTbl)
    _G.ReserveScript(self.GFunc(func)..'('..args..')', sec)
end

function M2UTIL.Contains(_, arr, word)
    for i = 1, #arr do
        if arr[i] == word then
            return true
        end
    end
    return false
end

-- 最速で読み込む必要がある
M2UTIL.OnInit('__M2UTIL', function()
    GFuncReset()
end)
