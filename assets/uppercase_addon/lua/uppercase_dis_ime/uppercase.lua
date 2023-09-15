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