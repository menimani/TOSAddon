local addonName = 'HAWKEYE'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

-- 定数
g.static = {
    min = {
        x = 0,
        y = -89,
        z = 50
    },
    max = {
        x = 359,
        y = 89,
        z = 1500
    },
    default = {
        x = 45,
        y = 38,
        z = 236
    }
}

-- 初期設定
g.settings = {
    -- 表示設定（1:表示、0:非表示）
    display = {
        -- 全体表示設定
        frame = 1,
        -- スライドバー表示設定
        slide = 1
    },
    -- フレーム座標
    position = {
        x = 500,
        y = 500
    },
    -- 最新カメラ座標
    campos = {
        x = g.static.default.x,
        y = g.static.default.y,
        z = g.static.default.z
    },
    dismaps = {}
}

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
    g.ShowFrame(0)

    g:LoadSettings()

    -- PVP地域アドオン無効
    if _G.IsPVPField() == 1 or _G.IsPVPServer() == 1 then
        return
    end

    -- 無効設定マップの場合
    local map = _G.session.GetCurrentMapProp():GetClassName()
    if g:Contains(g.settings.dismaps, map) then
        return
    end

    g:slashCommand('/hawkeye', g.Command)
    g:slashCommand('/hawk', g.Command)

    g.InitFrame()

    g.ShowFrame(g.settings.display.frame)
    g.ShowSlide(g.settings.display.slide)

    g:setupHook('FULLBLACK_RESIZE', function(...)
        g.oldFunc['FULLBLACK_RESIZE'](...)
        g:ReserveScript(g.CameraUpdate, {}, 0.5)
    end)

    g:ReserveScript(g.CameraUpdate, {}, 0.5)
end)

function g.Command(command)
    local cmd
    if #command > 0 then
        cmd = table.remove(command, 1)
    else
        g.ToggleFrame()
        return
    end

    if cmd == 'x' or cmd == 'y' or cmd == 'z' then
        local scale = tonumber(table.remove(command, 1))
        if type(scale) == 'number' then
            local min = g.static.min[cmd]
            local max = g.static.max[cmd]
            if min <= scale and scale <= max then
                g.settings.campos[cmd] = scale
                local campos = g.settings.campos
                g.SetSlideLevel(campos.x, campos.y, campos.z)
                g.CameraUpdate()
            else
                _G.CHAT_SYSTEM('Invalid '..cmd..' level. Minimum is '..min..' and maximum is '..max..'.')
            end
        end
        return
    end

    if cmd == 'dismap' then
        local map = _G.session.GetCurrentMapProp():GetClassName()
        if not g:Contains(g.settings.dismaps, map) then
            table.insert(g.settings.dismaps, map)
        end
        g:SaveSettings()
        return
    end

    if cmd == 'reset' then
        g.CameraReset()
        return
    end
end

-- カメラ座標更新
function g.CameraUpdate()
    local campos = g.settings.campos
    _G.camera.CamRotate(campos.y, campos.x)
    _G.camera.CustomZoom(campos.z)
end

-- フレーム初期化
function g.InitFrame()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    frame:SetSkinName('box_glass')

    -- ドラッグ可設定
    frame:EnableMove(1)
    frame:EnableHitTest(1)
    frame:SetEventScript(_G.ui.LBUTTONUP, g:GFunc(g.EndDrag))

    -- フレーム初期座標設定
    local position = g.settings.position
    frame:Move(position.x, position.y)
    frame:SetOffset(position.x, position.y)

    -- タイトルバー
    local titleText = frame:CreateOrGetControl('richtext', 'n_titleText', 0, 0, 0, 0)
    titleText:SetOffset(10,10)
    titleText:SetFontName('white_16_ol')
    titleText:SetText('/hawkeye or /hawk')

    -- スライド表示オンオフ切り替えボタン
    local btnW = frame:CreateOrGetControl('button', 'n_resize', 236, 4, 30, 30)
    btnW:SetText('{@sti7}{s16}W')
    btnW:SetEventScript(_G.ui.LBUTTONUP, g:GFunc(g.ToggleSlide))

    -- カメラ座標リセットボタン
    local btnR = frame:CreateOrGetControl('button', 'n_reset', 266, 4, 30, 30)
    btnR:SetText('{@sti7}{s16}R')
    btnR:SetEventScript(_G.ui.LBUTTONUP, g:GFunc(g.CameraReset))

    -- 座標ラベル
    local labelX = frame:CreateOrGetControl('richtext', 'n_labelX', 0, 0, 0, 0)
    local labelY = frame:CreateOrGetControl('richtext', 'n_labelY', 0, 0, 0, 0)
    local labelZ = frame:CreateOrGetControl('richtext', 'n_labelZ', 0, 0, 0, 0)
    labelX:SetFontName('white_14_ol')
    labelY:SetFontName('white_14_ol')
    labelZ:SetFontName('white_14_ol')
    labelX:SetOffset(20,40)
    labelY:SetOffset(20,70)
    labelZ:SetOffset(20,100)

    -- 座標スライド
    local scrX = frame:CreateOrGetControl('slidebar', 'n_scrX', 120, 34, 180, 30)
    local scrY = frame:CreateOrGetControl('slidebar', 'n_scrY', 120, 64, 180, 30)
    local scrZ = frame:CreateOrGetControl('slidebar', 'n_scrZ', 120, 94, 180, 30)
    _G.tolua.cast(scrX, 'ui::CSlideBar')
    _G.tolua.cast(scrY, 'ui::CSlideBar')
    _G.tolua.cast(scrZ, 'ui::CSlideBar')
    scrX:SetEventScript(_G.ui.LBUTTONPRESSED, g:GFunc(g.SlideEvent))
    scrY:SetEventScript(_G.ui.LBUTTONPRESSED, g:GFunc(g.SlideEvent))
    scrZ:SetEventScript(_G.ui.LBUTTONPRESSED, g:GFunc(g.SlideEvent))

    -- 座標スライド可動領域
    local min = g.static.min
    scrX:SetMinSlideLevel(min.x)
    scrY:SetMinSlideLevel(min.y)
    scrZ:SetMinSlideLevel(min.z)
    local max = g.static.max
    scrX:SetMaxSlideLevel(max.x)
    scrY:SetMaxSlideLevel(max.y)
    scrZ:SetMaxSlideLevel(max.z)

    -- 設定座標反映
    local compos = g.settings.campos
    g.SetSlideLevel(compos.x, compos.y, compos.z)
