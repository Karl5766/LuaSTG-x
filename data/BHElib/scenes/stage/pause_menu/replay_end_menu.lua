---------------------------------------------------------------------------------------------------
---replay_end_menu.lua
---author: Karl
---date: 2021.3.26
---desc: replay end menu is a pause menu displayed in the end of a replay
---------------------------------------------------------------------------------------------------

local PauseMenuManager = require("BHElib.scenes.stage.pause_menu.pause_menu")

---@class ReplayEndMenuManager:PauseMenuManager
local M = LuaClass("menu.ReplayEndMenuManager", PauseMenuManager)

local _init_callbacks = require("BHElib.scenes.stage.pause_menu.pause_menu_page_init_callbacks")

---------------------------------------------------------------------------------------------------
---menu manager

function M:initMenuPages()
    local menu_pages = {
        {_init_callbacks.ReplayEndMenuTitle, "pause_page"},
    }
    self:setupMenuPagesFromInfoArray(menu_pages, "game", LAYER_TOP)

    -- setup choices if any (none currently)

    self:setTopMenuPageToEnter()
end

return M