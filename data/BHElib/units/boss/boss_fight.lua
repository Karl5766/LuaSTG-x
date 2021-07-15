---------------------------------------------------------------------------------------------------
---boss_fight.lua
---author: Karl
---date created: 2021.6.1
---desc: Defines the base objects for boss fights
---------------------------------------------------------------------------------------------------
---boss fight overview

-- (below I use the term spell to generally refer to boss attacks (as in other shmups))
--
-- 1. boss object init, this object does not have boss position etc. but keeps record of every
--      spell/dialogue to be played
--
-- 2. boss object is responsible for initializing the boss sprite animation, then creates and
--      enters the first spell/dialogue object, second spell/dialogue object and so on
--
-- 3. the boss object will inject the boss animation into each spell object, and the spell object
--      will use the position of the animation as the position of the boss
--
-- 4. in each spell, the spell object will create hitbox objects and synchronize their positions
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