---------------------------------------------------------------------------------------------------
---menu_scene.lua
---author: Karl
---date: 2021.3.4
---desc: implements the main menu
---------------------------------------------------------------------------------------------------

local GameScene = require("BHElib.scenes.game_scene")

---@class Menu:GameScene
local Menu = LuaClass("scenes.Menu", GameScene)

-- require modules
require("BHElib.scenes.menu.menu_page")
local SceneTransition = require("BHElib.scenes.scene_transition")
local SceneInitState = require("BHElib.scenes.stage.state_of_scene_init")
local ReplayFileReader = require("BHElib.input.replay_file_reader")
local FileStream = require("util.file_stream")

local MenuPageArray = require("BHElib.scenes.menu.menu_page_array")
local MenuPagePool = require("BHElib.scenes.menu.menu_page_pool")

local MenuConst = require("BHElib.scenes.menu.menu_const")
local Ustorage = require("util.universal_id")

-- menu pages
local MainMenuPage = require("BHElib.scenes.menu.main_menu_page")

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
    self.transition_speed = 1 / 60

    return self
end

---create a menu scene
---@return cc.Scene a new cocos scene
function Menu:createScene()
    -- initialize by first creating all menu pages

    -- an array to track the sequence of menus leading to the current one
    self.menu_page_array = MenuPageArray()
    -- a pool to track all existing menus, whether they are entering or exiting (in the latter case they may not be in the array)
    self.menu_page_pool = MenuPagePool()

    self:initMenuPages()

    return GameScene.createScene(self)
end

function Menu:initMenuPages()
    local menu_pages = {
        {"menu.MainMenuPage", "main_menu"},
    }
    for i = 1, #menu_pages do
        local class_id, menu_id = unpack(menu_pages[i])
        self:setupMenuPageAtPos(class_id, menu_id, i)
    end

    -- setup choices
    -- currently no choices ar needed

    local menu_page_array = self.menu_page_array
    local menu_id = menu_page_array:getMenuId(menu_page_array:getSize())
    local cur_menu_page = self.menu_page_pool:getMenuFromPool(menu_id)
    cur_menu_page:setPageEnter(true, self.transition_speed)
end

---add a menu page to the menu page array and menu page pool
function Menu:registerPage(class_id, menu_page_id, menu_page)
    local menu_page_pos = self.menu_page_array:appendMenu(class_id, menu_page_id)
    self.menu_page_pool:setMenuInPool(menu_page_id, menu_page, menu_page_pos)
    return menu_page_pos
end

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
        ---replay mode
        -- read from file
        local file_stream = FileStream(Menu.replay_path_for_read, "rb")
        local replay_file_reader = ReplayFileReader(file_stream, start_stage_in_replay)
        local replay_summaries = replay_file_reader:readSummariesFromFile()

        group_init_state = table.deepcopy(replay_summaries.scene_group_summary.group_init_state)
        local first_scene_summary = replay_summaries.scene_summary_array[1]
        scene_init_state = first_scene_summary.scene_init_state
    else
        ---game mode
        -- use default settings
        group_init_state = table.deepcopy(Menu.default_group_init_state)
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
    local stage_id = next_scene_group:getCurrentSceneId()
    local StageClass = Ustorage:getById(stage_id)

    local next_stage = StageClass(scene_init_state, next_scene_group)
    return next_stage
end

function Menu:cleanup()
    local menu_page_pool = self.menu_page_pool
    for _, info_array in menu_page_pool:getIter() do
        local menu_page = info_array[2]
        menu_page:cleanup()
    end
end

