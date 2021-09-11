---------------------------------------------------------------------------------------------------
---deletion_tasks.lua
---date: 2021.9.11
---desc: This file defines tasks that manages a unit's deletion
---------------------------------------------------------------------------------------------------

---@class DeletionTasks
local M = {}

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local Yield = coroutine.yield
local _math_huge = math.huge

---------------------------------------------------------------------------------------------------

local function InBox(x, y, l, r, b, t)
    return x >= l and x <= r and y >= b and y <= t
end

---Check each frame, if unit is out of box, call Del on it
---@param unit Prefab.Object
---@param l number
---@param r number
---@param b number
---@param t number
function M.DelOutOf(unit, l, r, b, t)
    l = l or -_math_huge
    r = r or _math_huge
    b = b or -_math_huge
    t = t or _math_huge
    TaskNew(unit, function()
        while InBox(unit.x, unit.y, l, r, b, t) do
            Yield()
        end
        Del(unit)
    end)
end

---@param unit Prefab.Object
---@param time number number of frames; after this amount of time passes the object will be deleted
function M.DelAfter(unit, time)
    assert(time and time >= 0, "Error: Invalid time parameter!")
    TaskNew(unit, function()
        for i = 1, time do
            Yield()
        end
        Del(unit)
    end)
end

function M.DelOutOfAfterComingIn(unit, l, r, b, t)
    l = l or -_math_huge
    r = r or _math_huge
    b = b or -_math_huge
    t = t or _math_huge
    TaskNew(unit, function()
        while not InBox(unit.x, unit.y, l, r, b, t) do
            Yield()
        end
        while InBox(unit.x, unit.y, l, r, b, t) do
            Yield()
        end
        Del(unit)
    end)
end

return M