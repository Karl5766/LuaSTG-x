---------------------------------------------------------------------------------------------------
---game_over_menu.lua
---author: Karl
---date: 2021.8.16
---desc: game over menu is the pause menu that is created when the player runs out of lives
---------------------------------------------------------------------------------------------------

local PauseMenuManager = require("BHElib.scenes.stage.pause_menu.pause_menu")

---@class GameOverMenuManager:PauseMenuManager
local M = LuaClass("menu.GameOverMenuManager", PauseMenuManager)

local _init_callbacks = require("BHElib.scenes.stage.pause_menu.pause_menu_page_init_callbacks")

---------------------------------------------------------------------------------------------------
---menu manager

function M:initMenuPages()
    local menu_pages = {
        {_init_callbacks.GameOverMenuTitle, "pause_page"},
    }
    self:setupMenuPagesFromInfoArray(menu_pages, "game", LAYER_TOP)

    -- setup choices if any (none currently)

    self:setTopMenuPageToEnter()
end

return M