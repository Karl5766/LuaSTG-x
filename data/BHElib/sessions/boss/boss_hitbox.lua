---------------------------------------------------------------------------------------------------
---boss_hitbox.lua
---author: Karl
---date created: 2021.6.1
---desc: Defines the base objects for enemies that have hitboxes; a hitbox here has a disk shaped
---     collision box with some hp, the hitbox is killed when hp reaches or goes below 0
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")
local EnemyHitbox = require("BHElib.units.enemy.enemy_hitbox")

---@class Prefab.BossHitbox:Prefab.EnemyHitbox
local M = Prefab.NewX(EnemyHitbox)

---------------------------------------------------------------------------------------------------
---init

---@param radius number
---@param hp number initial hp
---@param session AttackSession
function M:init(radius, hp, session)
    EnemyHitbox.init(self, radius, hp)

    self.session = session
    session:addHitbox(self)

    self.is_del = false
end

---------------------------------------------------------------------------------------------------
---deletion

function M:del()
    if not self.is_del then
        self.session:onHitboxDel(self)
    end

    self.is_del = true
end

function M:kill()
    if not self.is_del then
        self.session:onHitboxKill(self)
    end

    self.is_del = true
end

---------------------------------------------------------------------------------------------------
---collision events

---@param other Prefab.PlayerBullet
function M:onPlayerBulletCollision(other)
    other:onEnemyCollision(self)
    if self.hp < self.max_hp * 0.1 then
        other:playLowHpHitSound()
    else
        other:playNormalHitSound()
    end
end

Prefab.Register(M)

return M