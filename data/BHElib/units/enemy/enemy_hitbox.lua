---------------------------------------------------------------------------------------------------
---enemy_hitbox.lua
---author: Karl
---date created: 2021.6.1
---desc: Defines the base objects for enemies that have hitboxes; a hitbox here has a disk shaped
---     collision box with some hp, the hitbox is killed when hp reaches or goes below 0
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")

---@class Prefab.EnemyHitbox:Prefab.Object
local EnemyHitbox = Prefab.NewX(Prefab.Object)

---------------------------------------------------------------------------------------------------

function EnemyHitbox:init(radius, hp)
    self.group = GROUP_ENEMY
    self.bound = false
    self.a = radius
    self.b = radius
    self.rect = false
    self.hp = hp
    self.damage_multiplier = 1
end

function EnemyHitbox:setDamageMultiplier(damage_multiplier)
    self.damage_multiplier = damage_multiplier
end

function EnemyHitbox:getDamageMultiplier()
    return self.damage_multiplier
end

function EnemyHitbox:colli(other)
    if other.onEnemyCollision then
        other:onEnemyCollision(self)

        self.hp = self.hp - other:getAttack() * self.damage_multiplier
    end

    if self.hp <= 0 then
        Kill(self)
    end
end

Prefab.Register(EnemyHitbox)

return EnemyHitbox