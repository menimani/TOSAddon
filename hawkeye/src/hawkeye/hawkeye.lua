local addonName = 'HAWKEYE'
local addonNameLower = addonName:lower()

_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]
local acutil = require('acutil')

g.settingsFileLoc = '../addons/'..addonNameLower..'/settings.json'

g.settings = {
    enable = true,
    window = 1,
    position = {
        x = 500,
        y = 500
    },
    campos = {
        x = 45,
        y = 38,
        z = 236
    },
    dismaps = {}
}

g.static = {
    min = {
        x = 0,
        y = -89,
        z = 50
    },
    max = {
        x = 360,
        y = 90,
        z = 1500
    },
    default = {
        x = 45,
        y = 38,
        z = 236
    }
}

_G[addonName..'_ON_INIT'] = function(addon, frame)
    g.addon = g.addon or addon
    g.frame = g.addon or frame

    g.GlobalFunction()
    addon:RegisterMsg('GAME_START', addonName..'_INIT')
end

function g.Init()
    if _G.ADDONS.MENIMANI.BAN.isBan() then
        return
    end

    local frame = ui.GetFrame(addonNameLower)
    frame:ShowWindow(0)

    -- PVP地域アドオン無効
    if IsPVPField() == 1 or IsPVPServer() == 1 then
        return
    end

    local map = session.GetCurrentMapProp():GetClassName()
    if g.Contains(g.settings.dismaps, map) then
        return
    end

    acutil.slashCommand('/hawkeye', g.Command)
    acutil.slashCommand('/hawk', g.Command)

    g.LoadSettings()

    if g.settings.enable then
        frame:ShowWindow(1)
    end

    if not g.settings.window then
        g.settings.window = 1
        g.SaveSettings()
    end

    -- ドラッグ
    frame:EnableMove(1)
    frame:EnableHitTest(1)
    frame:SetEventScript(ui.LBUTTONUP, addonName..'_END_DRAG')

    frame:Move(g.settings.position.x, g.settings.position.y)
    frame:SetOffset(g.settings.position.x, g.settings.position.y)

    g.InitFrame(frame)
    g.InitWindow()

    ReserveScript(addonName..'_CAMERA_UPDATE()', 0.5)
end

-- 引数（文字列）で渡す関数を一括で定義する
function g.GlobalFunction()
    _G[addonName..'_COMMAND'] = g.Command
    _G[addonName..'_INIT'] = g.Init

    _G[addonName..'_CAMERA_UPDATE'] = g.CameraUpdate
    _G[addonName..'_CAMERA_UPDATE_XY'] = g.CameraUpdateXY
    _G[addonName..'_CAMERA_UPDATE_Z'] = g.CameraUpdateZ

    _G[addonName..'_RESET'] = g.Reset
    _G[addonName..'_RESIZE_WINDOW'] = g.ResizeWindow
    _G[addonName..'_END_DRAG'] = g.EndDrag
end

function g.Command(command)
    local cmd = ''
    if #command > 0 then
        cmd = table.remove(command, 1)
    else
        g.ToggleFrame()
        return
    end
    if cmd == 'x' or cmd == 'y' or cmd == 'z' then
        local scale = tonumber(table.remove(command, 1))
        if type(scale) == 'number' then
            if scale >= g.static.min[cmd] and scale <= g.static.max[cmd] then
                local frame = ui.GetFrame(addonNameLower)
                local scr = frame:GetChild('n_scr'..cmd:upper())
                tolua.cast(scr, 'ui::CSlideBar')
                g.settings.campos[cmd] = scale
                scr:SetLevel(g.settings.campos[cmd])
                g.SaveSettings()
                g.CameraUpdate()
            else
                CHAT_SYSTEM('Invalid '..cmd..' level. Minimum is '..g.static.min[cmd]..' and maximum is '..g.static.max[cmd]..'.')
            end
        end
        return
    end
    if cmd == 'dismap' then
        local map = session.GetCurrentMapProp():GetClassName()
        if not g.Contains(g.settings.dismaps, map) then
            table.insert(g.settings.dismaps, map)
        end
        g.SaveSettings()
        return
    end
    if cmd == 'reset' then
        g.Reset()
        return
    end
end

-- カメラ座標更新
function g.CameraUpdate()
    g.CameraUpdateXY()
    g.CameraUpdateZ()
end

-- カメラ座標更新(XY軸)
function g.CameraUpdateXY()
    local frame = ui.GetFrame(addonNameLower)
    local labelX = frame:GetChild('n_labelX')
    local scrX = frame:GetChild('n_scrX')
    local labelY = frame:GetChild('n_labelY')
    local scrY = frame:GetChild('n_scrY')
    tolua.cast(scrX, 'ui::CSlideBar')
    tolua.cast(scrY, 'ui::CSlideBar')

    g.settings.campos.x = scrX:GetLevel()
    g.settings.campos.y = scrY:GetLevel()

    labelX:SetText('X座標('..(g.settings.campos.x)..'):')
    labelY:SetText('Y座標('..(g.settings.campos.y)..'):')

    camera.CamRotate(g.settings.campos.y, g.settings.campos.x)
    g.SaveSettings()
end

-- カメラ座標更新(Z軸)
function g.CameraUpdateZ()
    local frame = ui.GetFrame(addonNameLower)
    local labelZ = frame:GetChild('n_labelZ')
    local scrZ = frame:GetChild('n_scrZ')
    tolua.cast(scrZ, 'ui::CSlideBar')

    g.settings.campos.z = scrZ:GetLevel()

    labelZ:SetText('Z座標('..(g.settings.campos.z)..'):')

    camera.CustomZoom(g.settings.campos.z)
    g.SaveSettings()
