--------------------------------------------------------------------------------------------
---acc_controller.lua
---author: Karl
---date created: <2021
---desc: Defines a kind of object that manages the acceleration of bullets (and units in
---     general)
--------------------------------------------------------------------------------------------

---@class AccController
local M = LuaClass("AccController")

--------------------------------------------------------------------------------------------
---cache variables and functions

local select = select
local unpack = unpack

--------------------------------------------------------------------------------------------
---init

function M.__create(start_v)
    -- Construct an M object
    -- Input
    --		start_v (float) - starting speed

    start_v = start_v or 0

    local self = {}

    self.n=1
    self.start_v = start_v
    self.end_v = start_v
    self.total_length = 0
    self.time_array = {0, math.huge}
    self.coeff_array = {}  -- A quadratic list that specifies an equation l(t) t that calculates the distance at i-th segment
    return self
end

function M.shortInit(...)
    local acc_con = M(select(1, ...))
    local n = select("#", ...)
    for i = 3, n, 2 do
        acc_con:addAcc(select(i - 1, ...), select(i, ...))
    end
    return acc_con
end

--------------------------------------------------------------------------------------------
---getters and modifiers

---@param acc_time number
---@param final_speed number
function M:newAcc(acc_time, final_speed)
    if acc_time == nil then
        error("ExpressionAccController: The value of time entered is nil.")
    elseif final_speed == nil then
        error("ExpressionAccController: The value of velocity entered is nil.")
    end
    if acc_time < 0 then
        error("ExpressionAccController: The value of time entered is negative.")
    end
    local n, total_length, total_time, last_v = self.n, self.total_length, self.time_array[self.n], self.end_v
    self.end_v = final_speed
    self.total_length = total_length + (last_v + final_speed) * 0.5 * acc_time
    self.time_array[n + 1] = total_time + acc_time
    self.time_array[n + 2] = math.huge
    self.n = n + 1

    if acc_time == 0 then
        self.coeff_array[n] = {0, 0, total_length}
        return
    end

    local a = (final_speed - last_v) * 0.5 / acc_time
    local b = last_v - 2 * a * total_time
    local c = total_length - a * total_time ^ 2 - b * total_time
    self.coeff_array[n] = {a, b, c}
end

M.addAcc = M.newAcc

function M:getDistance(t)
    local i, tList = 1, self.time_array
    while t > tList[i] do
        i = i + 1
    end
    if i == 1 then
        return t * self.start_v
    end
    local n = self.n
    if i == n + 1 then
        return self.total_length + (t - tList[n]) * self.end_v
    end
    local coeff_array = self.coeff_array[i - 1]
    return t * (t * coeff_array[1] + coeff_array[2]) + coeff_array[3]  -- Evaluate the quadratic function
end

function M:getSpeed(t)
    local i, tList = 1, self.time_array
    while t > tList[i] do
        i = i + 1
    end
    if i == 1 then
        return self.start_v
    elseif i == self.n + 1 then
        return self.end_v
    end
    local coeff_array = self.coeff_array[i - 1]
    return 2 * t * coeff_array[1] + coeff_array[2]  -- Differenciate the quadratic function
end

--------------------------------------------------------------------------------------------
---copy

function M:copy()
    local obj = M(self[1])

    obj.n=self.n
    obj.start_v = self.start_v
    obj.end_v = self.end_v
    obj.total_length = self.total_length
    for i = 1,self.n do
        obj.time_array[i] = self.time_array[i]
        if i < self.n then
            obj.coeff_array[i] = {unpack(self.coeff_array[i])}
        end
    end
    return obj
end

return M