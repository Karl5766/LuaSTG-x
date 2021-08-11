---------------------------------------------------------------------------------------------------
---attack_session.lua
---author: Karl
---date created: 2021.8.5
---desc: Defines the attacks for the boss
---------------------------------------------------------------------------------------------------

local Session = require("BHElib.sessions.session")

---@class AttackSession:Session
local M = LuaClass("AttackSession", Session)

local Renderer = require("BHElib.ui.renderer_prefab")

---------------------------------------------------------------------------------------------------

---@param boss Prefab.Animation
---@param duration number spell time in frames
---@param stage Stage
---@param attack_id string unique id of the attack
---@param countdown_pos math.Vec2 position for the time to display
function M.__create(stage, boss, duration, attack_id, countdown_pos)
    local self = Session.__create(stage)
    self.boss = boss
    ---@type Prefab.BossHitbox
    self.hitbox = nil
    self.duration = duration
    self.attack_id = attack_id

    self.timeout_flag = false
    self.fail_flag = false  -- if the player has made a mistake
    self.kill_flag = false  -- true only if the boss' hitbox was shot down

    local enable_capture = not stage:isReplay()
    self.enable_capture = enable_capture

    if enable_capture then
        require("BHElib.sessions.boss.capture_rate"):incAttemptNum(
                stage:getDifficulty(),
                self.attack_id,
                stage:getPlayer().class.SHOT_TYPE_ID)
    end

    self.renderer = Renderer(LAYER_TOP, self, "game")

    local TextClass = require("BHElib.ui.text_class")
    self.countdown_text_object = TextClass(nil, color.WhiteSmoke, "font:noto_sans_sc", nil, nil)
    self.countdown_pos = math.Vec2(0, 164)

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

---@return string
function M:getAttackId()
    return self.attack_id
end

---@param hitbox Prefab.BossHitbox
function M:addHitbox(hitbox)
    assert(self.hitbox == nil, "Error: (SingleBoss) Attack session does not support multiple hitbox!")
    self.hitbox = hitbox
end

---------------------------------------------------------------------------------------------------
---update

---@param dt number
function M:update(dt)
    Session.update(self, dt)

    task.Do(self)

    -- sync the position of hitbox to that of the boss
    self:syncHitboxPosition()

    if self.timer >= self.duration then
        self.timeout_flag = true
    end
end

function M:syncHitboxPosition()
    local x, y = self.boss:getPosition()
    local hitbox = self.hitbox
    hitbox.x, hitbox.y = x, y
end

function M:render()
    local pos = self.countdown_pos
    local text_object = self.countdown_text_object

    local scale = 0.6

    local time_remain = (self.duration - self.timer) / 60
    local integer = int(time_remain)
    local mantissa = int(time_remain * 100) % 100

    text_object:setText(tostring(integer).." ")
    text_object:setFontAlign("right", "bottom")
    text_object:setFontSize(0.7 * scale)
    text_object:render(pos.x, pos.y)

    if mantissa ~= 0 then
        text_object:setText(".")
        text_object:render(pos.x, pos.y)

        text_object:setText(tostring(mantissa))
        text_object:setFontAlign("left", "bottom")
        text_object:setFontSize(0.6 * scale)
        text_object:render(pos.x + 10 * scale, pos.y)
    end
end

---------------------------------------------------------------------------------------------------

---triggered when a player misses or bombs
function M:onPlayerMissOrBomb()
    self.fail_flag = true
end

function M:onHitboxKill()
    self.kill_flag = true
    if not self.endSessionFlag then
        self:endSession()
    end
end

function M:onHitboxDel()
    if not self.endSessionFlag then
        self:endSession()
    end
end

function M:endSession()
    Session.endSession(self)

    local stage = self.stage
    if self.enable_capture then
        local is_captured = self.kill_flag and not (self:isFail() or self:isTimeOut())
        if is_captured then
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
end

return M