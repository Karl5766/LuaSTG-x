---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Karl2.
--- DateTime: 2021/6/1 23:29
---

local SingleBossSession = require("BHElib.sessions.boss.single_boss_session")

---@class BossSession.Nue:SingleBossSession
local M = LuaClass("boss_fight.Nue", SingleBossSession)

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local Yield = coroutine.yield

---------------------------------------------------------------------------------------------------

---@type Prefab.NueAnimation
local _Animation = require("enemy.nue_boss_animation")

local _Spell1 = require("enemy.nue_spell1")
local _Dialogue1 = require("enemy.nue_dialogue")

---------------------------------------------------------------------------------------------------

---@param self BossSession.Nue
local function Script(self)
    local boss = self.boss

    boss.x = -100
    boss.y = 300

    self:playSession(_Dialogue1())
    self:playAttackSessionByIndex(1)
end

function M.__create(stage)
    local spell_class_array = {
        _Spell1,
    }
    local boss = _Animation()
    local self = SingleBossSession.__create(boss, spell_class_array, Script, stage)
    return self
end

return M