---------------------------------------------------------------------------------------------------
---stage.lua
---author: Karl
---date: 2021.2.12
---references: -x/src/core/stage.lua, -x/src/core/corefunc.lua, -x/src/app/views/GameScene.lua
---desc: Defines the Stage class; every subclass of Stage represents a unique stage, and every
---     instance of them represent a playthrough
---------------------------------------------------------------------------------------------------

local GameScene = require("BHElib.scenes.game_scene")  -- superclass

---@class Stage:GameScene
---@comment an instance of this class represents a shmup stage.
local Stage = LuaClass("scenes.Stage", GameScene)

---@comment an array of all stages created by Stage.new().
local _all_stages = {}

---------------------------------------------------------------------------------------------------

local SceneTransition = require("BHElib.scenes.scene_transition")
local _input = require("BHElib.input.input_and_replay")
local GameSceneInitState = require("BHElib.scenes.stage.state_of_scene_init")
local SceneGroup = require("BHElib.scenes.stage.scene_group")

---------------------------------------------------------------------------------------------------
---const

Stage.BACK_TO_MENU = 1
Stage.GO_TO_NEXT_STAGE = 2
Stage.RESTART_SCENE_GROUP = 3

---------------------------------------------------------------------------------------------------
---virtual methods

---return the stage id
---@return string unique string that identifies the stage
---virtual Stage:getSid()

---virtual Stage:getDisplayName()

---------------------------------------------------------------------------------------------------
---class method

---create and return a new stage instance, representing an actual play-through;
---the init state parameters should not be modified by the Stage object
---@param scene_init_state GameSceneInitState specifies the initial state of this stage
---@param scene_group SceneGroup current scene group, includes the global states of the play-through
---@return Stage a stage object
function Stage.__create(scene_init_state, scene_group)
    local self = GameScene.__create()

    self.timer = 0

    self.scene_group = scene_group
    self.scene_init_state = scene_init_state

    scene_group:appendSceneInitState(scene_init_state)  -- record the init state of the current scene

    self.replay_io_manager = scene_group:getReplayIOManager()
    self.is_paused = false  -- for pause menu
    self.transition_type = nil  -- for scene transition

    return self
end

---@return table an array of all stages created by Stage.new()
function Stage.getAll()
    return _all_stages
end

---register the stage for look up
---@param stage Stage a class derived from Stage to register
function Stage.registerStageClass(stage)
    table.insert(_all_stages, stage)
end

---@param id string the id to look for
---@return Stage a class derived from Stage with the given id; if not found, return nil
function Stage.findStageClassById(id)
    for i = 1, #_all_stages do
        if _all_stages[i]:getSid() == id then
            return _all_stages[i]
        end
    end
    error("Error: stage class is not found!")
end

---@return string scene type
function Stage.getSceneType()
    return "stage"
end

---------------------------------------------------------------------------------------------------
---setters and getters

---@return boolean if the state is entered in replay mode
function Stage:isReplay()
    return self.replay_io_manager:isReplay()
end

function Stage:getScore()
    return self.score
end

---------------------------------------------------------------------------------------------------
---create scene

---@return cc.Scene a new cocos scene
function Stage:createScene()
    ---@type GameSceneInitState
    local scene_init_state = self.scene_init_state

    -- set random seed
    ran:Seed(scene_init_state.random_seed)

    -- init score
    self.score = scene_init_state.init_score

    ---TOBEADDED: initialize the player

    self.replay_io_manager:startNewScene()  -- clear input from last scene, setup replay reader/writer

    return GameScene.createScene(self)
end

---------------------------------------------------------------------------------------------------
---scene update

