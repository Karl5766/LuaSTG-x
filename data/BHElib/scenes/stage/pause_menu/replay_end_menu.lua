---------------------------------------------------------------------------------------------------
---replay_end_menu.lua
---author: Karl
---date: 2021.3.26
---desc: replay end menu is a pause menu displayed in the end of a replay
---------------------------------------------------------------------------------------------------

local PauseMenuManager = require("BHElib.scenes.stage.pause_menu.pause_menu")

---@class ReplayEndMenuManager:PauseMenuManager
local ReplayEndMenuManager = LuaClass("menu.ReplayEndMenuManager", PauseMenuManager)

local _init_callbacks = require("BHElib.scenes.stage.pause_menu.pause_menu_page_init_callbacks")

---------------------------------------------------------------------------------------------------
---menu manager

function ReplayEndMenuManager.__create(stage)
    local self = PauseMenuManager.__create(stage)
    return self
end

function ReplayEndMenuManager:initMenuPages()
    local menu_pages = {
        {_init_callbacks.ReplayEndMenuTitle, "pause_page"},
    }
    for i = 1, #menu_pages do
        local class_id, menu_id = unpack(menu_pages[i])
        local menu_page = self:setupMenuPageAtPos(class_id, menu_id, i)
        menu_page:setRenderView("game")
    end

    -- setup choices
    -- currently no choices are needed

    local menu_page_array = self.menu_page_array
    local menu_id = menu_page_array:getMenuId(menu_page_array:getSize())
    local cur_menu_page = self.menu_page_pool:getMenuFromPool(menu_id)
    cur_menu_page:setPageEnter(true, self.transition_speed)
end

return ReplayEndMenuManager