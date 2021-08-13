---------------------------------------------------------------------------------------------------
---spell_session.lua
---author: Karl
---date created: 2021.8.9
---desc: Defines the spells for single-boss boss fight; a spell has its capture rate explicitly
---     rendered (instead of just recording it), and display other spell information like attack
---     session does
---------------------------------------------------------------------------------------------------

local AttackSession = require("BHElib.sessions.boss.attack_session")

---@class SpellSession:AttackSession
local M = LuaClass("SpellSession", AttackSession)

---------------------------------------------------------------------------------------------------
---cache functions and variables

local Vec2 = math.Vec2

---------------------------------------------------------------------------------------------------

---@type boolean
M.IS_SPELL_CLASS = true

---name of the spell card (a constant class attribute)
---@type string
M.SPELL_DISPLAY_NAME = nil

---------------------------------------------------------------------------------------------------
---init

---@param boss Prefab.Animation
---@param duration number spell time in frames
---@param stage Stage
---@param attack_id string unique id of the attack
function M.__create(stage, boss, duration, attack_id)
    local self = AttackSession.__create(stage, boss, duration, attack_id)

    local num_capture, num_attempt = require("BHElib.sessions.boss.capture_rate"):getCaptureRate(
            stage:getDifficulty(),
            attack_id,
            stage:getPlayer().class.SHOT_TYPE_ID)
    self.display_capture_rate = {num_capture, num_attempt}

    local TextClass = require("BHElib.ui.text_class")
    self.spell_info_text_object = TextClass(nil, color.WhiteSmoke, "font:noto_sans_sc", 0.28, nil)
    self.spell_info_pos = Vec2(110, 200)

    return self
end

---------------------------------------------------------------------------------------------------
---update

function M:render()
    AttackSession.render(self)

    local scale = 0.6

    local pos = self.spell_info_pos
    ---@type ui.TextClass
    local text_object = self.spell_info_text_object

    local ref_x = pos.x - 16 * scale
    local spell_status_y = pos.y - 26.5 * scale
    local text_y = pos.y - 11 * scale

    text_object:setFontAlign("right")
    -- spell bonus
    SetImageStateAndRender("image:boss_ui_spell_bonus", "mul+alpha", color.White, ref_x - 160 * scale, spell_status_y, scale)
    if self:isFail() then
        SetImageStateAndRender("image:boss_ui_spell_bonus_failed", "mul+alpha", color.White, ref_x - 96 * scale, spell_status_y, 0.9 * scale)
    else
        local spell_bonus = 20000000
        text_object:setText(tostring(spell_bonus))
        text_object:render(ref_x - 4 * scale, text_y)
    end

    -- capture rate
    SetImageStateAndRender("image:boss_ui_spell_capture_rate", "mul+alpha", color.White, ref_x, spell_status_y + 1 * scale, scale)
    local capture_rate = self.display_capture_rate
    if capture_rate[1] > 999 then
        SetImageStateAndRender("image:boss_ui_spell_master", "mul+alpha", color.White, ref_x + 64 * scale, spell_status_y, 0.9 * scale)
    else
        local capture_rate_str = tostring(capture_rate[1]).."/"..tostring(capture_rate[2])
        text_object:setText(capture_rate_str)
        text_object:render(ref_x + 136 * scale, text_y)
    end

    -- spell name
    SetImageStateAndRender("image:boss_ui_spell_name_decoration", "mul+alpha", color.White, pos.x - 50 * scale, pos.y - 17 * scale, 1.5 * scale)
    text_object:setFontAlign("right")
    text_object:setText(self.SPELL_DISPLAY_NAME)
    text_object:render(pos.x + 66 * scale, pos.y + 15 * scale)
end

return M