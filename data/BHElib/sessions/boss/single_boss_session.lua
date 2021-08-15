---------------------------------------------------------------------------------------------------
---single_boss_session.lua
---author: Karl
---date created: 2021.8.5
---desc: Defines the base objects for a single boss, non/spell format boss fight
---------------------------------------------------------------------------------------------------

local Session = require("BHElib.sessions.session")
local ScriptableSession = require("BHElib.sessions.scriptable_session")

---@class SingleBossSession:ScriptableSession
local M = LuaClass("SingleBossSession", ScriptableSession)

local Renderer = require("BHElib.ui.renderer_prefab")

--------------------------------------------------------------------------------------------------

---name of the boss displayed at the upper right corner
---@type string
M.BOSS_DISPLAY_NAME = nil

--------------------------------------------------------------------------------------------------
---init

---@param parent ParentSession the parent session of this session
---@param boss Prefab.Animation the boss sprite
---@param attack_session_class_array table an array of classes of the attack sessions to play
---@param script function a coroutine function that takes self as first parameter
function M.__create(parent, boss, attack_session_class_array, script)
    local self = ScriptableSession.__create(parent, script)
    self.boss = boss
    self.attack_session_class_array = attack_session_class_array
    self.renderer = Renderer(LAYER_TOP, self, "game")

    return self
end

function M:ctor()
    self.num_star = self:getNumSpellLeft(1)

    local TextClass = require("BHElib.ui.text_class")
    self.boss_name_text_object = TextClass(
            self.BOSS_DISPLAY_NAME,
            color.White,
            "font:noto_sans_sc",
            0.28,
            "left")
end

--------------------------------------------------------------------------------------------------
---setters and getters

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

--------------------------------------------------------------------------------------------------
---update

function M:update(dt)
    ---rewriting the update of the children by calling the base Session class method
    Session.update(self, dt)

    local is_updated = false

    while not is_updated do
        is_updated = self:updateChildren()  -- run children

        if is_updated == false then
            -- resume the script to find something to update
            if coroutine.status(self.coroutine) == "dead" then
                self:endSession()
                is_updated = true
            else
                self:resumeCoroutine()
            end
        end
    end
end

function M:render()
    self.boss_name_text_object:render(-180, 210)
    local max_width = 100
    local num_star = self.num_star
    local star_width = 13
    local star_height = 13
    if num_star > 5 then
        star_width = star_width / math.min(num_star, max_width) * 5
    end
    for i = 0, num_star - 1 do
        local xi, yi = i % max_width, int(i / max_width)
        local x, y = -176 + xi * star_width, 186 - yi * star_height
        SetImageStateAndRender("image:hint_spell_card_left", "mul+add", color.White, x, y, 0.75)
    end
end

--------------------------------------------------------------------------------------------------
---couroutine

---@param index number the index of the attack session in the array
function M:playAttackSessionByIndex(index)
    local Class = self.attack_session_class_array[index]
    Class(self, self.boss)  -- add as a child of self
    self:setNumStar(self:getNumSpellLeft(index))
end

--------------------------------------------------------------------------------------------------
---deletion

function M:endSession()
    ScriptableSession.endSession(self)
    Del(self.renderer)
end

return M