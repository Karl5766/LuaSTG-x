---------------------------------------------------------------------------------------------------
---stage_transition_callbacks.lua
---author: Karl
---date: 2021.7.8
---desc: implements stage transition callbacks that creates the next scene and clean up the current
---     stage; these functions are supposed to be fed to the stage object as callbacks via the
---     parameters of the scene transition function
---------------------------------------------------------------------------------------------------

---@class StageTransitionCallbacks
local _callbacks = {}

local SceneInitState = require("BHElib.scenes.stage.state_of_scene_init")
local SceneGroup = require("BHElib.scenes.stage.scene_group")
local Ustorage = require("util.universal_id")

---------------------------------------------------------------------------------------------------
---from stage to menu

---create a menu scene
---@param stage Stage the stage to go from
---@param task_spec any specifies the tasks to perform on the menu
---@return GameScene the next scene to go to
local function CreateMenuWithTaskSpec(stage, task_spec)
    stage:cleanup(false)

    -- go back to menu
    local MenuSceneClass = require("BHElib.scenes.main_menu.main_menu_scene")
    local menu_scene = MenuSceneClass.shortInit(task_spec)
    return menu_scene
end

---create a menu scene without saving replay
---@param stage Stage the stage to go from
---@return GameScene the next scene to go to
function _callbacks.createMenuWithoutSavingReplay(stage)
    return CreateMenuWithTaskSpec(stage, {"no_task"})
end

---create a menu scene while saving replay
---@param stage Stage the stage to go from
---@return GameScene the next scene to go to
function _callbacks.createMenuAndSaveReplay(stage)
    return CreateMenuWithTaskSpec(stage, {"save_replay"})
end

---------------------------------------------------------------------------------------------------
---from stage to stage

---@param stage Stage the stage to go from
---@param next_init_state GameSceneInitState
local function InheritGameplayResources(stage, next_init_state)
    next_init_state.score = stage:getScore()

    local next_player_init_state = next_init_state.player_init_state
    local cur_player = stage:getPlayer()

    next_player_init_state.x = cur_player.x
    next_player_init_state.y = cur_player.y

    next_player_init_state.num_life,
        next_player_init_state.num_bomb,
        next_player_init_state.num_graze = cur_player:getPlayerResources()
end

---create a menu scene while saving replay
---@param stage Stage the stage to go from
---@return GameScene the next scene to go to
function _callbacks.restartSceneGroup(stage)
    stage:cleanup(false)

    -- start the game again, with the same scene init state and the scene group init state
    local scene_group = stage.scene_group
    local next_init_state = scene_group:getFirstSceneInitState()
    local group_init_state = scene_group:getSceneGroupInitState()
    local next_scene_group = SceneGroup(group_init_state)

    -- find the first stage class
    local stage_id = next_scene_group:getCurrentSceneId()
    local StageClass = Ustorage:getById(stage_id)

    local next_stage = StageClass(next_init_state, next_scene_group)
    return next_stage
end

---create a menu scene while saving replay
---@param stage Stage the stage to go from
---@return GameScene the next scene to go to
function _callbacks.restartStageAndKeepRecording(stage)
    local next_init_state = SceneInitState()
    InheritGameplayResources(stage, next_init_state)
    stage:cleanup(true)

    -- create scene init state for next stage
    local cur_init_state = stage.scene_init_state

    next_init_state.random_seed = ran:Int(0, 65535)

    -- update the scene group
    local scene_group = stage.scene_group
    scene_group:completeCurrentScene(cur_init_state)
    scene_group:restartScene()
    local stage_id = stage[".classname"]
    local StageClass = Ustorage:getById(stage_id)

    -- pass over the scene group object and create the next stage
    local next_stage = StageClass(next_init_state, scene_group)
    return next_stage
end

---create a menu scene while saving replay
---@param stage Stage the stage to go from
---@return GameScene the next scene to go to
function _callbacks.goToNextStage(stage)
    local next_init_state = SceneInitState()
    InheritGameplayResources(stage, next_init_state)
    stage:cleanup(true)

    -- create scene init state for next stage
    local cur_init_state = stage.scene_init_state

    next_init_state.random_seed = ran:Int(0, 65535)

    -- update the scene group
    local scene_group = stage.scene_group
    scene_group:completeCurrentScene(cur_init_state)
    scene_group:advanceScene()
    local stage_id = stage.scene_group:getCurrentSceneId()
    local StageClass = Ustorage:getById(stage_id)

    -- pass over the scene group object and create the next stage
    local next_stage = StageClass(next_init_state, scene_group)
    return next_stage
end

return _callbacks