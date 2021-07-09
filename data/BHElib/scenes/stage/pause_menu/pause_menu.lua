---------------------------------------------------------------------------------------------------
---pause_menu.lua
---author: Karl
---date: 2021.3.16
---references: THlib/ext/pause_menu.lua THlib/ext.lua
---desc: implements pause menu for stages
---------------------------------------------------------------------------------------------------

local MenuManager = require("BHElib.scenes.menu.menu_manager")

---@class PauseMenuManager:MenuManager
local M = LuaClass("menu.PauseMenuManager", MenuManager)

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local TaskDo = task.Do
local TaskWait = task.Wait

---------------------------------------------------------------------------------------------------

---@param stage Stage the stage that created this pause menu
function M.__create(stage)
    local self = MenuManager.__create(1 / 15)
    self.continue_menu = true
    self.stage = stage
    return self
end

function M:initMenuPages()
end

function M:continueMenu()
    return self.continue_menu
end

function M:update(dt)
    MenuManager.update(self, dt)
    TaskDo(self)
end

function M:onMenuExit()
    -- set all menu pages to exit state
    self:setAllPageExit()

    local to_do = self:queryChoice("to_do")
    -- use task to implement waiting; requires calling task.Do in update function
    TaskNew(self, function()
        -- fade out menu page
        TaskWait(math.ceil(1 / self.transition_speed))

        -- start stage or exit game, depending on the state set by createNextGameScene
        local callbacks = require("BHElib.scenes.stage.stage_transition_callbacks")
        if to_do == "resume" then
            self.continue_menu = false
        elseif to_do == "quit_to_menu" then
            self.stage:transitionWithCallback(callbacks.createMenuAndSaveReplay)
        elseif to_do == "restart_scene_group" then
            self.stage:transitionWithCallback(callbacks.restartSceneGroup)
        else
            error("onMenuExit() called without to_do set by any menu page in the page array!")
        end
    end)
end

return M