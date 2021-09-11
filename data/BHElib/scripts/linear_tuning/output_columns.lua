---------------------------------------------------------------------------------------------------
---output_columns.lua
---author: Karl
---date created: before 2021
---desc: Defines output columns
---modifiers:
---     Karl, 2021.9.4, put output columns together and add a method for easy definition
---------------------------------------------------------------------------------------------------

local ParameterColumn = require("BHElib.scripts.linear_tuning.parameter_column")

---@class OutputColumns
local M = {}

---------------------------------------------------------------------------------------------------

local Bullet = require("BHElib.units.bullet.bullet_prefab")
local DelayedAccBullet = require("BHElib.scripts.units.delayed_acc_bullet")
local EnemyTypes = require("BHElib.units.enemy.enemy_type.enemy_types")
local Enemy = require("BHElib.units.enemy.enemy_prefab")
local DeletionTasks = require("BHElib.scripts.units.deletion_tasks")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local TaskWait = task.Wait

---------------------------------------------------------------------------------------------------
---defining function

function M.Define(class_id, spark_callback)
    local ret = LuaClass(class_id, ParameterColumn)
    function ret.__create(master)
        return ParameterColumn.__create(master, class_id)
    end
    ret.spark = spark_callback

    return ret
end
local Define = M.Define

---------------------------------------------------------------------------------------------------

M.Empty = Define("EmptyOutputColumn", function(self)
end)

---------------------------------------------------------------------------------------------------

M.Bullet = Define("BulletOutputColumn", function(self)
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
end)

---------------------------------------------------------------------------------------------------

M.AccBullet = Define("DelayedAccBulletOutputColumn", function(self)
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
end)

---------------------------------------------------------------------------------------------------

M.Enemy = Define("EnemyOutputColumn", function(self)
    local startTime = self.s_t or 0

    TaskNew(self.s_master,function()
        if startTime < 0 then
            local decimal = 1 - (-self.s_t) % 1
            startTime = startTime - decimal
            TaskWait(-startTime)
            startTime = decimal
        end

        if self.s_n ~= 0 then
            local enemy = Enemy(self.type, self.hp)
            enemy.x = self.x
            enemy.y = self.y
            enemy.vx = self.vx
            enemy.vy = self.vy
            if enemy.vx > 0.3 then
                enemy:playMovementAnimation(INFINITE, false)
            elseif enemy.vx < -0.3 then
                enemy:playMovementAnimation(INFINITE, true)
            end
            enemy.bound = true
            if self.del_out_of_after_coming_in then
                enemy.bound = false
                DeletionTasks.DelOutOfAfterComingIn(enemy, unpack(self.del_out_of_after_coming_in))
            end
            if self.chains then
                for _, chain in ipairs(self.chains) do
                    chain:sparkAll(enemy)
                end
            end
        end
    end)
end)

return M