end

-- フレーム初期化
function g.InitFrame(frame)
    local frame = ui.GetFrame(addonNameLower)
    frame:SetSkinName('box_glass')

    local titleText = frame:CreateOrGetControl('richtext', 'n_titleText', 0, 0, 0, 0)
    titleText:SetOffset(10,10)
    titleText:SetFontName('white_16_ol')
    titleText:SetText('/hawkeye or /hawk')

    local btnReset = frame:CreateOrGetControl('button', 'n_resize', 236, 4, 30, 30)
    btnReset:SetText('{@sti7}{s16}W')
    btnReset:SetEventScript(ui.LBUTTONUP, addonName..'_RESIZE_WINDOW')

    local btnReset = frame:CreateOrGetControl('button', 'n_reset', 266, 4, 30, 30)
    btnReset:SetText('{@sti7}{s16}R')
    btnReset:SetEventScript(ui.LBUTTONUP, addonName..'_RESET')

    local labelX = frame:CreateOrGetControl('richtext', 'n_labelX', 0, 0, 0, 0)
    labelX:SetOffset(20,40)
    labelX:SetFontName('white_14_ol')
    labelX:SetText('X座標('..(g.settings.campos.x)..'):')

    local labelY = frame:CreateOrGetControl('richtext', 'n_labelY', 0, 0, 0, 0)
    labelY:SetOffset(20,70)
    labelY:SetFontName('white_14_ol')
    labelY:SetText('Y座標('..(g.settings.campos.y)..'):')

    local labelZ = frame:CreateOrGetControl('richtext', 'n_labelZ', 0, 0, 0, 0)
    labelZ:SetOffset(20,100)
    labelZ:SetFontName('white_14_ol')
    labelZ:SetText('Z座標('..(g.settings.campos.z)..'):')

    local scrX = frame:CreateOrGetControl('slidebar', 'n_scrX', 120, 34, 180, 30)
    tolua.cast(scrX, 'ui::CSlideBar')
    scrX:SetMinSlideLevel(g.static.min.x)
    scrX:SetMaxSlideLevel(g.static.max.x-1)
    scrX:SetLevel(g.settings.campos.x)

    local scrY = frame:CreateOrGetControl('slidebar', 'n_scrY', 120, 64, 180, 30)
    tolua.cast(scrY, 'ui::CSlideBar')
    scrY:SetMinSlideLevel(g.static.min.y)
    scrY:SetMaxSlideLevel(g.static.max.y-1)
    scrY:SetLevel(g.settings.campos.y)

    local scrZ = frame:CreateOrGetControl('slidebar', 'n_scrZ', 120, 94, 180, 30)
    tolua.cast(scrZ, 'ui::CSlideBar')
    scrZ:SetMinSlideLevel(g.static.min.z)
    scrZ:SetMaxSlideLevel(g.static.max.z)
    scrZ:SetLevel(g.settings.campos.z)
end

-- カメラ座標リセット
function g.Reset()
    local frame = ui.GetFrame(addonNameLower)
    local scrX = frame:GetChild('n_scrX')
    local scrY = frame:GetChild('n_scrY')
    local scrZ = frame:GetChild('n_scrZ')
    tolua.cast(scrX, 'ui::CSlideBar')
    tolua.cast(scrY, 'ui::CSlideBar')
    tolua.cast(scrZ, 'ui::CSlideBar')

    g.settings.campos.x = g.static.default.x
    g.settings.campos.y = g.static.default.y
    g.settings.campos.z = g.static.default.z
    scrX:SetLevel(g.static.default.x)
    scrY:SetLevel(g.static.default.y)
    scrZ:SetLevel(g.static.default.z)

    g.CameraUpdate()
end

-- ウィンドウサイズ初期化
function g.InitWindow()
    local frame = ui.GetFrame(addonNameLower)
    if g.settings.window == 1 then
        frame:Resize(300,40)
    else
        frame:Resize(300,120)
    end
end

-- ウィンドウサイズ変更(Wボタン押下用)
function g.ResizeWindow()
    local frame = ui.GetFrame(addonNameLower)
    if g.settings.window == 0 then
        g.settings.window = 1
        frame:Resize(300,40)
    else
        g.settings.window = 0
        frame:Resize(300,120)
    end
    g.SaveSettings()
end

-- フレーム場所保存処理
function g.EndDrag()
    local frame = ui.GetFrame(addonNameLower)
    g.settings.position.x = frame:GetX()
    g.settings.position.y = frame:GetY()
    g.SaveSettings()
end

-- フレームの表示切り替え
function g.ToggleFrame()
    local frame = ui.GetFrame(addonNameLower)
    if g.settings.enable == true then
        frame:ShowWindow(0)
        g.settings.enable = false
    else
        frame:ShowWindow(1)
        g.settings.enable = true
    end
end

-- 設定保存
function g.SaveSettings()
    acutil.saveJSON(g.settingsFileLoc, g.settings)
end

-- 設定読込
function g.LoadSettings()
    local t, err = acutil.loadJSON(g.settingsFileLoc, g.settings)
    if err then
        -- 設定ファイル読み込み失敗時処理
        _G.CHAT_SYSTEM(string.format('[%s] cannot load setting files', addonNameLower))
    else
        -- 設定ファイル読み込み成功時処理
        g.settings = t
    end
end

function g.Contains(arr, word)
    for i = 1, #arr do
        if arr[i] == word then
            return true
        end
    end
    return false
end