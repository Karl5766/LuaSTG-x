---------------------------------------------------------------------------------------------------
---menu_scene.lua
---author: Karl
---date: 2021.3.4
---references:
---desc: implements the main menu
---------------------------------------------------------------------------------------------------

local GameScene = require("BHElib.scenes.game_scene")

---@class Menu:GameScene
local Menu = LuaClass("scenes.Menu", GameScene)

-- require modules
require("BHElib.scenes.menu.menu_page")
local SceneTransition = require("BHElib.scenes.scene_transition")
local _menu_transition = require("BHElib.scenes.menu.menu_page_transition")
local SceneInitState = require("BHElib.scenes.stage.state_of_scene_init")
local SceneGroupInitState = require("BHElib.scenes.stage.state_of_group_init")
local ReplayFileReader = require("BHElib.input.replay_file_reader")
local FileStream = require("util.file_stream")

---------------------------------------------------------------------------------------------------
---task spec format

---{"no_task"}
---{"save_replay"}

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local TaskWait = task.Wait

---------------------------------------------------------------------------------------------------
---class methods

---temporary used for setting the game parameters; must be called before the player select start game
function Menu.setStartGameInitState(group_init_state)
    Menu.default_group_init_state = group_init_state
end

---temporary used for setting the game parameters; must be called before the player select start replay
function Menu.setReplayFilePath(replay_path_for_read, replay_path_for_write)
    Menu.replay_path_for_read = replay_path_for_read
    Menu.replay_path_for_write = replay_path_for_write
end

---------------------------------------------------------------------------------------------------
---init

---create and return a new Menu instance
---@param current_task table specifies a task that the menu should carry out; format {string, table}
---@return Menu a menu object
function Menu.__create(task_spec)
    local self = GameScene.__create()

    self.task_spec = task_spec

    return self
end

---create a menu scene
---@return cc.Scene a new cocos scene
function Menu:createScene()
    -- initialize by first creating all menu pages

    -- for more complex menu, consider further moving the code of declaring object classes to another file

    local main_menu_content = {
        {"Start Game", function()
            TaskNew(self, function()
                -- fade out menu page
                _menu_transition.transitionTo(self.cur_menu, nil, 30)
                TaskWait(30)

                self.is_replay = false
                -- start stage
                SceneTransition.transitionTo(self, SceneTransition.instantTransition)
            end)
        end},
        {"Start Replay", function()
            TaskNew(self, function()
                -- fade out menu page
                _menu_transition.transitionTo(self.cur_menu, nil, 30)
                TaskWait(30)

                self.is_replay = true
                -- start stage
                SceneTransition.transitionTo(self, SceneTransition.instantTransition)
            end)
        end},
    }
    local main_menu = New(SimpleTextMenuPage, "TestMenu", main_menu_content, 1)
    self.cur_menu = _menu_transition.transitionTo(nil, main_menu, 30)

    return GameScene.createScene(self)
end

---------------------------------------------------------------------------------------------------
---instance methods

---construct the next stage
---@return Stage an object of Stage class
function Menu:createNextGameScene()
    -- for all stages
    local is_replay = self.is_replay

    local start_stage_in_replay = 1

    -- create init states for stage and the scene group
    local scene_init_state = nil
    local group_init_state = nil
    if is_replay then

        -- read from file
        local file_stream = FileStream(Menu.replay_path_for_read, "rb")
        local replay_file_reader = ReplayFileReader(file_stream, start_stage_in_replay)
        local replay_summaries = replay_file_reader:readSummariesFromFile()

        group_init_state = replay_summaries.scene_group_summary.group_init_state
        local first_scene_summary = replay_summaries.scene_summary_array[1]
        scene_init_state = first_scene_summary.scene_init_state
    else
        -- use default settings
        group_init_state = Menu.default_group_init_state
        scene_init_state = SceneInitState()
    end
    -- modify status that is not the same as when the replay is recorded
    group_init_state.is_replay = is_replay
    group_init_state.replay_path_for_read = Menu.replay_path_for_read
    group_init_state.replay_path_for_write = Menu.replay_path_for_write
    group_init_state.start_stage_in_replay = start_stage_in_replay

    local SceneGroup = require("BHElib.scenes.stage.scene_group")
    local next_scene_group = SceneGroup(group_init_state)

    -- find the stage class of the first stage
    local Stage = require("BHElib.scenes.stage.stage")
    local stage_id = next_scene_group:getCurrentSceneId()
    local StageClass = Stage.findStageClassById(stage_id)

    local next_stage = StageClass(scene_init_state, next_scene_group)
    return next_stage
end

---@return string name of the scene type
function Menu:getSceneType()
    return "menu"
end

function Menu:cleanup()
end

---@param dt number elapsed time
function Menu:update(dt)
    GameScene.update(self, dt)
end

local hud_painter = require("BHElib.ui.hud_painter")
function Menu:render()
    GameScene.render(self)
    hud_painter.drawHudBackground(
            "image:menu_hud_background",
            1.3
    )
end


return Menu