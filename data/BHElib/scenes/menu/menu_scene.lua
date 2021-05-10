---------------------------------------------------------------------------------------------------
---menu_scene.lua
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
local FileStream = require("util.file_stream")

local MenuConst = require("BHElib.scenes.menu.menu_const")
local Ustorage = require("util.universal_id")

---------------------------------------------------------------------------------------------------
---class methods

---temporary used for setting the game parameters; must be called before the player select start game
function M.setStartGameInitState(group_init_state)
    M.default_group_init_state = group_init_state
end

---temporary used for setting the game parameters; must be called before the player select start replay
function M.setReplayFilePath(replay_path_for_read, replay_path_for_write)
    M.replay_path_for_read = replay_path_for_read
    M.replay_path_for_write = replay_path_for_write
end

---------------------------------------------------------------------------------------------------
---init

---create and return a new menu scene
---@param menu_manager MainMenuManager an object that manages the menu pages
---@return Menu a menu object
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

    self:cleanup()

    local menu_manager = self.menu_manager
    if menu_manager:queryChoice("game_mode") == nil then
        return nil  -- exit the game
    end

    local is_replay = menu_manager:queryChoice("is_replay") ~= nil
    local start_stage_in_replay = 1

    -- create init states for stage and the scene group
    local scene_init_state = nil
    local group_init_state = nil
    if is_replay then
        ---replay mode
        -- read from file
        local file_stream = FileStream(M.replay_path_for_read, "rb")
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
    end
    -- modify status that is not the same as when the replay is recorded
    group_init_state.is_replay = is_replay
    group_init_state.replay_path_for_read = M.replay_path_for_read
    group_init_state.replay_path_for_write = M.replay_path_for_write
    group_init_state.start_stage_in_replay = start_stage_in_replay

    local SceneGroup = require("BHElib.scenes.stage.scene_group")
    local next_scene_group = SceneGroup(group_init_state)

    -- find the stage class of the first stage
    local stage_id = next_scene_group:getCurrentSceneId()
    local StageClass = Ustorage:getById(stage_id)

    local next_stage = StageClass(scene_init_state, next_scene_group)
    return next_stage
end

function M:cleanup()
    self.menu_manager:cleanup()  -- order doesn't matter

    GameScene.cleanup(self)
end

---@param dt number elapsed time
function M:update(dt)
    GameScene.update(self, dt)

    self.menu_manager:update(dt)
end

---handle choices raised by a menu page in the menu array at the given index
function M:handleChoices(choices, menu_page_pos)
    local menu_page_array = self.menu_page_array

    for i = 1, #choices do
        local choice = choices[i]
        local label = choice[1]  -- see menu_const.lua
        if label == MenuConst.CHOICE_SPECIFY then
            menu_page_array:setChoice(menu_page_pos, choice[2], choice[3])
        else
            -- menu page switch
            if label == MenuConst.CHOICE_GO_BACK then
                self:goBackToMenuPage(menu_page_pos - 1)
            elseif label == MenuConst.CHOICE_EXIT or label == MenuConst.CHOICE_GO_TO_MENUS then
                local menus = {}  -- for CHOICE_EXIT
                if label == MenuConst.CHOICE_GO_TO_MENUS then
                    menus = choice[2]
                end
                menu_page_array:setChoice(menu_page_pos, "go_to_menus", menus)
                menu_page_array:setChoice(menu_page_pos, "num_finished_menus", 0)
                self:goToNextMenuPage()
            end
        end
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


return M