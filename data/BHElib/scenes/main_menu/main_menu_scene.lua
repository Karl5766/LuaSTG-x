---------------------------------------------------------------------------------------------------
---main_menu_scene.lua
---author: Karl
---date: 2021.3.4
---desc: implements the main menu
---------------------------------------------------------------------------------------------------

local GameScene = require("BHElib.scenes.game_scene")

---@class MenuScene:GameScene
local M = LuaClass("scenes.Menu", GameScene)

-- require modules
local SceneInitState = require("BHElib.scenes.stage.state_of_scene_init")
local ReplayFileReader = require("BHElib.input.replay_file_reader")
local FileStream = require("file_system.file_stream")

local MenuConst = require("BHElib.ui.menu.menu_global")
local Ustorage = require("util.universal_id")

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
---@return MenuManager
function M.__create(menu_manager)
    local self = GameScene.__create()

    self.menu_manager = menu_manager
    menu_manager:setMenuScene(self)

    return self
end

---create and return the cocos scene of the menu scene
---@return cc.Scene a new cocos scene
function M:createScene()
    return GameScene.createScene(self)
end

---construct the next stage
---@return Stage an object of Stage class
function M:createNextAndCleanupCurrentScene()
    -- for all stages

    self:endSession()

    local menu_manager = self.menu_manager

    local is_replay = menu_manager:queryChoice("is_replay") ~= nil
    local game_mode = menu_manager:queryChoice("game_mode")

    if game_mode == nil and not is_replay then
        return nil  -- exit the game
    end

    local start_stage_in_replay = 1
    local replay_path_for_read

    -- create init states for stage and the scene group
    local scene_init_state
    local group_init_state
    if is_replay then
        ---replay mode
        -- read from file
        replay_path_for_read = menu_manager:queryChoice("replay_path_for_read")
        local file_stream = FileStream(replay_path_for_read, "rb")
        local replay_file_reader = ReplayFileReader(file_stream, start_stage_in_replay)
        local replay_summaries = replay_file_reader:readSummariesFromFile()

        group_init_state = table.deepcopy(replay_summaries.scene_group_summary.group_init_state)
        local first_scene_summary = replay_summaries.scene_summary_array[1]
        scene_init_state = first_scene_summary.scene_init_state
    else
        ---game mode
        -- use default settings
        group_init_state = table.deepcopy(M.default_group_init_state)
        scene_init_state = SceneInitState()
        scene_init_state.player_resource.num_life = 2
        scene_init_state.player_resource.num_bomb = 3
        scene_init_state.player_resource.num_power = 0
        scene_init_state.player_resource.num_graze = 0
        scene_init_state.random_seed = ((os.time() % 65536) * 877) % 65536
    end
    -- modify status that is not the same as when the replay is recorded
    group_init_state.is_replay = is_replay
    group_init_state.replay_path_for_read = replay_path_for_read
    group_init_state.replay_path_for_write = self.menu_manager:getTempReplayPath()
    group_init_state.start_stage_in_replay = start_stage_in_replay

    local SceneGroup = require("BHElib.scenes.stage.scene_group")
    local next_scene_group = SceneGroup(group_init_state)

    -- find the stage class of the first stage
    local stage_id = next_scene_group:getCurrentSceneId()
    local StageClass = Ustorage:getById(stage_id)

    local next_stage = StageClass(scene_init_state, next_scene_group)
    return next_stage
end

function M:endSession()
    self.menu_manager:cleanup()  -- order doesn't matter

    GameScene.endSession(self)
end

---@param dt number elapsed time
function M:update(dt)
    GameScene.update(self, dt)

    self.menu_manager:update(dt)
end

local _hud_painter = require("BHElib.ui.hud_painter")
function M:render()
    GameScene.render(self)
    _hud_painter:drawHudBackground(
            "image:menu_hud_background",
            1.3)
end


---------------------------------------------------------------------------------------------------
---short init parameter list

function M.shortInit(task_spec)
    local MenuManager = require("BHElib.scenes.main_menu.main_menu_manager")
    local self = M(MenuManager(task_spec, "data/BHElib/input/current", "replay"))
    return self
end


return M