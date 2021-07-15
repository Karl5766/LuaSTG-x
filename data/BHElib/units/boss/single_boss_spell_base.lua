---------------------------------------------------------------------------------------------------
---single_boss_spell_base.lua
---author: Karl
---date created: 2021.6.1
---desc: Defines the base objects for spells
---------------------------------------------------------------------------------------------------

---@class SingleBossSpellBase
local SpellBase = LuaClass("units.boss.Spell")

---------------------------------------------------------------------------------------------------

---@param duration number spell time in frames
---@param boss Prefab.Animation
---@param hitbox Prefab.EnemyHitbox
function SpellBase.__create(boss, hitbox, duration)
    local self = {}
    self.boss = boss
    self.hitbox = hitbox
    self.duration = duration
    self.timer = 0
    return self
end

function SpellBase:update(dt)
    task.Do(self)

    -- sync the position of hitbox to that of the boss
    self:syncHitboxPosition()

    self.timer = self.timer + 1
end

function SpellBase:syncHitboxPosition()
    local x, y = self.boss:getPosition()
    local hitbox = self.hitbox
    hitbox.x, hitbox.y = x, y
end

---return true if the spell has not ended
function SpellBase:continueSession()
    return IsValid(self.hitbox) and self.timer < self.duration
end

return SpellBase