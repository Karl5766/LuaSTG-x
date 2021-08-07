---------------------------------------------------------------------------------------------------
---attack_session.lua
---author: Karl
---date created: 2021.8.5
---desc: Defines the attacks for the boss
---------------------------------------------------------------------------------------------------

---@class AttackSession
local M = LuaClass("AttackSession")

---------------------------------------------------------------------------------------------------

---@param boss Prefab.Animation
---@param hitbox Prefab.EnemyHitbox
---@param duration number spell time in frames
---@param stage Stage
function M.__create(boss, hitbox, duration, stage)
    local self = {}
    self.boss = boss
    self.hitbox = hitbox
    self.duration = duration
    self.timer = 0
    self.timeout_flag = false
    self.stage = stage
    return self
end

function M:update(dt)
    task.Do(self)

    -- sync the position of hitbox to that of the boss
    self:syncHitboxPosition()

    if self.timer >= self.duration then
        self.timeout_flag = true
    end

    self.timer = self.timer + 1
end

function M:isTimeOut()
    return self.timeout_flag
end

function M:syncHitboxPosition()
    local x, y = self.boss:getPosition()
    local hitbox = self.hitbox
    hitbox.x, hitbox.y = x, y
end

---return true if the spell has not ended
function M:isContinuing()
    return IsValid(self.hitbox) and not self.timeout_flag
end

function M:endSession()
    Del(self.hitbox)
end

return M