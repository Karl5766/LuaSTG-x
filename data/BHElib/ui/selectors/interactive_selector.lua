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
---constants

M.IN_FORWARD = 1
M.IN_BACKWARD = 2
M.OUT_FORWARD = 3
M.OUT_BACKWARD = 4

M.OTHER = 5

---------------------------------------------------------------------------------------------------

---@param selection_input InputManager the object for this selector to receive input from
function M.__create(selection_input)
    local self = {}
    self.is_selecting = false  -- default not active
    self.selected_choice = nil
    self.transition_state = M.OTHER
    self.transition_progress = 0
    self.timer = 0
    self.selection_input = selection_input
    return self
end

function M:resetSelection()
    self.is_selecting = true
    self.selected_choice = nil
end

function M:isSelecting()
    return self.is_selecting
end

---@param state_const number a constant indicating the state of the selector about transitioning, E.g. IN_FORWARD
function M:setTransition(state_const)
    self.transition_state = state_const
end

---set the transition state of the selector
---@param t number a number between 0 and 1 for transition state; 0 is completely hidden, while 1 is in the normal state
function M:setTransitionProgress(t)
    self.transition_progress = t
end

---@param dt number time elapsed since last update
function M:update(dt)
    self.timer = self.timer + dt
end

return M