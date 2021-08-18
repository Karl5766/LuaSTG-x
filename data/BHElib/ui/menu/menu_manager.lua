---------------------------------------------------------------------------------------------------
---menu_manager.lua
---author: Karl
---date: 2021.3.4
---desc: MenuManager manages all menu pages in a menu scene. The class attempts to implement a menu
---     that has the following features:
---
---     1. Each menu page is an object that can be displayed, interacted, and can send messages to
---     the previous menu pages in the menu array.
---     2. The menu page array is an array which records all menu pages that lead up to the current
---     menu page, therefore the game knows which one to go back to when the user exits the current
---     menu page.
---     3. When an array is exited, it continues to exist in the menu page pool but will be removed
---     from the menu page array. Only the most recent one or more menu pages in the menu page
---     array and the exiting menu pages are updated and displayed on the screen.
---     4. When the user returns to or advances to a new menu page, the old menu page object will
---     be pulled out from menu page pool if possible (that is, if it still exists), otherwise a
---     new menu page object will be created using the same callback function.
---     5. The menu manager is able to maintain a global menu page transition speed multiplier
---     factor for this menu, so the transition speed can be easily changed here.
---------------------------------------------------------------------------------------------------

---@class MenuManager
local M = LuaClass("menu.MenuManager")

-- require modules
require("BHElib.ui.menu.menu_page")

local MenuPageArray = require("BHElib.ui.menu.menu_page_array")
local MenuPagePool = require("BHElib.ui.menu.menu_page_pool")

local MenuConst = require("BHElib.ui.menu.menu_global")

---------------------------------------------------------------------------------------------------
---virtual functions

---this function needs to initialize menu pages for menu_page_array and menu_page_pool
M.initMenuPages = nil

---this function needs to terminate the menu; call scene transition if needed
M.onMenuExit = nil

---------------------------------------------------------------------------------------------------
---init

---create and return a new Menu instance
---@param transition_speed number a transition speed coefficient
---@return MenuManager
function M.__create(transition_speed)
    local self = {}

    self.transition_speed = transition_speed or 1 / 15

    -- an array to track the sequence of menus leading to the current one
    self.menu_page_array = MenuPageArray()
    -- a pool to track all existing menus, whether they are entering or exiting (in the latter case they may not be in the array)
    self.menu_page_pool = MenuPagePool()

    return self
end

function M:ctor()
    self:initMenuPages()
end

---------------------------------------------------------------------------------------------------

---add a menu page to the menu page array and menu page pool
function M:registerPage(init_callback, menu_page_id, menu_page, menu_pos)
    self.menu_page_array:setMenu(menu_pos, init_callback, menu_page_id)
    self.menu_page_pool:setMenuInPool(menu_page_id, menu_page, menu_pos)
end

function M:queryChoice(choice_key)
    return self.menu_page_array:queryChoice(choice_key)
end

---@param menu_page_pos number the index from which the cascading starts
function M:cascade(menu_page_pos)
    assert(menu_page_pos, "Error: Attempt to cascade menu page at a nil index!")
    while menu_page_pos ~= nil do
        local menu_page_init_callback, menu_page_id
        menu_page_init_callback, menu_page_id, menu_page_pos = self.menu_page_array:findPrevMenuOf(menu_page_pos, "go_to_menus", "num_finished_menus")
        if menu_page_pos then
            local menu_page = self.menu_page_pool:getMenuFromPool(menu_page_id)
            menu_page:onCascade(self.menu_page_array)
        end
    end
end

---setup a menu page at the given position; can be used to append new menu page to the end of array
---will update the menu page in the page array and page pool;
---it should be guaranteed that the new menu has no choices recorded in the array
---@param menu_page_init_callback function a function that creates a new menu page
---@param menu_id string a unique id that identifies the menu page
---@param menu_pos number position in the array to setup menu page at
---@return MenuPage a menu page that has been setup in the given index of the array
function M:setupMenuPageAtPos(menu_page_init_callback, menu_id, menu_pos)
    -- check if menu already exist, if not, create a new one
    local menu_page_pool = self.menu_page_pool

    local queried_menu_pos = menu_page_pool:getMenuPosFromPool(menu_id)
    local menu_page
    local create_flag = (queried_menu_pos == nil and not menu_page_pool:isMenuExists(menu_id))

    if create_flag then
        menu_page = self:createMenuPage(menu_page_init_callback, menu_id)

        -- add/set the menu page in the array
        self:registerPage(menu_page_init_callback, menu_id, menu_page, menu_pos)
    else
        menu_page = menu_page_pool:getMenuFromPool(menu_id)

        self:registerPage(menu_page_init_callback, menu_id, menu_page, menu_pos)

        self.menu_page_array:clearChoices(menu_pos)
    end

    return menu_page
end

---@param menu_page_init_callback function a function that takes first parameter as menu manager, creates a new menu page
function M:createMenuPage(menu_page_init_callback)
    return menu_page_init_callback(self)
end

---set the top menu page to enter, in forward mode
function M:setTopMenuPageToEnter()
    local menu_page_array = self.menu_page_array
    local menu_id = menu_page_array:getMenuId(menu_page_array:getSize())
    local cur_menu_page = self.menu_page_pool:getMenuFromPool(menu_id)
    cur_menu_page:setPageEnter(true, self.transition_speed)
end

