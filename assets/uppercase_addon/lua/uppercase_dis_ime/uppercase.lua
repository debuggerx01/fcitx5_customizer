--
-- SPDX-FileCopyrightText: 2023 DebuggerX <dx8917312@gmail.com>
--
-- SPDX-License-Identifier: LGPL-2.1-or-later
--

--- Disable IME when entering uppercase letters.
-- @module UppercaseDisIME


local fcitx = require("fcitx")

fcitx.watchEvent(fcitx.EventType.KeyEvent, "handleUppercaseLetter")

preIME = nil

function handleUppercaseLetter(sym, state, release)
  if release or state ~= fcitx.KeyState.None then
    return
  end
  if sym >= 65 and sym <= 90 then
    current = fcitx.currentInputMethod()
    if current ~= 'keyboard-us' then
      fcitx.setCurrentInputMethod('keyboard-us')
      preIME = current
    end
  elseif preIME ~= nil then
    fcitx.setCurrentInputMethod(preIME)
    preIME = nil
    end
end