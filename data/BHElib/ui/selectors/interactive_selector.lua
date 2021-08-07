---------------------------------------------------------------------------------------------------
---interactive_selector.lua
---author: Karl
---date: 2021.4.26
---desc: Defines a selector class, which may receive input and return the selected item in a finite
---     or infinite set
---------------------------------------------------------------------------------------------------

---@class InteractiveSelector
local M = LuaClass("selectors.InteractiveSelector")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local clamp = math.clamp

---------------------------------------------------------------------------------------------------

---account for state changes happened in the current frame, prepare for the display coming up
function M:updateMenuDisplay()
end

---------------------------------------------------------------------------------------------------

local MenuConst = require("BHElib.ui.menu.menu_global")
---@param selection_input InputManager the object for this selector to receive input from
function M.__create(selection_input)
    local self = {}
    self.is_selecting = false  -- default not active
    self.selected_choice = nil
    self.transition_state = MenuConst.OTHER
    self.transition_progress = 0
    self.transition_velocity = 0
    self.timer = 0
    self.selection_input = selection_input
    return self
end

---@param is_selecting boolean true if the selection should start/continue; false if the selection should not continue
function M:resetSelection(is_selecting)
    self.is_selecting = is_selecting
    self.selected_choice = nil
end

function M:isInputEnabled()
    return self.is_selecting
end

function M:getChoice()
    return self.selected_choice
end

---@param state_const number a constant indicating the state of the selector about transitioning, E.g. IN_FORWARD
function M:setTransition(state_const)
    self.transition_state = state_const
    self:updateMenuDisplay()
end

---set the transition state of the selector
---@param t number a number between 0 and 1 for transition state; 0 is completely hidden, while 1 is in the normal state
function M:setTransitionProgress(t)
    self.transition_progress = t
    self:updateMenuDisplay()
end

---@return number transition progress from 0 to 1
function M:getTransitionProgress()
    return self.transition_progress
end

---set the rate of increase of transition progress per frame
function M:setTransitionVelocity(transition_velocity)
    self.transition_velocity = transition_velocity
end

---set the rate of increase of transition progress by frames required to go from completely hidden to shown
function M:transitionInWithTime(time)
    self.transition_velocity = 1 / time
end

---set the rate of increase of transition progress by frames required to go from completely shown to hidden
function M:transitionOutWithTime(time)
    self.transition_velocity = -1 / time
end

---@param dt number time elapsed since last update
function M:update(dt)
    self.timer = self.timer + dt
    local transition_progress = clamp(self.transition_progress + self.transition_velocity, 0, 1)
    self:setTransitionProgress(transition_progress)
end

---test for and process user input on the menu
function M:processInput()
end

return M