---override base class method for pause menu
---update (only) the scene and the objects, but does not check for scene transition
function Stage:updateSceneAndObjects(dt)
    -- check if pause menu should be created
    if _input.isAnyDeviceKeyJustChanged("escape", false, true) and
            not self.is_paused then

        self.is_paused = true
        local PauseMenu = require("BHElib.scenes.stage.pause_menu.user_pause_menu")
        self.pause_menu = PauseMenu(self)
    end

    if self.is_paused then
        -- only update device input, ignore recorded input
        GameScene.updateUserInput(self)

        if not self.pause_menu:update(dt) then  -- will return false when the menu chooses to resume the game
            self.is_paused = false
        end
    else
        GameScene.updateSceneAndObjects(self, dt)  -- call base method on non-menu mode
    end
end

---update the stage itself
function Stage:update(dt)
    GameScene.update(self, dt)
    self.timer = self.timer + dt
end

local _hud_painter = require("BHElib.ui.hud_painter")
---render stage hud
function Stage:render()
    GameScene.render(self)
    _hud_painter.draw(
            "image:menu_hud_background",
            1.3,
            "font:menu",
            "image:white"
    )
end

---called in frameFunc()
---update recorded device input for replay
function Stage:updateUserInput()
    -- update device input
    GameScene.updateUserInput(self)

    -- update recorded input
    self.replay_io_manager:updateUserInput()
end

---------------------------------------------------------------------------------------------------
---for transition

---for game scene transition;
---cleanup before exiting the scene; overwritten in case anything is changed during the scene of
---subclasses
function Stage:cleanup()
    GameScene.cleanup(self)

    self.replay_io_manager:finishCurrentScene(self)
    if self.transition_type ~= Stage.GO_TO_NEXT_STAGE then
        self.replay_io_manager:finishCurrentSceneGroup(self)
        self.replay_io_manager:cleanup()
    end
end

---construct the object for the next scene and return it
---@return GameScene the next game scene
function Stage:createNextGameScene()
    local transition_type = self.transition_type
    if transition_type == Stage.BACK_TO_MENU then
        -- go back to menu
        local Menu = require("BHElib.scenes.menu.menu_scene")
        local task_spec = {"save_replay"}
        return Menu(task_spec)
    elseif transition_type == Stage.GO_TO_NEXT_STAGE then

        -- create scene init state for next stage
        local cur_init_state = self.scene_init_state
        local next_init_state = GameSceneInitState()

        next_init_state.random_seed = cur_init_state.random_seed  -- use the same random seed
        next_init_state.score = self:getScore()  -- set the start score of next stage the same as the current score
        ---TOBEADDED: initialize player info as well

        -- update the scene group
        local scene_group = self.scene_group
        scene_group:completeCurrentScene(cur_init_state)
        scene_group:advanceScene()
        local stage_id = self.scene_group:getCurrentSceneId()
        local StageClass = Stage.findStageClassById(stage_id)

        -- pass over the scene group object and create the next stage
        local next_stage = StageClass(next_init_state, scene_group)
        return next_stage

    elseif transition_type == Stage.RESTART_SCENE_GROUP then
        -- start the game again, with the same scene init state and the scene group init state
        local scene_group = self.scene_group
        local next_init_state = scene_group:getFirstSceneInitState()
        local group_init_state = scene_group:getSceneGroupInitState()
        local next_scene_group = SceneGroup(group_init_state)

        -- find the first stage class
        local stage_id = next_scene_group:getCurrentSceneId()
        local StageClass = Stage.findStageClassById(stage_id)

        local next_stage = StageClass(next_init_state, next_scene_group)
        return next_stage
    else
        error("Error: Invalid stage transition type!")
    end
end

---construct the initialization parameters for the next scene
function Stage:completeScene()
    self.transition_type = Stage.GO_TO_NEXT_STAGE
    SceneTransition.transitionTo(self, SceneTransition.instantTransition)
end

---ends the play-through and go back to menu
function Stage:completeSceneGroup()
    self.transition_type = Stage.BACK_TO_MENU
    SceneTransition.transitionTo(self, SceneTransition.instantTransition)
end

---restart the scene group
function Stage:restartSceneGroup()
    self.transition_type = Stage.RESTART_SCENE_GROUP
    SceneTransition.transitionTo(self, SceneTransition.instantTransition)
end

return Stage