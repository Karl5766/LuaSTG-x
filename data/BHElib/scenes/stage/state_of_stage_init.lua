-------------------------------------------------------------------------------------------------
---state_of_stage_init.lua
---author: Karl
---date: 2021.3.10
---desc: Defines the GameSceneInitState object, which is created and used for initialization of
---     the initial state of a level.
---modifier:
-------------------------------------------------------------------------------------------------

---@class GameSceneInitState
local InitState = LuaClass("scenes.GameSceneInitState")

---create and return a default init state
---the attributes of an object of this class should not be modified more than once,
---except for initialization immediately following creating the object
function InitState.__create()
    local self = {}
    self.random_seed = 0
    self.player_init_state = {
        x = 0,
        y = -176,
        num_life = 1,
        num_bomb = 1,
    }
    self.init_score = 0

    return self
end

return InitState