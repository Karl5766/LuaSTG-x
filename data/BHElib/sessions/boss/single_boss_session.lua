---------------------------------------------------------------------------------------------------
---single_boss_session.lua
---author: Karl
---date created: 2021.8.5
---desc: Defines the base objects for a single boss, non/spell format boss fight
---------------------------------------------------------------------------------------------------

local ScriptableSession = require("BHElib.sessions.scriptable_session")

---@class SingleBossSession:ScriptableSession
local M = LuaClass("SingleBossSession", ScriptableSession)

local Renderer = require("BHElib.ui.renderer_prefab")

--------------------------------------------------------------------------------------------------

---@param boss Prefab.Animation the boss sprite
---@param attack_session_class_array table an array of classes of the attack sessions to play
---@param script function a coroutine function that takes self as first parameter
---@param stage Stage
function M.__create(stage, boss, attack_session_class_array, script)
    local self = ScriptableSession.__create(stage, script)
    self.boss = boss
    self.attack_session_class_array = attack_session_class_array
    self.renderer = Renderer(LAYER_TOP, self, "game")
    return self
end

function M:ctor()
    self.num_star = self:getNumSpellLeft(1)
end

---@return Prefab.Animation the boss sprite
function M:getBoss()
    return self.boss
end

function M:setNumStar(num_star)
    self.num_star = num_star
end

---@return number the size of attack session array
function M:getNumAttackSession()
    return #self.attack_session_class_array
end

---@return table
function M:getAttackSessionArray()
    return self.attack_session_class_array
end

---@param index number the index of the attack session in the array
function M:playAttackSessionByIndex(index)
    local Class = self.attack_session_class_array[index]
    local session = Class(self.boss, self.stage)
    self:setSession(session)
    self:setNumStar(self:getNumSpellLeft(index))
    coroutine.yield()
end

---@param index number index of the current attack that is on-going; enter 0 if at the start
---@return number of spell left
function M:getNumSpellLeft(index)
    local count = -1
    local classes = self.attack_session_class_array
    for i = index, #classes do
        if classes[i].IS_SPELL_CLASS then
            count = count + 1
        end
    end
    if count < 0 then
        count = 0
    end
    return count
end

function M:endSession()
    ScriptableSession.endSession(self)
    Del(self.renderer)
end

function M:render()
    RenderText("font:test", "boss name", -180, 210, 0.34, "left")
    local max_width = 100
    local num_star = self.num_star
    local star_width = 13
    local star_height = 13
    if num_star > 5 then
        star_width = star_width / math.min(num_star, max_width) * 5
    end
    for i = 0, num_star - 1 do
        local xi, yi = i % max_width, int(i / max_width)
        AlignedRender("image:hint_spell_card_left", -176 + xi * star_width, 186 - yi * star_height, 0.75)
    end
end

return M