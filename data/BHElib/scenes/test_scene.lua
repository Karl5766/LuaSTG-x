---------------------------------------------------------------------------------------------------
---menu_scene.lua
---author: Karl
---date: 2021.3.4
---desc: implements the main menu
---------------------------------------------------------------------------------------------------

local GameScene = require("BHElib.scenes.game_scene")

---@class TestScene:GameScene
local M = LuaClass("scenes.TestScene", GameScene)

-- require modules
local SceneInitState = require("BHElib.scenes.stage.state_of_scene_init")
local ReplayFileReader = require("BHElib.input.replay_file_reader")
local FileStream = require("util.file_stream")

local MenuConst = require("BHElib.scenes.menu.menu_const")
local Ustorage = require("util.universal_id")

---------------------------------------------------------------------------------------------------
---const

M.BACK_TO_MENU = 1
M.GO_TO_NEXT_STAGE = 2
M.RESTART_SCENE_GROUP = 3


---------------------------------------------------------------------------------------------------

local SceneTransition = require("BHElib.scenes.scene_transition")
local Input = require("BHElib.input.input_and_recording")
local GameSceneInitState = require("BHElib.scenes.stage.state_of_scene_init")
local SceneGroup = require("BHElib.scenes.stage.scene_group")

---------------------------------------------------------------------------------------------------
---class methods

---temporary used for setting the game parameters; must be called before the player select start game
function M.setStartGameInitState(group_init_state)
    M.default_group_init_state = group_init_state
end

---------------------------------------------------------------------------------------------------
---init

---create and return a new menu scene
---@param menu_manager MainMenuManager an object that manages the menu pages
---@return Menu a menu object
function M.__create(scene_init_state, scene_group)
    local self = GameScene.__create()

    self.scene_group = scene_group
    self.scene_init_state = scene_init_state

    scene_group:appendSceneInitState(scene_init_state)  -- record the init state of the current scene

    self.is_paused = false  -- for pause menu
    self.transition_type = nil  -- for scene transition

    return self
end

function M:createScene()
    ---@type GameSceneInitState
    local scene_init_state = self.scene_init_state
    local player_init_state = scene_init_state.player_init_state
    local group_init_state = self.scene_group:getSceneGroupInitState()

    -- set random seed
    ran:Seed(scene_init_state.random_seed)

    -- init score
    self.score = scene_init_state.init_score

    -- init player
    --local Player = Ustorage:getById(group_init_state.player_class_id)
    --local player = Player(self)
    --player.x = player_init_state.x
    --player.y = player_init_state.y
    --self.player = player

    local scene = GameScene.createScene(self)

    local canvas = require('imgui.Widget').ChildWindow('canvas')
    scene:addChild(canvas)

    self.exit_button = {}
    for j = 1, 12 do
        for i = 1, 100 do
            local exit_button = require("BHElib.input.recording_cc_button")(
                    "creator/image/default_btn_normal.png",
                    "creator/image/default_btn_pressed.png",
                    "creator/image/default_btn_disabled.png", 0)
            exit_button:setPosition(cc.p(200 + i * 6, 200 + j * 10))
            exit_button:setUseRecordingInput(true)
            canvas:addChild(exit_button, 0)
            table.insert(self.exit_button, exit_button)
        end
    end


    task.New(self, function()
        task.Wait(600)
        self:goToNextScene()
    end)

    return scene
end

---modify the game loop in GameScene:frameUpdate for pause menu
function M:frameUpdate(dt)
    -- check if pause menu should be created
    if Input:isAnyDeviceKeyJustChanged("escape", false, true) and
            not self.is_paused then

        -- create pause menu
        self.is_paused = true
        local PauseMenu = require("BHElib.scenes.stage.pause_menu.user_pause_menu")
        self.pause_menu = PauseMenu.Manager(self)
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

