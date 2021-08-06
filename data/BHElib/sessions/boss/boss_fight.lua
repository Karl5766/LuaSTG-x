---------------------------------------------------------------------------------------------------
---boss_fight.lua
---author: Karl
---date created: 2021.6.1
---desc: Defines the base objects for boss fights
---------------------------------------------------------------------------------------------------
---boss fight overview

-- (below I use the term spell to generally refer to boss attacks (as in other shmups))
--
-- 1. the session will pass the boss animation object into each spell session, and the spell
--      session will use the position of the animation as the position of the boss
--
-- 2. in each spell session, the spell will create hitbox objects and synchronize their positions
--      to the animation; when the hitbox gets shoot, the boss loses hp, and eventually the hitbox
--      is shot down, and the spell will end at that moment; the boss then goes on to the next
--      spell

---------------------------------------------------------------------------------------------------

---@class BossFight
local BossFight = LuaClass("units.boss.BossFight")

function BossFight.__create()
    local self = {
        session = nil,
        continue_flag = true,  -- set to false to end the boss fight
    }
    return self
end

function BossFight:updateSession(dt)
    assert(self.session, "Error: Boss fight session does not exist!")

    if self.continue_flag then
        local session = self.session
        session:update(dt)
        if not session:continueSession() then
            self.session = nil
        end
    end
end

function BossFight:setSession(session)
    self.session = session
end

function BossFight:continueBossFight()
    return self.continue_flag
end

---set the boss fight to stop
function BossFight:setEndOfFight()
    self.continue_flag = false
end

return BossFight