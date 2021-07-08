---------------------------------------------------------------------------------------------------
---spell.lua
---author: Karl
---date created: 2021.6.1
---desc: Defines the base objects for spells
---------------------------------------------------------------------------------------------------

---@class Spell
local SpellBase = LuaClass("units.boss.Spell")

---------------------------------------------------------------------------------------------------

---@param duration number spell time in frames
---@param animation Prefab.Animation
---@param hitbox EnemyHitbox
function SpellBase.__create(animation, hitbox, duration)
    local self = {}
    self.animation = animation
    self.hitbox = hitbox
    self.duration = duration
    self.timer = 0
    return self
end

function SpellBase:update(dt)
    task.Do(self)

    -- sync the position of hitbox to that of the animation
    local x, y = self.animation:getPosition()
    local hitbox = self.hitbox
    hitbox.x, hitbox.y = x, y

    self.timer = self.timer + 1
end

---return true if the spell has not ended
function SpellBase:continueSession()
    return IsValid(self.hitbox) and self.timer < self.duration
end

return SpellBase