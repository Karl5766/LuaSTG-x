---------------------------------------------------------------------------------------------------
---spell_session.lua
---author: Karl
---date created: 2021.6.1
---desc: Defines the base objects for spells
---------------------------------------------------------------------------------------------------

---@class SpellSession
local M = LuaClass("session.Spell")

---------------------------------------------------------------------------------------------------

---@param boss Prefab.Animation
---@param hitbox Prefab.EnemyHitbox
---@param duration number spell time in frames
function M.__create(boss, hitbox, duration)
    local self = {}
    self.boss = boss
    self.hitbox = hitbox
    self.duration = duration
    self.timer = 0
    return self
end

function M:update(dt)
    task.Do(self)

    -- sync the position of hitbox to that of the boss
    self:syncHitboxPosition()

    self.timer = self.timer + 1
end

function M:syncHitboxPosition()
    local x, y = self.boss:getPosition()
    local hitbox = self.hitbox
    hitbox.x, hitbox.y = x, y
end

---return true if the spell has not ended
function M:continueSession()
    return IsValid(self.hitbox) and self.timer < self.duration
end

return M