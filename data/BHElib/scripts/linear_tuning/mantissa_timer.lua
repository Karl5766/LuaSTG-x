--------------------------------------------------------------------------------------------
---mantissa_timer.lua
---author: Karl
---desc: 用于克服Luastg单帧时间限制，精确计算时间的倒计时秒表
---modifiers:
---		Karl, 2020.6.27, 加入update函数；其作用与wait函数相近，但是不会在task中进行等待
---		2021.8.29, 把代码移植到-x上，改用LuaClass实现
--------------------------------------------------------------------------------------------

---@class MantissaTimer
local M = LuaClass("MantissaTimer")

--------------------------------------------------------------------------------------------
---cache variables and functions

local floor = math.floor
local TaskWait = task.Wait

--------------------------------------------------------------------------------------------
---init

---@param start_time number initial time on the clock
function M.__create(start_time)
	local self = {
		start_time = start_time or 0,
	}

	return self
end

function M:ctor()
	self:reset()
end

--------------------------------------------------------------------------------------------
---reset

function M:reset()
	local start_time = self.start_time
	self.total_time = -start_time
	self.mantissa_time = -start_time  -- wait() will start waiting only when mantissa >= 1
end

--------------------------------------------------------------------------------------------
---update

function M:wait(wait_time)
	local total_time = self.total_time + wait_time
	local mantissa = self.mantissa_time + wait_time
	
	local t = floor(mantissa)
    if t > 0 then
		mantissa = mantissa - t
		TaskWait(t)
    end

	self.mantissa_time = mantissa
	self.total_time = total_time
end

---wait() without actually waiting in task
function M:update(wTime)
	local total_time = self.total_time + wTime
	local mantissa = self.mantissa_time + wTime

	local t = floor(mantissa)
	if t > 0 then
		mantissa = mantissa - t
	end

	self.mantissa_time = mantissa
	self.total_time = total_time
end

function M:mantissa()
	return self.mantissa_time
end

function M:total()
	return self.total_time
end

function M:copy()
	local newTimer = M(self.start_time, self.stop_time)
	newTimer.total_time = self.total_time
	newTimer.mantissa_time = self.mantissa_time
	return newTimer
end