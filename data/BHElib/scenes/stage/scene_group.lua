---------------------------------------------------------------------------------------------------
---scene_group.lua
---author: Karl
---date: 2021.3.27
---desc: Defines the SceneGroup class
---------------------------------------------------------------------------------------------------

---@class SceneGroup
local SceneGroup = LuaClass("BHElib.scenes.SceneGroup")

local ReplayIOManager = require("BHElib.input.replay_io_manager")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Insert = table.insert

---------------------------------------------------------------------------------------------------
---init

---create and return a SceneGroup object
---@param group_init_state SceneGroupInitState initial state of the scene group
---@return GlobalSceneState
function SceneGroup.__create(group_init_state)
    local self = {}

    self.group_init_state = group_init_state
    self.current_scene_num = 1
    self.completed_scene = 0
    self.scene_init_state_history_array = {} -- record init states of past scenes

    self.replay_io_manager = nil

    SceneGroup.setupReplayIOManager(self)

    return self
end

---------------------------------------------------------------------------------------------------
---setters and getters

---@return GameSceneInitState the initial state of the first scene in the scene group
function SceneGroup:getFirstSceneInitState()
    return self.scene_init_state_history_array[1]
end

---@return SceneGroupInitState the initial state of the scene group
function SceneGroup:getSceneGroupInitState()
    return self.group_init_state
end

---@return number the current stage number
function SceneGroup:getCurrentSceneNum()
    return self.current_scene_num
end

---@return string the current stage class id
function SceneGroup:getCurrentSceneId()
    return self.group_init_state.scene_id_array[self.current_scene_num]
end

---@return number number of stages completed
function SceneGroup:getCompletedSceneNum()
    return self.completed_scene
end

---@return ReplayIOManager an object that manages the replay read and write
function SceneGroup:getReplayIOManager()
    return self.replay_io_manager
end

---complete scene
function SceneGroup:completeCurrentScene()
    self.completed_scene = self.completed_scene + 1
end

---update the current stage num
function SceneGroup:advanceScene()
    self.current_scene_num = self.current_scene_num + 1
end

---remember the current stage init state
---@param scene_init_state GameSceneInitState the init state to remember
function SceneGroup:appendSceneInitState(scene_init_state)
    Insert(self.scene_init_state_history_array, scene_init_state)
end

---setup the replay io manager by the scene group init state
function SceneGroup:setupReplayIOManager()
    local group_init_state = self.group_init_state
    self.replay_io_manager = ReplayIOManager(
            group_init_state.is_replay,
            group_init_state.replay_path_for_read,
            group_init_state.replay_path_for_write,
            group_init_state.start_stage_in_replay
    )
end

return SceneGroup