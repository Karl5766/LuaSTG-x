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

---@param radius number
---@param hp number initial hp
---@param session AttackSession
function M:init(radius, hp, session)
    EnemyHitbox.init(self, radius, hp)

    self.session = session
    session:addHitbox(self)

    self.is_del = false
end

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

Prefab.Register(M)

return M