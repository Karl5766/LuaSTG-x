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
local M = LuaClass("scenes.Stage", GameScene)

---------------------------------------------------------------------------------------------------

local SceneTransition = require("BHElib.scenes.game_scene_transition")
local Input = require("BHElib.input.input_and_recording")
local SceneGroup = require("BHElib.scenes.stage.scene_group")
local Ustorage = require("util.universal_id")

---------------------------------------------------------------------------------------------------
---init

---create and return a new stage instance, representing an actual play-through;
---the init state parameters should not be modified by the Stage object
---@param scene_init_state GameSceneInitState specifies the initial state of this stage
---@param scene_group SceneGroup current scene group, includes the global states of the play-through
---@return Stage a stage object
function M.__create(scene_init_state, scene_group)
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
---create scene

---@return cc.Scene a new cocos scene
function M:createScene()
    ---@type GameSceneInitState
    local scene_init_state = self.scene_init_state
    local player_pos = scene_init_state.player_pos
    local group_init_state = self.scene_group:getSceneGroupInitState()

    -- set random seed
    ran:Seed(scene_init_state.random_seed)

    -- init score
    self.score = scene_init_state.score

    -- init player
    local Player = Ustorage:getById(group_init_state.player_class_id)
    local player = Player(self, nil, scene_init_state.player_resource)
    player.x = player_pos.x
    player.y = player_pos.y
    self:setPlayer(player)

    self.replay_io_manager:startNewScene()  -- clear input from last scene, setup replay reader/writer

    return GameScene.createScene(self)
end

---------------------------------------------------------------------------------------------------
---setters and getters

---@return boolean if the state is entered in replay mode
function M:isReplay()
    return self.replay_io_manager:isReplay()
end

---@return number difficulty
function M:getDifficulty()
    return self.scene_init_state.difficulty
end

---@return number self.score
function M:getScore()
    return self.score
end

---increase the score by a number
---@param inc_score number
function M:addScore(inc_score)
    self.score = self.score + inc_score
end

---triggered when a player misses or bombs
function M:onPlayerMissOrBomb()
    for session, _ in pairs(self.sessions) do
        local on_player_miss_or_bomb = session.onPlayerMissOrBomb
        if on_player_miss_or_bomb then
            on_player_miss_or_bomb(session)
        end
    end
end

---@param player Prefab.Player the player of this stage
function M:setPlayer(player)
    self.player = player
end

---@return Prefab.Player the (unique) player of the stage
function M:getPlayer()
    assert(self.player, "Error: Player does not exist!")
    return self.player
end

---@return gameplay_resources.Player resources that player initially holds
function M:getInitPlayerResource()
    return self.scene_init_state.player_resource
end

---------------------------------------------------------------------------------------------------
---scene update

---modify the game loop in GameScene:frameUpdate for pause menu
function M:frameUpdate(dt)
    -- update screen effects if any
    require("BHElib.unclassified.screen_effect"):update(dt)

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
function M:render()
    GameScene.render(self)
    _hud_painter:drawHudBackground("image:menu_hud_background", 1.3)
    _hud_painter:drawPlayfieldOutline("image:white")

    -- there can be multiple players exist, so use the interface that returns the unique player
    _hud_painter:drawResources(self, "font:test")
end

---update recorded device input for replay
function M:updateUserInput()
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
function M:endSession(continue_scene_group)
    GameScene.endSession(self)

    self.replay_io_manager:finishCurrentScene(self)
    if not continue_scene_group then
        self.replay_io_manager:finishCurrentSceneGroup(self)
        self.replay_io_manager:cleanup()
    end
end

---construct the object for the next scene and return it
---@return GameScene the next game scene
function M:createNextAndCleanupCurrentScene()
    local callback = self.transition_callback
    assert(callback, "Error: Stage transition callback does not exist!")
    return callback(self)
end

---------------------------------------------------------------------------------------------------
---direct transitions
---these transitions can be called almost anywhere through the current stage object

---terminate current scene and transition to a new one
---@param transition_callback function a function creates new scene and cleanup current scene
function M:transitionWithCallback(transition_callback)
    assert(type(transition_callback) == "function", "Error: Invalid transition callback!")
    self.transition_callback = transition_callback
    SceneTransition.transitionAtStartOfNextFrame(self)
end

---go to next stage or end play-through depending on the progress in the scene group
function M:goToNextScene()
    local callbacks = require("BHElib.scenes.stage.stage_transition_callbacks")
    if self.scene_group:isFinalScene() then
        self:transitionWithCallback(callbacks.createMenuAndSaveReplay)
    else
        self:transitionWithCallback(callbacks.goToNextStage)
    end
end

return M