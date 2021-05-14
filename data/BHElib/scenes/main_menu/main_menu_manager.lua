---------------------------------------------------------------------------------------------------
---main_menu_manager.lua
---author: Karl
---date: 2021.5.9
---desc: implements a menu manager object that initializes menu pages and handles menu exit for the
---     main menus
---------------------------------------------------------------------------------------------------

local MenuManager = require("BHElib.scenes.menu.menu_manager")

---@class MainMenuManager:MenuManager
local M = LuaClass("menu.MainMenuManager", MenuManager)

local SceneTransition = require("BHElib.scenes.scene_transition")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local TaskDo = task.Do
local TaskWait = task.Wait

---------------------------------------------------------------------------------------------------
---tasks format

---{"no_task"}
---{"save_replay"}

---------------------------------------------------------------------------------------------------

function M.__create(task_spec, temp_replay_path, replay_folder_path)
    local self = MenuManager.__create()
    self.task_spec = task_spec
    self.temp_replay_path = temp_replay_path
    self.replay_folder_path = replay_folder_path
    return self
end

---@return string path of temporary replay writing slot
function M:getTempReplayPath()
    return self.temp_replay_path
end

---@return string path of replay folder
function M:getReplayFolderPath()
    return self.replay_folder_path
end

function M:setMenuScene(scene)
    self.scene = scene
end

local TitleMenuPage = require("BHElib.scenes.main_menu.title_menu_page")
local ReplayMenuPage = require("BHElib.scenes.main_menu.replay_menu_page")
---@param class_id string id of the class of the menu to setup
---@param menu_id string id of the menu to setup
function M:createMenuPageFromClass(class_id, menu_id)
    if class_id == "menu.TitleMenuPage" then
        return TitleMenuPage(1, self.temp_replay_path)
    elseif class_id == "menu.ReplayMenuPage" then
        local is_saving
        if menu_id == "replay_saver" then
            is_saving = true
        elseif menu_id == "replay_loader" then
            is_saving = false
        end
        return ReplayMenuPage(1, is_saving, self.replay_folder_path, 10, 3)
    else
        error("ERROR: Unexpected menu page class "..class_id.." with menu id "..menu_id.."!")
    end
end

function M:initMenuPages()
    local task_name = self.task_spec[1]

    local menu_pages
    if task_name == "no_task" then
        menu_pages = {
            {"menu.TitleMenuPage", "main_menu"},
        }
    elseif task_name == "save_replay" then
        menu_pages = {
            {"menu.TitleMenuPage", "main_menu"},
            {"menu.ReplayMenuPage", "replay_saver"},
        }
    end

    for i = 1, #menu_pages do
        local class_id, menu_id = unpack(menu_pages[i])
        self:setupMenuPageAtPos(class_id, menu_id, i)
    end
    local menu_page_array = self.menu_page_array

    -- simulate choices
    if task_name == "save_replay" then
        menu_page_array:setChoice(1, "go_to_menus", {menu_pages[2]})
        menu_page_array:setChoice(1, "num_finished_menus", 1)
    end

    for i = 1, #menu_pages do
        local class_id, menu_id = unpack(menu_pages[i])
        local cur_menu_page = self.menu_page_pool:getMenuFromPool(menu_id)
        if i == #menu_pages then
            cur_menu_page:setPageEnter(true, self.transition_speed)
        else
            cur_menu_page:setPageExit(true, self.transition_speed)
        end
    end
end

function M:update(dt)
    MenuManager.update(self, dt)
    TaskDo(self)
end

function M:onMenuExit()
    self:setAllPageExit()

    -- use task to implement waiting; requires calling task.Do in update function
    TaskNew(self, function()
        -- fade out menu page
        TaskWait(math.ceil(1 / self.transition_speed))

        -- start stage or exit game, depending on the state set by createNextGameScene
        SceneTransition.transitionFrom(self.scene, SceneTransition.instantTransition)
    end)
end

return M