---setup menu pages
---@param menu_page_info_array table an array in which each element contains information for initializing each menu page
---@param coordinates_name string name of the render view to render in E.g. "ui" "game" "3d"
---@param init_layer number (if non-nil) set the initial layer of the menu pages to this value
function M:setupMenuPagesFromInfoArray(menu_page_info_array, coordinates_name, init_layer)
    for i = 1, #menu_page_info_array do
        local class_id, menu_id = unpack(menu_page_info_array[i])
        local menu_page = self:setupMenuPageAtPos(class_id, menu_id, i)
        if init_layer then
            menu_page:setLayer(init_layer)
        end
        menu_page:setRenderView(coordinates_name)
    end
end

---------------------------------------------------------------------------------------------------
---update

---@param dt number elapsed time
function M:update(dt)
    -- update all existing menu pages
    local menu_page_pool = self.menu_page_pool
    local menu_page_array = self.menu_page_array

    local to_be_deleted = {}
    for menu_page_id, info_array in menu_page_pool:getIter() do
        local menu_page_pos = info_array[1]
        local menu_page = info_array[2]
        if not menu_page:continueMenuPage() then
            -- flag for deletion
            -- only delete if the menu page is not in the array, in which case it needs to exist to respond to cascade()
            if menu_page_array:getSize() < menu_page_pos or menu_page_array:getMenuId(menu_page_pos) ~= menu_page_id then
                to_be_deleted[menu_page_id] = menu_page_pos
            end
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
---@param menu_page_pos number the index of the menu page that raised the choices
function M:handleChoices(choices, menu_page_pos)
    local menu_page_array = self.menu_page_array

    local exit_indicator = 0
    local next_pos = -1
    local cascade_flag = false
    for i = 1, #choices do
        local choice = choices[i]
        local label = choice[1]  -- see menu_global.lua
        if label == MenuConst.CHOICE_SPECIFY then
            menu_page_array:setChoice(menu_page_pos, choice[2], choice[3])
        elseif label == MenuConst.CHOICE_CASCADE then
            cascade_flag = true
        elseif label == MenuConst.CHOICE_EXECUTE then
            local callback = choice[2]
            callback(self)
        else
            -- menu page switch
            if label == MenuConst.CHOICE_GO_BACK then
                exit_indicator = 1
                next_pos = menu_page_pos - 1

                if next_pos <= 0 then
                    -- no menu page to go back to, exit the menu
                    label = MenuConst.CHOICE_EXIT
                end
            end
            if label == MenuConst.CHOICE_EXIT or label == MenuConst.CHOICE_GO_TO_MENUS then
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

    if cascade_flag then
        self:cascade(menu_page_array:getSize())  -- cascade from the current menu page
    end

    if exit_indicator == 1 then
        self:goBackToMenuPage(next_pos)
    elseif exit_indicator == 2 then
        self:goToNextMenuPage()
    else
        local top_page = self.menu_page_pool:getMenuFromPool(menu_page_array:getMenuId(menu_page_pos))
        top_page:resetSelection(true)
    end
end

---exit current menu page and go back to one of the previous menu pages
---@param next_pos number the index of the menu page to go back to in the array
function M:goBackToMenuPage(next_pos)
    local menu_page_array = self.menu_page_array
    local menu_page_pool = self.menu_page_pool
    local cur_pos = menu_page_array:getSize()
    local cur_id = menu_page_array:getMenuId(cur_pos)
    local cur_page = menu_page_pool:getMenuFromPool(cur_id)

    local init_callback, next_id = menu_page_array:getMenuInitCallback(next_pos), menu_page_array:getMenuId(next_pos)
    menu_page_array:retrievePrevMenu("go_to_menus", "num_finished_menus")  ---TODO: these parameters should be constants

    assert(cur_pos == menu_page_array:getSize(), "Error: Size mismatch!")
    menu_page_array:popMenu()
    cur_page:setPageExit(false, self.transition_speed)

    local next_page = self:setupMenuPageAtPos(init_callback, next_id, next_pos)

    next_page:setPageEnter(false, self.transition_speed)
end

function M:goToNextMenuPage()
    local menu_page_array = self.menu_page_array
    local menu_page_pool = self.menu_page_pool
    local cur_pos = menu_page_array:getSize()
    local cur_id = menu_page_array:getMenuId(cur_pos)
    local cur_page = menu_page_pool:getMenuFromPool(cur_id)

    cur_page:setPageExit(true, self.transition_speed)

    local menu_page_init_callback, next_id, next_pos = menu_page_array:retrieveNextMenu("go_to_menus", "num_finished_menus")

    if menu_page_init_callback ~= nil then
        local next_page = self:setupMenuPageAtPos(menu_page_init_callback, next_id, next_pos)

        next_page:setPageEnter(true, self.transition_speed)
    else
        -- next menu not found; exit the menu scene
        self:onMenuExit()
    end
end

---------------------------------------------------------------------------------------------------
---exiting

function M:setAllPageExit()
    -- set all menu pages to exit state
    local menu_page_pool = self.menu_page_pool
    for _, info_array in menu_page_pool:getIter() do
        local menu_page = info_array[2]
        menu_page:setPageExit(true, self.transition_speed)
    end
end

function M:cleanup()
    local menu_page_pool = self.menu_page_pool
    for _, info_array in menu_page_pool:getIter() do
        local menu_page = info_array[2]
        menu_page:cleanup()
    end
end

return M