_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI']['M2UTIL'] = _G['ADDONS']['MENIMANI']['M2UTIL'] or {}

local M2UTIL = _G['ADDONS']['MENIMANI']['M2UTIL']
local acutil = require('acutil')

--[[
    ■属性
    クラス変数

    ■変数内容
    GFuncで登録した関数リスト

    ■ライフサイクル
    ロード時初期化
--]]
local globalFuncList = {}

--[[
    ■属性
    クラス関数

    ■処理内容
    GFuncで登録した関数リスト初期化
--]]
local function GFuncReset()
    for i = 1, #globalFuncList do
        _G[globalFuncList[i]] = nil
    end
    globalFuncList = {}
end

--[[
    ■属性
    コンストラクタ

    ■処理内容
    アドオン登録

    ■呼出方法
    _G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, onInitFunc)

    ■引数
    addonName  アドオン名
    onInitFunc アドオン毎の初期化処理

    ■返値
    アドオン用インスタンス
--]]
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
            _G.CHAT_SYSTEM('['..g.addonNameLower..'] you pissed me off')
            return
        end
        _G.CHAT_SYSTEM('['..g.addonNameLower..'] is loaded')
        onInitFunc(g.addon, g.frame)
    end

    setmetatable(g, {__index = M2UTIL})
    return g
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    設定保存

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:SaveSettings(settingsName)

    ■引数
    settingsName 任意 設定名 初期値「settings」
--]]
function M2UTIL.SaveSettings(self, settingsName)
    settingsName = settingsName or 'settings'
    local fileName = string.format('../addons/%s/%s.json', self.addonNameLower, settingsName)
    self[settingsName] = self[settingsName] or {}
    acutil.saveJSON(fileName, self[settingsName])
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    設定読込

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:LoadSettings(settingsName)

    ■引数
    settingsName 任意 設定名 初期値「settings」

    ■破壊処理内容
    g[settingsName]に設定ファイルの内容を読込
--]]
function M2UTIL.LoadSettings(self, settingsName)
    settingsName = settingsName or 'settings'
    local fileName = string.format('../addons/%s/%s.json', self.addonNameLower, settingsName)
    self[settingsName] = self[settingsName] or {}
    local t, err = acutil.loadJSON(fileName, self[settingsName])
    if err then
        _G.CHAT_SYSTEM(string.format('[%s] cannot load setting files', self.addonNameLower))
    else
        self[settingsName] = t
    end
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    グローバル関数の名称衝突を回避する。
    グローバル関数（_G直下）で実装する必要がある場合に使用。

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:GFunc(func)

    ■引数
    func _G直下配置予定の関数

    ■返値
    「アドオン名 + 16桁の16進数」 形式の関数名
    ※ _G[globalFuncName]で参照
--]]
function M2UTIL.GFunc(self, func)
    local globalFuncName = tostring(func):gsub('function: ', self.addonName)
    table.insert(globalFuncList, globalFuncName)
    _G[globalFuncName] = func
    return globalFuncName
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    関数上書き

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:setupHook(oldFuncName, func)

    ■引数
    oldFuncName 元関数名
    func        上書き内容
--]]
function M2UTIL.setupHook(self, oldFuncName, func)
    self.oldFunc = self.oldFunc or {}
    self.oldFunc[oldFuncName] = self.oldFunc[oldFuncName] or _G[oldFuncName]
    _G[oldFuncName] = func
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    関数実行後にイベント発火

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:setupEvent(eventName, func)

    ■引数
    eventName 元関数名
    func      イベントに紐づける関数
--]]
function M2UTIL.setupEvent(self, eventName, func)
    self:setupHook(eventName, function(...)
        local result = self.oldFunc[eventName](...)
        _G.imcAddOn.BroadMsg(eventName)
        return result
    end)
    self:RegisterMsg(eventName, func)
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    イベント登録

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:RegisterMsg(eventName, func)

    ■引数
    eventName イベント名
    func      イベントに紐づける関数
