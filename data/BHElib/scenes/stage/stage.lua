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

---------------------------------------------------------------------------------------------------

local SceneTransition = require("BHElib.scenes.scene_transition")
local Input = require("BHElib.input.input_and_recording")
local SceneGroup = require("BHElib.scenes.stage.scene_group")
local Ustorage = require("util.universal_id")

---------------------------------------------------------------------------------------------------
---const

Stage.BACK_TO_MENU = 1
Stage.GO_TO_NEXT_STAGE = 2
Stage.RESTART_SCENE_GROUP = 3
Stage.RESTART_AND_KEEP_RECORDING = 4

---------------------------------------------------------------------------------------------------
---virtual methods

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

    self.scene_group = scene_group
    self.scene_init_state = scene_init_state

    scene_group:appendSceneInitState(scene_init_state)  -- record the init state of the current scene

    self.replay_io_manager = scene_group:getReplayIOManager()
    self.is_paused = false  -- for pause menu
    self.transition_type = nil  -- for scene transition
    self.end_replay = false

    return self
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

---@param player PlayerBase the player of this stage
function Stage:setPlayer(player)
    self.player = player
end

---@return Prefab.Player the (unique) player of the stage
function Stage:getPlayer()
    return self.player
end

---@return number, number the number of initial player life and bombs
function Stage:getInitPlayerResources()
    local player_init_state = self.scene_init_state.player_init_state
    return player_init_state.num_life, player_init_state.num_bomb
end

---------------------------------------------------------------------------------------------------
---create scene

---@return cc.Scene a new cocos scene
function Stage:createScene()
    ---@type GameSceneInitState
    local scene_init_state = self.scene_init_state
    local player_init_state = scene_init_state.player_init_state
    local group_init_state = self.scene_group:getSceneGroupInitState()

    -- set random seed
    ran:Seed(scene_init_state.random_seed)

    -- init score
    self.score = scene_init_state.init_score

    -- init player
    local Player = Ustorage:getById(group_init_state.player_class_id)
    local player = Player(self, nil)
    player.x = player_init_state.x
    player.y = player_init_state.y
    self.player = player

    self.replay_io_manager:startNewScene()  -- clear input from last scene, setup replay reader/writer

    return GameScene.createScene(self)
end

---------------------------------------------------------------------------------------------------
---scene update

---modify the game loop in GameScene:frameUpdate for pause menu
function Stage:frameUpdate(dt)
    -- update screen effects if any
    require("BHElib.screen_effect"):update(dt)

    -- check if pause menu should be created
    if Input:isAnyDeviceKeyJustChanged("escape", false, true) and
            not self.is_paused then

        -- create pause menu
        self.is_paused = true
        local PauseMenu = require("BHElib.scenes.stage.pause_menu.user_pause_menu")
        self.pause_menu = PauseMenu(self, self.replay_io_manager:isReplay())
    end

    if self.is_paused then
        -- only update device input, ignore recorded input
        GameScene.updateUserInput(self)

        self.pause_menu:update(dt)
        self.is_paused = self.pause_menu:continueMenu()
    else
        self:updateSceneAndObjects(dt)  -- call base method on non-menu mode
    end
end

local _hud_painter = require("BHElib.ui.hud_painter")
---render stage hud
function Stage:render()
    GameScene.render(self)
    _hud_painter:draw(
            "image:menu_hud_background",
            1.3,
            "image:white"
    )

    -- there can be multiple players exist, so use the interface that returns the unique player
    _hud_painter:drawPlayerResources(self:getPlayer())
end

---update recorded device input for replay
function Stage:updateUserInput()
    -- update device input
    GameScene.updateUserInput(self)

    -- update recorded input
    local replay_io_manager = self.replay_io_manager
    if replay_io_manager:isReplay() and replay_io_manager:isStageEndReached() then
        -- end of replay reached

        self.is_paused = true
        local PauseMenu = require("BHElib.scenes.stage.pause_menu.replay_end_menu")
        self.pause_menu = PauseMenu(self)
    else
        replay_io_manager:updateUserInput()
    end

    self:setPlaybackSpeed(1)
    if replay_io_manager:isReplay() and not self.is_paused then
        if Input:isAnyDeviceKeyDown("left") or
                Input:isAnyDeviceKeyDown("right") or
                Input:isAnyDeviceKeyDown("up") or
                Input:isAnyDeviceKeyDown("down") then
            replay_io_manager:changeToNonReplayMode()
        elseif Input:isAnyDeviceKeyDown("repslow") then
            self:setPlaybackSpeed(0.25)
        elseif Input:isAnyDeviceKeyDown("repfast") then
            self:setPlaybackSpeed(4)
        end
    end
end

---------------------------------------------------------------------------------------------------
---transition implementation

---for game scene transition;
---for cleaning up before exiting the scene;
---@param continue_scene_group boolean if true, continue replay; if false, stop and finish up replay io
function Stage:cleanup(continue_scene_group)
    GameScene.cleanup(self)

    self.replay_io_manager:finishCurrentScene(self)
    if not continue_scene_group then
        self.replay_io_manager:finishCurrentSceneGroup(self)
        self.replay_io_manager:cleanup()
    end
end

---construct the object for the next scene and return it
---@return GameScene the next game scene
function Stage:createNextAndCleanupCurrentScene()
    local callback = self.transition_callback
    assert(callback, "Error: Stage transition callback does not exist!")
    return callback(self)
end

---------------------------------------------------------------------------------------------------
---direct transitions
---these transitions can be called almost anywhere through the current stage object

---terminate current scene and transition to a new one
---@param transition_callback function a function creates new scene and cleanup current scene
function Stage:transitionWithCallback(transition_callback)
    assert(type(transition_callback) == "function", "Error: Invalid transition callback!")
    self.transition_callback = transition_callback
    SceneTransition.transitionFrom(self, SceneTransition.instantTransition)
end

---go to next stage or end play-through depending on the progress in the scene group
function Stage:goToNextScene()
    local callbacks = require("BHElib.scenes.stage.stage_transition_callbacks")
    if self.scene_group:isFinalScene() then
        self:transitionWithCallback(callbacks.createMenuAndSaveReplay)
    else
        self:transitionWithCallback(callbacks.goToNextStage)
    end
end

return Stage