---construct the object for the next scene and return it
---@return GameScene the next game scene
function M:createNextAndCleanupCurrentScene()
    --local player_x, player_y = self.player.x, self.player.y  -- save object attributes
    self:cleanup()  -- cleanups; includes clearing all objects

    local transition_type = self.transition_type
    if transition_type == M.BACK_TO_MENU then
        -- go back to menu
        local Menu = require("BHElib.scenes.menu.menu_scene")
        return Menu.shortInit({"save_replay"})
    elseif transition_type == M.GO_TO_NEXT_STAGE then

        -- create scene init state for next stage
        local cur_init_state = self.scene_init_state
        local next_init_state = GameSceneInitState()

        next_init_state.random_seed = cur_init_state.random_seed  -- use the same random seed
        next_init_state.score = self:getScore()  -- set the start score of next stage the same as the current score
        next_init_state.player_init_state.x = player_x
        next_init_state.player_init_state.y = player_y

        -- update the scene group
        local scene_group = self.scene_group
        scene_group:completeCurrentScene(cur_init_state)
        scene_group:advanceScene()
        local stage_id = self.scene_group:getCurrentSceneId()
        local StageClass = Ustorage:getById(stage_id)

        -- pass over the scene group object and create the next stage
        local next_stage = StageClass(next_init_state, scene_group)
        return next_stage

    elseif transition_type == M.RESTART_SCENE_GROUP then
        -- start the game again, with the same scene init state and the scene group init state
        local scene_group = self.scene_group
        local next_init_state = scene_group:getFirstSceneInitState()
        local group_init_state = scene_group:getSceneGroupInitState()
        local next_scene_group = SceneGroup(group_init_state)

        -- find the first stage class
        local stage_id = next_scene_group:getCurrentSceneId()
        local StageClass = Ustorage:getById(stage_id)

        local next_stage = StageClass(next_init_state, next_scene_group)
        return next_stage
    else
        error("Error: Invalid stage transition type!")
    end
end

---construct the next stage
---@return Stage an object of Stage class
function M:createNextAndCleanupCurrentScene()
    -- for all stages

    self:cleanup()

    local Menu = require("BHElib.scenes.menu.menu_scene")
    return Menu.shortInit({"save_replay"})
end

function M:cleanup()
    GameScene.cleanup(self)
end

local BulletPrefabs = require("BHElib.units.enemy_bullet.bullet_prefabs")
local BulletTypes = require("BHElib.units.enemy_bullet.bullet_types")
---@param dt number elapsed time
function M:update(dt)
    GameScene.update(self, dt)

    for i = 1, 7 do
        local a = ran:Float(0, 360)
        local bullet_type_name = "grain"
        local bullet_info = BulletTypes.bullet_type_to_info[bullet_type_name]
        local b = BulletPrefabs.Base("grain", COLOR_BLUE, GROUP_ENEMY_BULLET, 11, bullet_info.size)
        b.x = 0
        b.y = 120
        b.vx = 4 * cos(a)
        b.vy = 4 * sin(a)
        b.rot = a
    end

    for i, button in ipairs(self.exit_button) do
        button:update(1)
    end
end

local hud_painter = require("BHElib.ui.hud_painter")
function M:render()
    GameScene.render(self)
    hud_painter.drawHudBackground(
            "image:menu_hud_background",
            1.3
    )
end

---------------------------------------------------------------------------------------------------
---direct transitions
---these transitions can be called almost anywhere through the current stage object

---go to the next stage
function M:goToNextStage()
    self.transition_type = M.GO_TO_NEXT_STAGE
    SceneTransition.transitionFrom(self, SceneTransition.instantTransition)
end

---ends the play-through and go back to menu
function M:completeSceneGroup()
    self.transition_type = M.BACK_TO_MENU
    SceneTransition.transitionFrom(self, SceneTransition.instantTransition)
end

---restart the scene group
function M:restartSceneGroup()
    self.transition_type = M.RESTART_SCENE_GROUP
    SceneTransition.transitionFrom(self, SceneTransition.instantTransition)
end

---go to next stage or end play-through depending on the progress in the scene group
function M:goToNextScene()
    if self.scene_group:isFinalScene() then
        self:completeSceneGroup()
    else
        self:goToNextStage()
    end
end

local _hud_painter = require("BHElib.ui.hud_painter")
---render stage hud
function M:render()
    GameScene.render(self)
    _hud_painter.draw(
            "image:menu_hud_background",
            1.3,
            "font:menu",
            "image:white"
    )
end

---------------------------------------------------------------------------------------------------
---short init parameter list

function M.shortInit(task_spec)
    local MenuManager = require("BHElib.scenes.main_menu.main_menu_manager")
    local self = M(MenuManager(task_spec, "data/BHElib/input/current", "replay"))
    return self
end


return M