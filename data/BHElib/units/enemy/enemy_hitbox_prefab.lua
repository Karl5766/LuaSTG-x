---------------------------------------------------------------------------------------------------
---enemy_hitbox.lua
---author: Karl
---date created: 2021.6.1
---desc: Defines the base objects for enemies that have hitboxes; a hitbox here has a disk shaped
---     collision box with some hp, the hitbox is killed when hp reaches or goes below 0
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---@class Prefab.EnemyHitbox:Prefab.Object
local M = Prefab.NewX(Prefab.Object, "Prefab.EnemyHitbox")

---------------------------------------------------------------------------------------------------
---@param colli_radius number will set .a and .b to this value; radius of the hitbox by default
---@param max_hp number maximum hp value
function M:init(colli_radius, max_hp)

    self.group = GROUP_ENEMY
    self.bound = false
    self.a = colli_radius
    self.b = colli_radius
    self.rect = false
    self.max_hp = max_hp
    self.hp = max_hp
    self.damage_multiplier = 1
end

---------------------------------------------------------------------------------------------------

---@return number maximum hp of the enemy
function M:getMaxHp()
    return self.max_hp
end

---@return number remaining hp of the enemy
function M:getHp()
    return self.hp
end

---@param damage_multiplier number specifies the multiplier of the damage
function M:setDamageMultiplier(damage_multiplier)
    self.damage_multiplier = damage_multiplier
end

---@return number
function M:getDamageMultiplier()
    return self.damage_multiplier
end

---@param attack number value of damage received
function M:receiveDamage(attack)
    self.hp = self.hp - attack * self.damage_multiplier
end

---------------------------------------------------------------------------------------------------
---update

function M:frame()
    if self.hp <= 0 then
        Kill(self)
    end
end

---------------------------------------------------------------------------------------------------
---collision events

function M:onPlayerBulletCollision(other)
    other:onEnemyCollision(self)
    other:playNormalHitSound()
end

Prefab.Register(M)

return M