---------------------------------------------------------------------------------------------------
---single_boss_with_spell_boss_fight.lua
---author: Karl
---date created: 2021.7.15
---desc: Defines the base objects for a single boss, non/spell format boss fight
---------------------------------------------------------------------------------------------------

local BossFight = require("BHElib.units.boss.boss_fight")

---@class BossFight.SingleBossWithSpell:BossFight
local M = LuaClass("boss_fight.SingleBossWithSpell", BossFight)

--------------------------------------------------------------------------------------------------

---@param boss Prefab.Animation the boss sprite
---@param session_class_array table an array of classes of sessions to be played in order
function M.__create(boss, session_class_array)
    local self = BossFight.__create()
    self.boss = boss
    self.session_class_array = session_class_array
    self.current_session_index = 0
    return self
end

function M:update(dt)
    if not self.session then
        local classes = self.session_class_array
        local index = self.current_session_index
        if index >= #classes then
            -- quit boss fight
            self:setEndOfFight()
            return
        else
            -- go to next session
            index = index + 1
            self.current_session_index = index
            local SessionClass = classes[index]
            self:setSession(SessionClass(self.boss))
        end
    end

    -- self.session guaranteed not be nil here
    self:updateSession(dt)
end

return M