---------------------------------------------------------------------------------------------------
---pause_menu.lua
---author: Karl
---date: 2021.3.16
---references: THlib/ext/pause_menu.lua THlib/ext.lua
---desc: implements pause menu for stages
---------------------------------------------------------------------------------------------------

---@class PauseMenu
local PauseMenu = LuaClass("scenes.stage.PauseMenu")

local _menu_transition = require("BHElib.scenes.menu.menu_page_transition")
local SceneTransition = require("BHElib.scenes.scene_transition")
local _menu = require("BHElib.scenes.menu.menu_scene")  -- end the game and go back to main menu

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local TaskDo = task.Do
local TaskWait = task.Wait

---------------------------------------------------------------------------------------------------

---@param stage Stage the stage object that created this pause menu
function PauseMenu.__create(stage)
    local self = {}

    self.stage = stage
    self.continue_menu = true  -- the game will check if this is false each frame; if so, the game resumes

    self.pause_menu_pages = {}  -- an array of game objects that represents pause menu pages
    self.cur_menu = nil  -- current menu page

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
    TaskDo(self)

    return self.continue_menu
end

---------------------------------------------------------------------------------------------------
---common functions that may be used by derived classes

---return back to the game
---@param transition_time number time of the transition in frames
function PauseMenu:resume(transition_time)
    TaskNew(self, function()

        -- fade out menu page
        _menu_transition.transitionTo(self.cur_menu, nil, transition_time)
        TaskWait(transition_time)

        self.continue_menu = false
    end)
end

---end the stage and go back to the main menu
---@param transition_time number time of the transition in frames
function PauseMenu:quitToMenu(transition_time)
    TaskNew(self, function()
        -- fade out menu page
        _menu_transition.transitionTo(self.cur_menu, nil, transition_time)
        TaskWait(transition_time)

        self.stage:completeSceneGroup()
        SceneTransition.update()  -- immediately do the transition
    end)
end

---restart the scene group
---@param transition_time number time of the transition in frames
function PauseMenu:restartSceneGroup(transition_time)
    TaskNew(self, function()
        -- fade out menu page
        _menu_transition.transitionTo(self.cur_menu, nil, transition_time)
        TaskWait(transition_time)

        self.stage:restartSceneGroup()
        SceneTransition.update()  -- immediately do the transition
    end)
end

return PauseMenu