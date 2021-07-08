---------------------------------------------------------------------------------------------------
---user_pause_menu.lua
---author: Karl
---date: 2021.3.26
---desc: user pause menu is the pause menu that is created when the player interrupts the game
---------------------------------------------------------------------------------------------------

local PauseMenuManager = require("BHElib.scenes.stage.pause_menu.pause_menu")

---@class UserPauseMenuManager:PauseMenuManager
local UserPauseMenuManager = LuaClass("menu.UserPauseMenuManager", PauseMenuManager)

local _init_callbacks = require("BHElib.scenes.stage.pause_menu.pause_menu_page_init_callbacks")

---------------------------------------------------------------------------------------------------
---menu manager

---@param stage Stage the stage object that created this pause menu
function UserPauseMenuManager.__create(stage)
    local self = PauseMenuManager.__create(stage)
    return self
end

function UserPauseMenuManager:initMenuPages()
    local menu_pages = {
        {_init_callbacks.UserPauseMenuTitle, "pause_page"},
    }
    for i = 1, #menu_pages do
        local class_id, menu_id = unpack(menu_pages[i])
        local menu_page = self:setupMenuPageAtPos(class_id, menu_id, i)
        --menu_page:setLayer(LAYER_HUD - 1)
        menu_page:setRenderView("game")
    end

    -- setup choices
    -- currently no choices are needed

    local menu_page_array = self.menu_page_array
    local menu_id = menu_page_array:getMenuId(menu_page_array:getSize())
    local cur_menu_page = self.menu_page_pool:getMenuFromPool(menu_id)
    cur_menu_page:setPageEnter(true, self.transition_speed)
end

return UserPauseMenuManager