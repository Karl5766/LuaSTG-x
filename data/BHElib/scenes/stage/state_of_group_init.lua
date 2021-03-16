---------------------------------------------------------------------------------------------------
---state_of_group_init.lua
---author: Karl
---date: 2021.3.10
---desc: Defines the SceneGroupInitState object, which is created and used for initialization of
---     the initial state of an entire play-through, which may contain several levels.
---modifier:
---------------------------------------------------------------------------------------------------

---@class SceneGroupInitState
local InitState = LuaClass("scenes.SceneGroupInitState")

---create and return a default init state;
---the attributes of an object of this class should not be modified more than once,
---except for initialization immediately following creating the object
function InitState.__create()
    local self = {}

    self.player_class_id = nil
    self.stage_id_array = nil
    self.is_replay = nil
    self.replay_path_for_write = nil
    self.replay_path_for_read = nil

    return self
end

return InitState