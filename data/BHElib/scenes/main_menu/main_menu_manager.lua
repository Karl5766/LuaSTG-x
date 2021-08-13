---------------------------------------------------------------------------------------------------
---main_menu_manager.lua
---author: Karl
---date: 2021.5.9
---desc: implements a menu manager object that initializes menu pages and handles menu exit for the
---     main menus
---------------------------------------------------------------------------------------------------

local MenuManager = require("BHElib.ui.menu.menu_manager")

---@class MainMenuManager:MenuManager
local M = LuaClass("menu.MainMenuManager", MenuManager)

local SceneTransition = require("BHElib.scenes.game_scene_transition")
local _init_callbacks = require("BHElib.scenes.main_menu.main_menu_page_init_callbacks")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local TaskDo = task.Do
local TaskWait = task.Wait

---------------------------------------------------------------------------------------------------

---create a main menu manager
---specifying the replay saving/loading paths should probably be done in the menu code,
---so I put these parameters below
---
---possible tasks formats:
---1.{"no_task"}
---2.{"save_replay"}
---
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

function M:initMenuPages()
    local task_name = self.task_spec[1]

    local menu_pages
    if task_name == "no_task" then
        menu_pages = {
            {_init_callbacks.Title, "main_menu"},
        }
    elseif task_name == "save_replay" then
        menu_pages = {
            {_init_callbacks.Title, "main_menu"},
            {_init_callbacks.ReplaySaver, "replay_saver"},
        }
    else
        error("Error: Invalid menu task name: "..tostring(task_name))
    end

    for i = 1, #menu_pages do
        local init_callback, menu_id = unpack(menu_pages[i])
        self:setupMenuPageAtPos(init_callback, menu_id, i)
    end
    local menu_page_array = self.menu_page_array

    -- simulate choices
    if task_name == "save_replay" then
        menu_page_array:setChoice(1, "go_to_menus", {menu_pages[2]})
        menu_page_array:setChoice(1, "num_finished_menus", 1)
    end

    for i = 1, #menu_pages do
        local init_callback, menu_id = unpack(menu_pages[i])
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
        SceneTransition.transitionAtStartOfNextFrame(self.scene)
    end)
end

return M