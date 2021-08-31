---------------------------------------------------------------------------------------------------
---delayed_acc_bullet_output_column.lua
---author: Karl
---date created: before 2021
---desc: Manages the ui of a tuning stage
---------------------------------------------------------------------------------------------------

local ParameterColumn = require("BHElib.scripts.linear_tuning.parameter_column")

---@class BulletOutputColumn:ParameterColumn
local M = LuaClass("BulletOutputColumn", ParameterColumn)

---------------------------------------------------------------------------------------------------

local Bullet = require("BHElib.units.bullet.bullet_prefab")

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

    local startTime = self.s_t or 0

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
            local b = Bullet(self.bullet_type_name, self.color_index, GROUP_ENEMY_BULLET,
                    self.blink_time, self.effect_size, self.destroyable)
            b.x = self.x
            b.y = self.y
            local angle = self.angle
            b.vx = self.controller * cos(angle)
            b.vy = self.controller * sin(angle)
        end
    end)
end

return M