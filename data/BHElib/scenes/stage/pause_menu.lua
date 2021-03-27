---------------------------------------------------------------------------------------------------
---pause_menu.lua
---author: Karl
---date: 2021.3.16
---references: THlib/ext/pause_menu.lua THlib/ext.lua
---desc: implements pause menu for stages; pause menu kind of works like the menu scene
---------------------------------------------------------------------------------------------------

---@class PauseMenu
local PauseMenu = LuaClass()

local _menu_transition = require("BHElib.scenes.menu.menu_page_transition")
local _scene_transition = require("BHElib.scenes.scene_transition")
local _menu = require("BHElib.scenes.menu.menu_scene")  -- end the game and go back to main menu

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local TaskPropagateDo = task.PropagateDo
local SetChild = task.SetChild

---------------------------------------------------------------------------------------------------

---@param stage Stage the stage object that created this pause menu
function PauseMenu.__create(stage)
    local self = {}

    self.stage = stage
    self.continue_menu = true

    local transition_time = 30
    -- define behavior for selecting each option
    local pause_menu_content = {
        {"Resume", function()
            TaskNew(self, function()

                -- fade out menu page
                _menu_transition.transitionTo(self.cur_menu, nil, transition_time)
                task.Wait(transition_time)

                self.continue_menu = false
            end)
        end},
        {"End the Game", function()
            TaskNew(self, function()
                -- fade out menu page
                _menu_transition.transitionTo(self.cur_menu, nil, transition_time)
                task.Wait(transition_time)

                local task_spec = {"no_task"}
                _scene_transition.transitionTo(self.stage, _menu(task_spec))
                _scene_transition.goToNextScene()  -- immediately do the transition
            end)
        end},
    }
    local pause_menu_page = New(SimpleTextMenuPage, "TestMenu", pause_menu_content, 1)
    pause_menu_page.update = SimpleTextMenuPage.frame
    self.pause_menu_pages = {pause_menu_page}
    self.cur_menu = _menu_transition.transitionTo(nil, pause_menu_page, transition_time)

    return self
end

---@param dt number
---@return boolean true if the menu continues; false if the game is to be resumed in this frame
function PauseMenu:update(dt)
    -- update each menu
    for _, menu_page in ipairs(self.pause_menu_pages) do
        menu_page:update()
    end

    -- do tasks added by menu pages
    TaskPropagateDo(self)

    return self.continue_menu
end

return PauseMenu