end

-- カメラ座標リセット
function g.CameraReset()
    local default = g.static.default
    g.SetSlideLevel(default.x, default.y, default.z)
    g.CameraUpdate()
end

-- スライド更新処理
function g.SetSlideLevel(x, y, z)
    local frame = _G.ui.GetFrame(g.addonNameLower)

    -- スライド位置更新
    local scrX = frame:GetChild('n_scrX')
    local scrY = frame:GetChild('n_scrY')
    local scrZ = frame:GetChild('n_scrZ')
    _G.tolua.cast(scrX, 'ui::CSlideBar')
    _G.tolua.cast(scrY, 'ui::CSlideBar')
    _G.tolua.cast(scrZ, 'ui::CSlideBar')
    scrX:SetLevel(x)
    scrY:SetLevel(y)
    scrZ:SetLevel(z)

    -- 座標ラベル更新
    local labelX = frame:GetChild('n_labelX')
    local labelY = frame:GetChild('n_labelY')
    local labelZ = frame:GetChild('n_labelZ')
    labelX:SetText('X座標('..x..'):')
    labelY:SetText('Y座標('..y..'):')
    labelZ:SetText('Z座標('..z..'):')

    -- 設定更新
    g.settings.campos.x = x
    g.settings.campos.y = y
    g.settings.campos.z = z
    g:SaveSettings()
end

-- スライド操作イベント（設定、カメラ更新）
function g.SlideEvent()
    local frame = _G.ui.GetFrame(g.addonNameLower)

    -- スライド位置取得
    local scrX = frame:GetChild('n_scrX')
    local scrY = frame:GetChild('n_scrY')
    local scrZ = frame:GetChild('n_scrZ')
    _G.tolua.cast(scrX, 'ui::CSlideBar')
    _G.tolua.cast(scrY, 'ui::CSlideBar')
    _G.tolua.cast(scrZ, 'ui::CSlideBar')

    local level = {
        x = scrX:GetLevel(),
        y = scrY:GetLevel(),
        z = scrZ:GetLevel()
    }
    g.SetSlideLevel(level.x, level.y, level.z)
    g.CameraUpdate()
end

-- フレームの移動操作終了処理
function g.EndDrag()
    local frame = _G.ui.GetFrame(g.addonNameLower)
    g.settings.position.x = frame:GetX()
    g.settings.position.y = frame:GetY()
    g:SaveSettings()
end

-- フレームの表示切り替え
function g.ToggleFrame()
    -- トグル1⇒0, 0⇒1
    g.settings.display.frame = 1 - g.settings.display.frame
    g:SaveSettings()

    g.ShowFrame(g.settings.display.frame)
end

-- スライドの表示切り替え
function g.ToggleSlide()
    -- トグル1⇒0, 0⇒1
    g.settings.display.slide = 1 - g.settings.display.slide
    g:SaveSettings()

    g.ShowSlide(g.settings.display.slide)
end

-- フレーム表示（1:表示、0:非表示）
function g.ShowFrame(mode)
    local frame = _G.ui.GetFrame(g.addonNameLower)
    frame:ShowWindow(mode)
end

-- スライド表示（1:表示、0:非表示）
function g.ShowSlide(mode)
    local frame = _G.ui.GetFrame(g.addonNameLower)
    if mode == 1 then
        frame:Resize(300,40)
    elseif mode == 0 then
        frame:Resize(300,120)
    end
end
