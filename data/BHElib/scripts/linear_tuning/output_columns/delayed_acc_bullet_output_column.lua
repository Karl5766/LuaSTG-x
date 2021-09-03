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

    local start_time = self.s_t or 0

    TaskNew(self.s_master,function()
        if start_time < 0 then
            local decimal = 1 - (-self.s_t) % 1
            start_time = start_time - decimal
            TaskWait(-start_time)
            start_time = decimal
        end

        if self.sound then
            local soundName, soundVol = unpack(self.sound)
            PlaySound(soundName, soundVol, self.x/256, true)
        end
        if self.s_n ~= 0 then
            self.start_time = start_time
            DelayedAccBullet(self)
        end
    end)
end

return M