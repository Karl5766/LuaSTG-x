---------------------------------------------------------------------------------------------------
---menu_scene.lua
---author: Karl
---date: 2021.3.4
---desc:
---------------------------------------------------------------------------------------------------

---@class MenuManager
local M = LuaClass("menu.MenuManager")

-- require modules
require("BHElib.scenes.menu.menu_page")

local MenuPageArray = require("BHElib.scenes.menu.menu_page_array")
local MenuPagePool = require("BHElib.scenes.menu.menu_page_pool")

local MenuConst = require("BHElib.scenes.menu.menu_const")

---------------------------------------------------------------------------------------------------

---this function needs to initialize menu pages for menu_page_array and menu_page_pool
function M:initMenuPages()
end

---this function needs to terminate the menu; call scene transition if needed
function M:onMenuExit()
end

function M:createMenuPageFromClass(class_id)
end

---------------------------------------------------------------------------------------------------
---init

---create and return a new Menu instance
---@param current_task table specifies a task that the menu should carry out; format {string, table}
---@return Menu a menu object
function M.__create(transition_speed)
    local self = {}

    self.transition_speed = transition_speed or 1 / 30

    -- an array to track the sequence of menus leading to the current one
    self.menu_page_array = MenuPageArray()
    -- a pool to track all existing menus, whether they are entering or exiting (in the latter case they may not be in the array)
    self.menu_page_pool = MenuPagePool()

    return self
end

function M:ctor()
    self:initMenuPages()
end

---add a menu page to the menu page array and menu page pool
function M:registerPage(class_id, menu_page_id, menu_page)
    local menu_page_pos = self.menu_page_array:appendMenu(class_id, menu_page_id)
    self.menu_page_pool:setMenuInPool(menu_page_id, menu_page, menu_page_pos)
    return menu_page_pos
end

function M:cleanup()
    local menu_page_pool = self.menu_page_pool
    for _, info_array in menu_page_pool:getIter() do
        local menu_page = info_array[2]
        menu_page:cleanup()
    end
end

---@param dt number elapsed time
function M:update(dt)
    -- update all existing menu pages
    local menu_page_pool = self.menu_page_pool

    local to_be_deleted = {}
    for menu_page_id, info_array in menu_page_pool:getIter() do
        local menu_page_pos = info_array[1]
        local menu_page = info_array[2]
        if not menu_page:continueMenuPage() then
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
    -- update after creating new menu pages to ensure update() is called at least once in the first time of render
    for menu_page_id, info_array in menu_page_pool:getIter() do
        local menu_page = info_array[2]
        menu_page:update(1)
    end
    for menu_page_id, menu_page_pos in pairs(to_be_deleted) do
        local menu_page = menu_page_pool:getMenuFromPool(menu_page_id)
        menu_page:cleanup()
        menu_page_pool:delMenuInPool(menu_page_id)
    end
end

---handle choices raised by a menu page in the menu array at the given index
function M:handleChoices(choices, menu_page_pos)
    local menu_page_array = self.menu_page_array

    local exit_indicator = 0
    local next_pos = -1
    for i = 1, #choices do
        local choice = choices[i]
        local label = choice[1]  -- see menu_const.lua
        if label == MenuConst.CHOICE_SPECIFY then
            menu_page_array:setChoice(menu_page_pos, choice[2], choice[3])
        else
            -- menu page switch
            if label == MenuConst.CHOICE_GO_BACK then
                exit_indicator = 1
                next_pos = menu_page_pos - 1
            elseif label == MenuConst.CHOICE_EXIT or label == MenuConst.CHOICE_GO_TO_MENUS then
                local menus = {}  -- for CHOICE_EXIT
                if label == MenuConst.CHOICE_GO_TO_MENUS then
                    menus = choice[2]
                end
                menu_page_array:setChoice(menu_page_pos, "go_to_menus", menus)
                menu_page_array:setChoice(menu_page_pos, "num_finished_menus", 0)
                exit_indicator = 2
            end
        end
    end
    if exit_indicator == 1 then
        self:goBackToMenuPage(next_pos)
    elseif exit_indicator == 2 then
        self:goToNextMenuPage()
    end
end

---@param next_pos number the index of the menu page to go back to in the array
function M:goBackToMenuPage(next_pos)
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

function M:goToNextMenuPage()
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
        self:onMenuExit()
    end
end

function M:setAllPageExit()
    -- set all menu pages to exit state
    local menu_page_pool = self.menu_page_pool
    for _, info_array in menu_page_pool:getIter() do
        local menu_page = info_array[2]
        menu_page:setPageExit(true, self.transition_speed)
    end
end

function M:queryChoice(choice_key)
    return self.menu_page_array:queryChoice(choice_key)
end

---setup a menu page at the given position; can be used to append new menu
---will update the menu page in the page array and page pool
---@return MenuPage a menu page that has been setup in the given index of the array
function M:setupMenuPageAtPos(class_id, menu_id, menu_pos)
    -- check if menu already exist, if not, create a new one
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

return M