---@param dt number elapsed time
function Menu:update(dt)
    GameScene.update(self, dt)

    -- update all existing menu pages
    local menu_page_pool = self.menu_page_pool

    local to_be_deleted = {}
    for menu_page_id, info_array in menu_page_pool:getIter() do
        local menu_page_pos = info_array[1]
        local menu_page = info_array[2]

        menu_page:update(1)
        if not menu_page:continueMenu() then
            -- flag for deletion
            to_be_deleted[menu_page_id] = menu_page_pos
        else
            if menu_page:isInputEnabled() then
                menu_page:processInput()
            end

            local choices = menu_page:getChoice()
            if choices ~= nil then
                self:handleChoices(choices, menu_page_pos)
            end
        end
    end
    for menu_page_id, menu_page_pos in pairs(to_be_deleted) do
        local menu_page = menu_page_pool:getMenuFromPool(menu_page_id)
        menu_page:cleanup()
        menu_page_pool:delMenuInPool(menu_page_id)
    end
end

---handle choices raised by a menu page in the menu array at the given index
function Menu:handleChoices(choices, menu_page_pos)
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

---@param next_pos number the index of the menu page to go back to in the array
function Menu:goBackToMenuPage(next_pos)
    local menu_page_array = self.menu_page_array
    local menu_page_pool = self.menu_page_pool
    local cur_pos = menu_page_array:getSize()
    local cur_id = menu_page_array:getMenuId(cur_pos)
    local cur_page = menu_page_pool:getMenuFromPool(cur_id)

    local next_class_id, next_id = menu_page_array:getMenuClassId(next_pos), menu_page_array:getMenuId(next_pos)

    cur_page:setPageExit(false, self.transition_speed)

    menu_page_array:retrievePrevMenu("go_to_menus", "num_finished_menus")

    local next_page = self:setupMenuPageAtPos(next_class_id, next_id, next_pos)

    next_page:setPageEnter(false, self.transition_speed)
end

function Menu:goToNextMenuPage()
    local menu_page_array = self.menu_page_array
    local menu_page_pool = self.menu_page_pool
    local cur_pos = menu_page_array:getSize()
    local cur_id = menu_page_array:getMenuId(cur_pos)
    local cur_page = menu_page_pool:getMenuFromPool(cur_id)

    cur_page:setPageExit(true, self.transition_speed)

    local next_class_id, next_id, next_pos = menu_page_array:retrieveNextMenu("go_to_menus", "num_finished_menus")

    if next_class_id ~= nil then
        local next_page = self:setupMenuPageAtPos(next_class_id, next_id, next_pos)

        next_page:setPageEnter(true, self.transition_speed)
    else
        -- next menu not found; exit the menu scene
        self:exitMenuScene()
    end
end

function Menu:exitMenuScene()
    -- set all menu pages to exit state
    local menu_page_pool = self.menu_page_pool
    for _, info_array in menu_page_pool:getIter() do
        local menu_page = info_array[2]
        menu_page:setPageExit(true, self.transition_speed)
    end
    local transition_time = 30
    TaskNew(self, function()
        -- fade out menu page
        TaskWait(30)

        -- start stage or exit game, depending on the state set by createNextGameScene
        SceneTransition.transitionFrom(self, SceneTransition.instantTransition)
    end)
end

function Menu:createMenuPageFromClass(class_id)
    if class_id == "menu.MainMenuPage" then
        return MainMenuPage(1)
    else
        error("ERROR: Unexpected menu page class!")
    end
end

---setup a menu page at the given position; can be used to append new menu
---will update the menu page in the page array and page pool
---@return MenuPage a menu page that has been setup in the given index of the array
function Menu:setupMenuPageAtPos(class_id, menu_id, menu_pos)
    -- check if menu already exist, if not, create a new one
    local menu_page_array = self.menu_page_array
    local menu_page_pool = self.menu_page_pool

    local queried_menu_pos = menu_page_pool:getMenuPosFromPool(menu_id)
    local menu_page
    if queried_menu_pos == nil then
        menu_page = self:createMenuPageFromClass(class_id)
    else
        menu_page = menu_page_pool:getMenuFromPool(menu_id)
    end

    -- add/set the menu page in the array
    self:registerPage(class_id, menu_id, menu_page)

    return menu_page
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