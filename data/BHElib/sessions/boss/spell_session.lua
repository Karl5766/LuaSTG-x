---------------------------------------------------------------------------------------------------
---spell_session.lua
---author: Karl
---date created: 2021.8.9
---desc: Defines the spells for the boss
---------------------------------------------------------------------------------------------------

local AttackSession = require("BHElib.sessions.boss.attack_session")

---@class SpellSession:AttackSession
local M = LuaClass("SpellSession", AttackSession)

---------------------------------------------------------------------------------------------------

M.IS_SPELL_CLASS = true

---------------------------------------------------------------------------------------------------
---init

---@param boss Prefab.Animation
---@param hitbox Prefab.EnemyHitbox
---@param duration number spell time in frames
---@param stage Stage
---@param attack_id string unique id of the attack
---@param enable_capture boolean if true, the global capture history will be modified at start and end of the spell
function M.__create(stage, boss, hitbox, duration, attack_id)
    local self = AttackSession.__create(stage, boss, hitbox, duration, attack_id)

    local num_capture, num_attempt = require("BHElib.sessions.boss.capture_rate"):getCaptureRate(
            stage:getDifficulty(),
            attack_id,
            stage:getPlayer().class.SHOT_TYPE_ID)
    self.display_capture_rate = {num_capture, num_attempt}

    return self
end

---------------------------------------------------------------------------------------------------
---update

function M:render()
    local font_name = "font:noto_sans_sc"
    local capture_rate = self.display_capture_rate
    local capture_rate_str = tostring(capture_rate[1]).."/"..tostring(capture_rate[2])
    RenderText(
            font_name,
            "收率: "..capture_rate_str,
            180,
            200,
            0.3,
            "right")
end

return M