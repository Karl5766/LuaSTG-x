---------------------------------------------------------------------------------------------------
---user_pause_menu.lua
---author: Karl
---date: 2021.3.26
---desc: user pause menu is the pause menu that is created when the player interrupts the game
---------------------------------------------------------------------------------------------------

local PauseMenuManager = require("BHElib.scenes.stage.pause_menu.pause_menu")

---@class UserPauseMenuManager:PauseMenuManager
local M = LuaClass("menu.UserPauseMenuManager", PauseMenuManager)

local _init_callbacks = require("BHElib.scenes.stage.pause_menu.pause_menu_page_init_callbacks")

---------------------------------------------------------------------------------------------------
---menu manager

function M:initMenuPages()
    local menu_pages = {
        {_init_callbacks.UserPauseMenuTitle, "pause_page"},
    }
    self:setupMenuPagesFromInfoArray(menu_pages, "game", LAYER_TOP)

    -- setup choices if any (none currently)

    self:setTopMenuPageToEnter()
end

return M