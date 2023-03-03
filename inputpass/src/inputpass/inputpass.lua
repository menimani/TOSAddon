local addonName = 'INPUTPASS'
_G['ADDONS'] = _G['ADDONS'] or {}
_G['ADDONS']['MENIMANI'] = _G['ADDONS']['MENIMANI'] or {}
_G['ADDONS']['MENIMANI'][addonName] = _G['ADDONS']['MENIMANI'][addonName] or {}

local g = _G['ADDONS']['MENIMANI'][addonName]

_G['ADDONS']['MENIMANI']['M2UTIL'].OnInit(addonName, function()
  -- addon.ipf\warningmsgbox\warningmsgbox.lua
  g:setupEvent('WARNINGMSGBOX_FRAME_OPEN', g.AutoInput)
  g:setupEvent('NOT_ROASTING_GEM_EQUIP_WARNINGMSGBOX_FRAME_OPEN', g.AutoInput)
  g:setupEvent('WARNINGMSGBOX_FRAME_OPEN_REBUILDPOPUP', g.AutoInput)
  g:setupEvent('WARNINGMSGBOX_FRAME_OPEN_NONNESTED', g.AutoInput)
  g:setupEvent('WARNINGMSGBOX_FRAME_OPEN_WITH_CHECK', g.AutoInput)
  g:setupEvent('WARNINGMSGBOX_FRAME_OPEN_DELETE_ITEM', g.AutoInput)
  g:setupEvent('WARNINGMSGBOX_FRAME_OPEN_EXCHANGE_RECYCLE', g.AutoInput)
end)

function g.AutoInput()
  -- 指定文字列を抽出し、自動入力する
  local frame = _G.ui.GetFrame('warningmsgbox')
  local warningText = _G.GET_CHILD_RECURSIVELY(frame, 'warningtext')
  local input_text = string.match(warningText:GetText(), '.+%[(%S+)%]')
  if input_text == nil then
    return
  end
  local input_frame = _G.GET_CHILD_RECURSIVELY(frame, 'input')
  if input_frame == nil then
    return
  end
  input_frame:SetText(input_text)
end