--]]
function M2UTIL.RegisterMsg(self, eventName, func)
    local funcName = self:GFunc(func)
    local eventFuncName = eventName .. '_' .. funcName
    table.insert(globalFuncList, eventFuncName)
    _G[eventFuncName] = _G[funcName]
    self.addon:RegisterMsg(eventName, eventFuncName)
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    イベント解除　※登録時の関数

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:UnRegisterMsg(eventName, func)

    ■引数
    eventName イベント名
    func      イベントに紐づけたときの関数（関数のIDが変わってはならない）
--]]
function M2UTIL.UnRegisterMsg(self, eventName, func)
    local funcName = self:GFunc(func)
    local eventFuncName = eventName .. '_' .. funcName
    table.insert(globalFuncList, eventFuncName)
    _G[eventFuncName] = function () end
    self.addon:RegisterMsg(eventName, eventFuncName)
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    スラッシュコマンド登録

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:slashCommand(cmd, func)

    ■引数
    cmd  スラッシュコマンド
    func スラッシュコマンド用処理
--]]
function M2UTIL.slashCommand(_, cmd, func)
    acutil.slashCommand(cmd, func)
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    関数実行文字列可

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:FuncFormat(func, args)

    ■引数
    func 関数
    args 引数　{ 数値引数, "'文字列引数'" }
--]]
function M2UTIL.FuncFormat(self, func, args)
    return string.format('%s(%s)', self:GFunc(func), table.concat(args, ','))
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    遅延実行

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:ReserveScript(func, args, sec)

    ■引数
    func 遅延対象の関数
    args 引数　{ 数値引数, "'文字列引数'" }
    sec  何秒後に実行するか
--]]
function M2UTIL.ReserveScript(self, func, args, sec)
    _G.ReserveScript(self:FuncFormat(func, args), sec)
end

--[[
    ■属性
    インスタンス関数

    ■処理内容
    配列検査処理

    ■呼出方法
    local g = _G['ADDONS']['MENIMANI'][addonName]
    g:Contains(arr, word)

    ■引数
    arr  検査対象配列
    word 検査対象文字列

    ■返値
    存在: true
    存在しない: false
--]]
function M2UTIL.Contains(_, arr, word)
    for i = 1, #arr do
        if arr[i] == word then
            return true
        end
    end
    return false
end

--[[
    LOG関連処理
    各アドオンデフォルトではログ出力なし
    ログレベルは下記のように設定変更
    _G.ADDONS.MENIMANI.ADDONNAME.loglevel = 'debug'
    _G.ADDONS.MENIMANI.ADDONNAME.loglevel = 'info'
    _G.ADDONS.MENIMANI.ADDONNAME.loglevel = 'warn'
    _G.ADDONS.MENIMANI.ADDONNAME.loglevel = 'error'
]]
M2UTIL.loglevel = 'none'

local function log(color, text)
    print(color..tostring(text):gsub('^\t+', ''):gsub('\n\t+$', ''):gsub('(\n)\t+', '%1'))
end

function M2UTIL.debug(self, text)
    local LogTarget = {
        'debug'
    }
    if M2UTIL:Contains(LogTarget, self.loglevel) == false then
        return
    end
    log('{#696969}', '['..self.addonNameLower..'] '..text)
end

function M2UTIL.info(self, text)
    local LogTarget = {
        'debug',
        'info'
    }
    if M2UTIL:Contains(LogTarget, self.loglevel) == false then
        return
    end
    log('{#ffffff}', '['..self.addonNameLower..'] '..text)
end

function M2UTIL.warn(self, text)
    local LogTarget = {
        'debug',
        'info',
        'warn'
    }
    if M2UTIL:Contains(LogTarget, self.loglevel) == false then
        return
    end
    log('{#cfe600}', '['..self.addonNameLower..'] '..text)
end

function M2UTIL.error(self, text)
    local LogTarget = {
        'debug',
        'info',
        'warn',
        'error'
    }
    if M2UTIL:Contains(LogTarget, self.loglevel) == false then
        return
    end
    log('{#cc0000}', '['..self.addonNameLower..'] '..text)
end

--[[
    ■処理内容
    当アドオン初期化処理
    最速で読み込む必要がある
--]]
M2UTIL.OnInit('__M2UTIL', function()
    GFuncReset()
end)
