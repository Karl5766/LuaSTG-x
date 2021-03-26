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

local _input = require("BHElib.input.input_and_replay")
local _GlobalState = require("BHElib.scenes.stage.state_of_global")

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
---@param stage_init_state GameSceneInitState specifies the initial state of the stage
---@param group_init_state SceneGroupInitState a table containing the global initial state of the play-through
---@param replay_io_manager ReplayIOManager an object that manages the replay read and write
---@return Stage a stage object
function Stage.__create(group_init_state, stage_init_state, replay_io_manager)
    local self = GameScene.__create()

    self.timer = 0

    self.group_init_state = group_init_state
    self.stage_init_state = stage_init_state
    self.replay_io_manager = replay_io_manager
    self.global_state = _GlobalState(group_init_state.is_replay)

    self.is_paused = false  -- for pause menu

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
end

---@return string scene type
function Stage.getSceneType()
    return "stage"
end

---------------------------------------------------------------------------------------------------
---instance method

---@return cc.Scene a new cocos scene
function Stage:createScene()
    ---@type GameSceneInitState
    local stage_init_state = self.stage_init_state
    local group_init_state = self.group_init_state

    -- set random seed
    ran:Seed(stage_init_state.random_seed)

    -- init score
    self.score = stage_init_state.init_score

    ---TOBEADDED: initialize the player

    self.replay_io_manager:startNewScene()  -- clear input from last scene, setup replay reader/writer

    return GameScene.createScene(self)
end

---for game scene transition;
---cleanup before exiting the scene; overwritten in case anything is changed during the scene of
---subclasses
function Stage:cleanup()
    GameScene.cleanup(self)

    --TODO:implement multi stage replay
    self.replay_io_manager:finishCurrentScene(self)
    self.replay_io_manager:cleanup()
end

---construct the initialization parameters for the next scene
---@return GameSceneInitState, SceneGroupInitState, table init parameters for Stage.__create
function Stage:constructNextSceneInitState()
    local GameSceneInitState = require("BHElib.scenes.stage.state_of_scene_init")
    local cur_init_state = self.stage_init_state
    local next_init_state = GameSceneInitState()

    next_init_state.random_seed = cur_init_state.random_seed  -- use the same random seed
    next_init_state.score = self.score
    ---TOBEADDED: initialize player info as well

    -- update global state
    self.global_state:completeCurrentScene(cur_init_state)
    self.global_state:advanceScene()

    return self.group_init_state, next_init_state
end

---@return boolean if the state is entered in replay mode
function Stage:isReplay()
    return self.replay_io_manager:isReplay()
end

---ends the play-through and go back to menu
function Stage:completeSceneGroup()
    local Menu = require("BHElib.scenes.menu.menu_scene")
    local SceneTransition = require("BHElib.scenes.scene_transition")

    local task_spec = {"no_task"}

    SceneTransition.transitionTo(self, Menu(task_spec))
end

---override base class method for pause menu
function Stage:updateSceneAndObjects(dt)
    if _input.isAnyDeviceKeyJustChanged("escape", false, true) and
        not self.is_paused then

        self.is_paused = true
        local PauseMenu = require("BHElib.scenes.stage.pause_menu")
        self.pause_menu = PauseMenu(self)
    end

    if self.is_paused then
        -- only update device input, ignore recorded input
        GameScene.updateUserInput(self)

        if not self.pause_menu:update(dt) then
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


return Stage