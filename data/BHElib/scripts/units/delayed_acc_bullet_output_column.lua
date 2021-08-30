---------------------------------------------------------------------------------------------------
---delayed_acc_bullet_output_column.lua
---author: Karl
---date created: before 2021
---desc: Manages the ui of a tuning stage
---------------------------------------------------------------------------------------------------

local ParameterColumn = require("BHElib.scripts.linear_tuning.parameter_column")

---@class DelayedAccBulletOutputColumn:ParameterColumn
local M = LuaClass("DelayedAccBulletOutputColumn", ParameterColumn)

---------------------------------------------------------------------------------------------------

local DelayedAccBullet = require("BHElib.scripts.units.delayed_acc_bullet")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local TaskWait = task.Wait

---------------------------------------------------------------------------------------------------
---init

function M.__create(master)
    local self = ParameterColumn.__create(master, "delayed acc bullet output column")

    return self
end

function M:spark()
    -- Generate a delayed acceleration bullet

    local startTime = self.s_t

    TaskNew(self.s_master,function()
        if startTime < 0 then
            local decimal = 1 - (-self.s_t) % 1
            startTime = startTime - decimal
            TaskWait(-startTime)
            startTime = decimal
        end

        if self.sound then
            local soundName, soundVol = unpack(self.sound)
            PlaySound(soundName, soundVol, self.x/256, true)
        end
        if self.s_n ~= 0 then
            DelayedAccBullet(self)
        end
    end)
end

return M