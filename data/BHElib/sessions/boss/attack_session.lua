---------------------------------------------------------------------------------------------------
---attack_session.lua
---author: Karl
---date created: 2021.8.5
---desc: Defines the attacks for the boss
---------------------------------------------------------------------------------------------------

---@class AttackSession
local M = LuaClass("AttackSession")

local Renderer = require("BHElib.ui.renderer_prefab")

---------------------------------------------------------------------------------------------------

---@param boss Prefab.Animation
---@param hitbox Prefab.EnemyHitbox
---@param duration number spell time in frames
---@param stage Stage
---@param attack_id string unique id of the attack
function M.__create(stage, boss, hitbox, duration, attack_id)
    local self = {}
    self.boss = boss
    self.hitbox = hitbox
    self.duration = duration
    self.timer = 0

    ---@type Stage
    self.stage = stage
    self.attack_id = attack_id

    self.timeout_flag = false
    self.fail_flag = false  -- if the player has made a mistake

    local enable_capture = not stage:isReplay()
    self.enable_capture = enable_capture

    if enable_capture then
        require("BHElib.sessions.boss.capture_rate"):incAttemptNum(
                stage:getDifficulty(),
                self.attack_id,
                stage:getPlayer().class.SHOT_TYPE_ID)
    end

    self.renderer = Renderer(LAYER_TOP, self, "game")

    stage:addSession(self)

    return self
end

---------------------------------------------------------------------------------------------------
---setters and getters

---@return boolean
function M:isFail()
    return self.fail_flag
end

---@return boolean
function M:isTimeOut()
    return self.timeout_flag
end

---return true if the spell has not ended
function M:isContinuing()
    return IsValid(self.hitbox) and not self.timeout_flag
end

---@return string
function M:getAttackId()
    return self.attack_id
end

---------------------------------------------------------------------------------------------------
---update

---@param dt number
function M:update(dt)
    task.Do(self)

    -- sync the position of hitbox to that of the boss
    self:syncHitboxPosition()

    if self.timer >= self.duration then
        self.timeout_flag = true
    end

    self.timer = self.timer + 1
end

function M:syncHitboxPosition()
    local x, y = self.boss:getPosition()
    local hitbox = self.hitbox
    hitbox.x, hitbox.y = x, y
end

function M:render()
end

---------------------------------------------------------------------------------------------------

---triggered when a player misses or bombs
function M:onPlayerMissOrBomb()
    self.fail_flag = true
end

function M:endSession()
    local stage = self.stage
    print("ending session")
    if self.enable_capture then
        print("capture enabled")
        print(self:isFail())
        print(self:isTimeOut())
        print(IsValid(self.hitbox))
        local is_captured = not (self:isFail() or self:isTimeOut() or IsValid(self.hitbox))
        if is_captured then
            print("captured")
            require("BHElib.sessions.boss.capture_rate"):incCaptureNum(
                    stage:getDifficulty(),
                    self.attack_id,
                    stage:getPlayer().class.SHOT_TYPE_ID)
        end
    end

    if IsValid(self.hitbox) then
        Del(self.hitbox)
    end
    Del(self.renderer)

    stage:removeSession(self)
end

return M