---------------------------------------------------------------------------------------------------
---user_pause_menu.lua
---author: Karl
---date: 2021.3.26
---desc: user pause menu is the pause menu that is created when the player interrupts the game
---------------------------------------------------------------------------------------------------

local PauseMenu = require("BHElib.scenes.stage.pause_menu.pause_menu")

---@class ReplayEndMenu:PauseMenu
local ReplayEndMenu = LuaClass("scenes.stage.ReplayEndMenu", PauseMenu)

local _menu_transition = require("BHElib.scenes.menu.menu_page_transition")
local Prefab = require("BHElib.prefab")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local SetChild = task.SetChild
local Insert = table.insert

---------------------------------------------------------------------------------------------------

---@param stage Stage the stage object that created this pause menu
function ReplayEndMenu.__create(stage)
    local self = PauseMenu.__create(stage)

    local transition_time = 30
    -- define behavior for selecting each option
    local pause_menu_content = {
        {"Back to Menu", function()
            PauseMenu.quitToMenu(self, transition_time)
        end},
        {"Restart the Replay", function()
            PauseMenu.restartSceneGroup(self, transition_time)
        end},
    }
    local init_select_index = 1
    local pause_menu_page = New(Prefab.SimpleTextMenuPage, "TestMenu", pause_menu_content, init_select_index)
    pause_menu_page.update = Prefab.SimpleTextMenuPage.frame
    Insert(self.pause_menu_pages, pause_menu_page)

    self.cur_menu = _menu_transition.transitionTo(nil, pause_menu_page, transition_time)

    return self
end

return ReplayEndMenu