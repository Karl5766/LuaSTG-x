---------------------------------------------------------------------------------------------------
---unit_motion.lua
---author: Karl
---date created: before 2021
---desc: Defines tasks for controlling unit movement
---------------------------------------------------------------------------------------------------

---@class UnitMotion
local M = {}

local TaskNew = task.New
local Yield = coroutine.yield
local TaskWait = task.Wait
local Angle = Angle
local sin = sin
local cos = cos

---------------------------------------------------------------------------------------------------
---basic move to functions

---@param ease function maps [0,1] to [0,1]
function M.MoveTo(self, move_time, x, y, ease, navi)
    local sx, sy = self.x, self.y
    if navi then
        self.rot = Angle(sx, sy, x, y)
    end
    if move_time >= 1 then
        local dx, dy = x - sx, y - sy
        TaskNew(self, function()
            for i = 1, move_time do
                local u = ease(i / move_time)
                self.x, self.y = sx + u * dx, sy + u * dy
                Yield()
            end
        end)
    else
        self.x, self.y = x, y
    end
end

---------------------------------------------------------------------------------------------------
---controller

function M.XYControllerMoveTo(self, xCon, yCon, startTime)
    local baseX, baseY = self.x, self.y
    self.x, self.y = baseX + xCon:getDistance(startTime), baseY + yCon:getDistance(startTime)

    TaskNew(self, function()
        while true do
            local x, y = baseX + xCon:getDistance(startTime), baseY + yCon:getDistance(startTime)
            self.x, self.y = baseX + x, baseY + y
            Yield()
            startTime = startTime + 1
        end
    end)
end

function M.PolarControllerMoveTo(self, dCon, aCon, initAngle, startTime)
    local baseX, baseY = self.x, self.y
    local d, a = dCon:getDistance(startTime), aCon:getDistance(startTime) + initAngle
    self.x, self.y = baseX + cos(a) * d, baseY + sin(a) * d

    TaskNew(self, function()
        while true do
            local d, a = dCon:getDistance(startTime), aCon:getDistance(startTime) + initAngle
            self.x, self.y = baseX + cos(a) * d, baseY + sin(a) * d
            Yield()
            startTime = startTime + 1
        end
    end)
end

function M.FixedAngleControllerMoveTo(self, controller, angle, startTime)
    local baseX, baseY = self.x, self.y
    startTime = startTime or 0
    local d = controller:getDistance(startTime)
    self.x, self.y = baseX + cos(angle) * d, baseY + sin(angle) * d

    TaskNew(self, function()
        while true do
            local d = controller:getDistance(startTime)
            self.x, self.y = baseX + cos(angle) * d, baseY + sin(angle) * d
            Yield()
            startTime = startTime + 1
        end
    end)
end

function M.VariableAngleControllerMoveTo(self, controller, rotCon, initAngle, startTime, navi)
    -- Create a task that manages the speed and motion angle of an object
    -- Input
    --		self (list) - a reference to the object
    --		controller (AccController) - an acceleration controller that controls speed of the object
    --		rotCon (AccController) - an acceleration controller that controls motion angle of the object
    --		rotFlag (boolean) - whether to change the rotation of the object

    if navi then
        local a = initAngle + rotCon:getDistance(startTime)
        self.rot = a
    end

    TaskNew(self,function()
        while true do
            local v, a = controller:getSpeed(startTime), initAngle + rotCon:getDistance(startTime)
            self.vx, self.vy = v * cos(a), v * sin(a)
            if navi then
                self.rot = a
            end
            Yield()
            startTime = startTime + 1
        end
    end)
end

return M