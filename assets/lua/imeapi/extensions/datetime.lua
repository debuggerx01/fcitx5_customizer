--
-- SPDX-FileCopyrightText: 2023 DebuggerX <dx8917312@gmail.com>
--
-- SPDX-License-Identifier: LGPL-2.1-or-later
--

--- Current date and time strings.

function trim_left_zero(s)
    return (s:gsub("^0*", ""))
end

function _time(input)
  if input == "c" then
    return {
      os.time(),
      os.date("!%Y-%m-%dT%TZ")
    }
  end
  local time = os.time()
  local mon = trim_left_zero(os.date("%m", time))
  return {
    os.date("%Y/%m/%d %H:%M:%S", time),
    os.date("%H:%M:%S", time),
    os.date("%Y年" .. mon .. "月%d日 %H时%M分%S秒", time)
  }
end

function _date(input)
  local time = os.time()
  local mon = trim_left_zero(os.date("%m", time))
  return {
	  os.date("%Y年" .. mon .. "月%d日", time),
	  os.date("%Y-%m-%d", time),
	  os.date("%Y/%m/%d", time)
  }
end

ime.register_command("sj", "_time", "当前时间")

ime.register_command("rq", "_date", "当前日期")

