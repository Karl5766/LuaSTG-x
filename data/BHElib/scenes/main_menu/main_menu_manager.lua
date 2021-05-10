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

function M.__create(task_spec)
    local self = MenuManager.__create()
    self.task_spec = task_spec
    return self
end

function M:setMenuScene(scene)
    self.scene = scene
end

local TitleMenuPage = require("BHElib.scenes.main_menu.title_menu_page")
function M:createMenuPageFromClass(class_id)
    if class_id == "menu.TitleMenuPage" then
        return TitleMenuPage(1)
    else
        error("ERROR: Unexpected menu page class!")
    end
end

function M:initMenuPages()
    local menu_pages = {
        {"menu.TitleMenuPage", "main_menu"},
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