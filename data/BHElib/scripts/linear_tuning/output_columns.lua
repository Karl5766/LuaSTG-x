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

local ParameterMatrix = require("BHElib.scripts.linear_tuning.parameter_matrix")

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
---make functions to define other ones

local function SparkTaskCallback(self, spawn_callback)
    local startTime = self.s_t or 0
    if startTime < 0 then
        local decimal = 1 - (-startTime) % 1
        startTime = startTime - decimal
        TaskWait(-startTime)
        startTime = decimal
    end

    if self.s_n ~= 0 then
        spawn_callback(self, startTime)
    end
end

---@param spawn_callback function takes in parameters (col, s_t) and spawns an object accordingly
---@return function a spark function for the output column
local function GetSparkFunction(spawn_callback)
    local function Spark(self)
        TaskNew(self.s_master, function()
            SparkTaskCallback(self, spawn_callback)
        end)
    end

    return Spark
end

---@param class_id string
---@param spawn_callback function takes in parameters (col, s_t) and spawns an object accordingly
---@return function a spark function for the output column
function M.SpawnDefine(class_id, spawn_callback)
    local ret = LuaClass(class_id, ParameterColumn)
    function ret.__create(master)
        return ParameterColumn.__create(master, class_id)
    end
    ret.spark = GetSparkFunction(spawn_callback)

    return ret
end
local SpawnDefine = M.SpawnDefine

---@param class_id string
---@param spark_callback function takes in parameters (col)
---@return table a new OutputColumn class
function M.SparkDefine(class_id, spark_callback)
    local ret = LuaClass(class_id, ParameterColumn)
    function ret.__create(master)
        return ParameterColumn.__create(master, class_id)
    end
    ret.spark = spark_callback

    return ret
end
local SparkDefine = M.SparkDefine

---------------------------------------------------------------------------------------------------
---output definitions
---------------------------------------------------------------------------------------------------

M.Empty = SparkDefine("EmptyOutputColumn", function(self)
end)

---------------------------------------------------------------------------------------------------
---A column solely for call spark() on other matrices' heads

M.Matrices = SparkDefine("MatricesColumn", function(self)
    local chains = self.s_chains
    if chains then
        -- because this output column is a temporary instance, we can link it to the head of the
        -- matrix and spark it once (which copies the parameter to the head) and dispose it
        for i = 1, #chains do
            local chain = chains[i]
            local head = chain.head
            self:add(head)
            ParameterMatrix.SetChainMaster(chain, self.s_master)
        end
    end
    ParameterColumn.spark(self)
end)

---------------------------------------------------------------------------------------------------

M.Bullet = SpawnDefine("BulletOutputColumn", function(col, s_t)
    if col.s_n ~= 0 then
        if col.sound then
            local soundName, soundVol = unpack(col.sound)
            PlaySound(soundName, soundVol, col.x/256, true)
        end
        local b = Bullet(col.bullet_type_name, col.color_index, GROUP_ENEMY_BULLET,
                col.blink_time, col.effect_size, col.destroyable)
        b.x = col.x
        b.y = col.y
        local angle = col.angle
        b.vx = col.controller * cos(angle)
        b.vy = col.controller * sin(angle)
        return b
    end
end)

---------------------------------------------------------------------------------------------------

M.AccBullet = SpawnDefine("DelayedAccBulletOutputColumn", function(col, s_t)
    -- Generate a delayed acceleration bullet
    if col.s_n ~= 0 then
        if col.sound then
            local soundName, soundVol = unpack(col.sound)
            PlaySound(soundName, soundVol, col.x/256, true)
        end
        col.start_time = s_t

        local bullet = DelayedAccBullet(col)

        local registerers = col.registerers
        if registerers then
            for i = 1, #registerers do
                local registerer = registerers[i]
                registerer:on_init(bullet)
            end
        end

        return bullet
    end
end)

---------------------------------------------------------------------------------------------------

M.Enemy = SpawnDefine("EnemyOutputColumn", function(col, s_t)

    if col.s_n ~= 0 then
        local enemy = Enemy(col.type, col.hp)
        enemy.x = col.x
        enemy.y = col.y
        enemy.vx = col.vx
        enemy.vy = col.vy
        if enemy.vx > 0.3 then
            enemy:playMovementAnimation(INFINITE, false)
        elseif enemy.vx < -0.3 then
            enemy:playMovementAnimation(INFINITE, true)
        end
        enemy.bound = true
        if col.del_out_of_after_coming_in then
            enemy.bound = false
            DeletionTasks.DelOutOfAfterComingIn(enemy, unpack(col.del_out_of_after_coming_in))
        end
        if col.s_chains then
            for _, chain in ipairs(col.s_chains) do
                chain:sparkAll(enemy)
            end
        end

        return enemy
    end
end)

return M