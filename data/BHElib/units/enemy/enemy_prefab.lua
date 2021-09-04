---------------------------------------------------------------------------------------------------
---enemy_prefab.lua
---date created: 2021.8.19
---reference: THlib/enemy/enemy.lua
---desc: Defines the enemy class; it is derived from EnemyHitbox prefab, and utilizes enemy types
---     to implement varieties in animation
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")
local EnemyHitbox = require("BHElib.units.enemy.enemy_hitbox_prefab")

---@class Prefab.Enemy:Prefab.EnemyHitbox
local M = Prefab.NewX(EnemyHitbox)

---------------------------------------------------------------------------------------------------

---@param enemy_type EnemyTypeClass
---@param max_hp number
function M:init(enemy_type, max_hp)
    self.layer = LAYER_ENEMY
    self.damage_timer = 0

    self.enemy_type = enemy_type
    enemy_type:onInit(self)  -- will set self.img
    EnemyHitbox.init(self, enemy_type:getDefaultRadius(), max_hp)  -- set collision radius after self.img is set
end

function M:frame()
    task.Do(self)
    self.damage_timer = max(0, self.damage_timer - 1)

    EnemyHitbox.frame(self)
    self.enemy_type:onFrame(self)
end

function M:render()
    local res = self.res
    if self.damage_timer ~= 0 and self.timer % 3 == 0 then
        self.color = Color(0xFF0000A0)
    else
        self.color = Color(0xFFFFFFFF)
    end

    self.enemy_type:onRender(self)
end

---------------------------------------------------------------------------------------------------

---@param attack number value of damage received
function M:receiveDamage(attack)
    self.damage_timer = 12

    EnemyHitbox.receiveDamage(self, attack)
end

function M:playMovementAnimation(time, is_left)
    self.enemy_type:onMove(self, time, is_left)
end

---------------------------------------------------------------------------------------------------
---deletion

function M:kill()
    self.enemy_type:onKill(self)
end

Prefab.Register(M)

return M