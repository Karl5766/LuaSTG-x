---------------------------------------------------------------------------------------------------
---single_boss_session.lua
---author: Karl
---date created: 2021.8.5
---desc: Defines the base objects for a single boss, non/spell format boss fight
---------------------------------------------------------------------------------------------------

local ScriptableSession = require("BHElib.sessions.scriptable_session")

---@class SingleBossSession:ScriptableSession
local M = LuaClass("SingleBossSession", ScriptableSession)

--------------------------------------------------------------------------------------------------

---@param boss Prefab.Animation the boss sprite
---@param attack_session_class_array table an array of classes of the attack sessions to play
---@param script function a coroutine function that takes self as first parameter
function M.__create(boss, attack_session_class_array, script)
    local self = ScriptableSession.__create(script)
    self.boss = boss
    self.attack_session_class_array = attack_session_class_array
    return self
end

---@return Prefab.Animation the boss sprite
function M:getBoss()
    return self.boss
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
function M:setAttackSessionByIndex(index)
    local Class = self.attack_session_class_array[index]
    local session = Class(self.boss)
    self:setSession(session)
end

return M