local addonName = 'TRANSLATOR'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]
local acutil = require('acutil')

print('translator')
--dofile('C:/Users/achto/Documents/GitHub/TOSAddon_Private/translator/src/translator/translator.lua'); _G['ADDONS']['MENIMANI']['TRANSLATOR']:LoadSettings()
g.settings = {
    transrate = {
        normal = true,
        shout = true,
        party = true,
        guild = true,
        whisper = true,
        system = false,
        fight = false
    },
    lang = 'JA',
}

g.DeepL = g.DeepL or {}
function g.DeepL.Transrate(text, lang, chat_prefix)
    -- DeepL API実行は、m2TranslatorServiceに委譲する。
    local fileKey = g.DeepL.createFileKey()

    -- {}とdicIDは、翻訳対象外文字として指定する
    -- dicIDを含むとjsonデコード時に誤作動を起こすため、dic開始文字の@をエスケープしておく
    local escaped_text = text:gsub('{', '<pre>{'):gsub('}', '}</pre>'):gsub('@dicID_%^%*%$', '<pre>＠dicID_^*$'):gsub('%$%*%^', '$*^</pre>')
    local request = {
        target_lang = lang,
        text = {
            escaped_text
        },
        tag_handling = 'xml',
        ignore_tags = {
            'pre'
        }
    }
    -- m2TranslatorServiceの翻訳キューに入れる
    local inputFileName = string.format('../addons/%s/watch/input_%s.json', g.addonNameLower, fileKey)
    acutil.saveJSON(inputFileName, request)

    -- m2TranslatorServiceの翻訳結果が格納される。※格納されるまではファイルなし
    local outputFileName = string.format('../addons/%s/watch/output_%s.json', g.addonNameLower, fileKey)
    g.DeepL.outputWatcher(outputFileName, lang, chat_prefix, text, 0)
end

function g.DeepL.outputWatcher(fileName, lang, chat_prefix, original_text, attempts)
    local response, err = acutil.loadJSON(fileName, {})
    if err then
        if attempts < 60 then
            attempts = attempts + 1
            g:ReserveScript(g.DeepL.outputWatcher, {'"'..fileName..'"', '"'..lang..'"', '"'..chat_prefix..'"', '"'..original_text..'"', attempts}, 0.5)
        end
        return
    end

    if response.translations == nil then
        -- 翻訳失敗
        return
    end

    -- 翻訳完了時処理
    local translation = response.translations[1]
    local from_lang = translation.detected_source_language
    local transrated_text = (translation.text):gsub('<pre>', ''):gsub('</pre>', ''):gsub('＠dicID_%^%*%$', '@dicID_^*$'):gsub('%s*{', '{'):gsub('}%s*', '}')
    local msg = string.lower('[' .. from_lang .. '] ') .. original_text .. ' => ' .. string.lower('[' .. lang .. '] ')  .. transrated_text
    acutil.uiChat_OLD(chat_prefix .. msg)
end

local function createTimeGetter()
    local lastTimestamp = nil
    local counter = 0

    return function()
        local t = os.date('*t')
        local timestamp = string.format('%04d%02d%02d%02d%02d%02d', t.year, t.month, t.day, t.hour, t.min, t.sec)

        if timestamp == lastTimestamp then
            counter = counter + 1
        else
            counter = 1
            lastTimestamp = timestamp
        end

        return timestamp .. '_' .. string.format('%03d', counter)
    end
end
g.DeepL.createFileKey = createTimeGetter()

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    g:slashCommand('/translator', g.Command)

    g:LoadSettings()
    g:SaveSettings()
end)

function g.Command(command)
    if #command == 0 then
        return
    end

    local cmd = table.remove(command, 1)

    if g.settings.transrate[cmd] ~= nil and #command > 0 then
        --チャット種別の選択
        local arg = table.remove(command, 1)
        --オンオフ
        if arg == 'on' then
            g.settings.transrate[cmd] = true
            _G.CHAT_SYSTEM(string.format('[Translator] %s is enable', cmd))
            g:SaveSettings()
            return
        elseif arg == 'off' then
            g.settings.transrate[cmd] = false
            _G.CHAT_SYSTEM(string.format('[Translator] %s is disable', cmd))
            g:SaveSettings()
            return
        end
    end
    _G.CHAT_SYSTEM('[Transrator] Invalid Command')
end

function g.TransCommand(chat_prefix, command)
    if #command == 0 then
        return
    end

    local lang = table.remove(command, 1)
    local msg = table.concat(command, ' ')

    g.DeepL.Transrate(msg, lang, chat_prefix)
end

