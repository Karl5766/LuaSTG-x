-------------------------------------------------------------------------------------------------
---global_scene_state.lua
---author: Karl
---date: 2021.3.10
---desc: Defines the GlobalSceneState object, which is for passing information among stages in
---     a play-through
---modifier:
-------------------------------------------------------------------------------------------------

---@class GlobalSceneState
local GlobalState = LuaClass("scenes.GlobalInitState")

---create and return a GlobalSceneState object
---@is_replay boolean whether the scene is entered in replay mode
---@return GlobalSceneState
function GlobalState.__create(is_replay)
    local self = {}

    self.is_replay = is_replay
    self.current_scene_num = 1
    self.completed_scene = 0
    self.scene_init_state_history_array = {} -- record init states of past scenes

    return self
end

---remember the current stage init state and update the current stage num
---@param current_scene_init_state GameSceneInitState the init state to remember
function GlobalState:completeCurrentScene(current_scene_init_state)
    table.insert(self.scene_init_state_history_array, current_scene_init_state)
    self.completed_scene = self.completed_scene + 1
end

---update the state as going to the next scene
function GlobalState:advanceScene(current_scene_init_state)
    self.current_scene_num = self.current_scene_num + 1
end

---@return number the current stage number
function GlobalState:getCurrentSceneNum()
    return self.current_scene_num
end

---@return number number of stages completed
function GlobalState:getCompletedSceneNum()
    return self.completed_scene
end

return GlobalState