function acutil.onUIChat(msg)
    local words = {}
    for word in msg:gmatch('%S+') do
        table.insert(words, word)
    end

    local chatType = table.remove(words, 1)

    local target
    if g:Contains({'/w', '/f'}, chatType) then
        target = table.remove(words, 1)
    end

    local cmd
    if g:Contains({'/s', '/y', '/p', '/g', '/gn','/w', '/f'}, chatType) then
        cmd = table.remove(words, 1)
    elseif acutil.slashCommands[chatType] ~= nil then
        -- 一般チャットの場合、チャットタイプが付与されない
        cmd = chatType
    end

    if cmd == '/trans' then
        local chat_prefix = ''
        if chatType ~= nil then
            chat_prefix = chat_prefix .. chatType .. ' '
        end
        if target ~= nil then
            chat_prefix = chat_prefix .. target .. ' '
        end

        g.TransCommand(chat_prefix, words)
        return
    end

    acutil.uiChat_OLD(msg)

    local fn = acutil.slashCommands[cmd]
    if (fn ~= nil) then
        acutil.closeChat()
        return fn(words)
    end

end
_G.ui.Chat = acutil.onUIChat

-- チャット右クリック＆ダブルクリックイベント書き換え
function _G.REQ_TRANSLATE_TEXT(frameName, gbName, ctrlName)
    local frame = _G.ui.GetFrame(frameName)
    if frame == nil then
        return
    end

    local gb  = _G.GET_CHILD_RECURSIVELY(frame, gbName)
    if gb== nil then
        return
    end

    local size = _G.session.ui.GetMsgInfoSize(gbName)
    local cutting_table = _G.SCR_STRING_CUT(ctrlName, '_')
    local msgId	= cutting_table[#cutting_table]
    local pc = _G.GetMyPCObject()
    if pc == nil then
        return
    end

    local inputStr
    for i = 0, size - 1 do
        local clusterinfo = _G.session.ui.GetChatMsgInfo(gbName, i)
        if clusterinfo == nil then return 0 end
        if tostring(msgId) == clusterinfo:GetMsgInfoID() then
            inputStr = clusterinfo:GetMsg()
            if pc.Name == clusterinfo:GetCommanderName() then
                _G.ui.SysMsg(_G.ClMsg('CanNotTranslateMyChat'))
                return
            end
        end
    end

    g.DeepL.TransrateForChatFrame(inputStr, g.settings.lang, frameName, gbName, msgId)
end

function g.DeepL.TransrateForChatFrame(text, lang, frameName, gbName, msgId)
    -- DeepL API実行は、m2TranslatorServiceに委譲する。
    local fileKey = g.DeepL.createFileKey()

    -- {}とdicIDは、翻訳対象外文字として指定する
    -- dicIDを含むとjsonデコード時に誤作動を起こすため、dic開始文字の@をエスケープしておく
    local escaped_text = text:gsub('{', '<pre>{'):gsub('}', '}</pre>'):gsub('@dicID_%^%*%$', '<pre>＠dicID_^*$'):gsub('%$%*%^', '$*^</pre>')
    local request = {
        target_lang = lang,
        text = {
            escaped_text
        },
        tag_handling = 'xml',
        ignore_tags = {
            'pre'
        }
    }
    -- m2TranslatorServiceの翻訳キューに入れる
    local inputFileName = string.format('../addons/%s/watch/input_%s.json', g.addonNameLower, fileKey)
    acutil.saveJSON(inputFileName, request)

    -- m2TranslatorServiceの翻訳結果が格納される。※格納されるまではファイルなし
    local outputFileName = string.format('../addons/%s/watch/output_%s.json', g.addonNameLower, fileKey)
    g.DeepL.outputWatcherForChatFrame(outputFileName, lang, frameName, gbName, msgId, text, 0)
end

function g.DeepL.outputWatcherForChatFrame(fileName, lang, frameName, gbName, msgId, original_text, attempts)
    local response, err = acutil.loadJSON(fileName, {})
    if err then
        if attempts < 60 then
            attempts = attempts + 1
            g:ReserveScript(g.DeepL.outputWatcherForChatFrame, {'"'..fileName..'"', '"'..lang..'"', '"'..frameName..'"', '"'..gbName..'"', msgId, '"'..original_text..'"', attempts}, 0.5)
        end
        return
    end

    if response.translations == nil then
        -- 翻訳失敗
        return
    end

    -- 翻訳完了時処理
    local translation = response.translations[1]
    local from_lang = translation.detected_source_language
    local transrated_text = (translation.text):gsub('<pre>', ''):gsub('</pre>', ''):gsub('＠dicID_%^%*%$', '@dicID_^*$'):gsub('%s*{', '{'):gsub('}%s*', '}')
    local msg = string.lower('[' .. from_lang .. '] ') .. original_text .. ' => ' .. string.lower('[' .. lang .. '] ')  .. transrated_text
    _G.SET_TRANSLATE(msg, frameName, gbName, msgId)
end
