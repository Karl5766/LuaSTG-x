---------------------------------------------------------------------------------------------------
---shake_eff_listing_selector.lua
---author: Karl
---date: 2021.4.29
---desc: Defines a selector class over a finite set of item; upon selection the item selected will
---     display shaking effect
---------------------------------------------------------------------------------------------------

local ListingSelector = require("BHElib.ui.selectors.listing_selector")

---@class ShakeEffListingSelector:ListingSelector
local M = LuaClass("selectors.ShakeEffListingSelector", ListingSelector)

---------------------------------------------------------------------------------------------------

M.Selectable = LuaClass("ShakeEffListingSelector.Selectable")
local Selectable = M.Selectable

---@param init_timer_value number the initial time value of the shaking timer
function Selectable.__create(init_timer_value)
    local self = {}
    self.timer = init_timer_value
    return self
end

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Vec2 = math.vec2
local sin = sin

---------------------------------------------------------------------------------------------------

---@param selection_input InputManager the object for this selector to receive input from
---@param focused_index number initial focused index
---@param init_pos_offset math.vec2 initial position offset
---@param shake_max_time number duration of the shaking effect
---@param shake_amplitude number amplitude of the shaking effect; shaking only occurs in x direction
---@param shake_period number period of harmonic (sine) motion of shaking effect in frames
function M.__create(selection_input, focused_index, init_pos_offset, shake_max_time, shake_amplitude, shake_period)
    local self = ListingSelector.__create(selection_input, focused_index, init_pos_offset)
    self.shake_max_time = shake_max_time
    self.shake_amplitude = shake_amplitude
    self.shake_period = shake_period
    self.selectable_array = {}
    return self
end

function M:setShakeCoeff(shake_max_time, shake_amplitude, shake_period)
    self.shake_max_time = shake_max_time
    self.shake_amplitude = shake_amplitude
    self.shake_period = shake_period
end

function M:resetShakeTimer(timer_value)
    local selectable_array = self.selectable_array
    for i = 1, self.num_selectable do
        selectable_array[i].timer = timer_value
    end
end

---@param dt number time elapsed since last update
function M:updateShakeTimer(dt)
    local selectable_array = self.selectable_array
    for i = 1, self.num_selectable do
        local selectable = selectable_array[i]
        selectable.timer = selectable.timer + dt
    end
end

---return the position of a selectable item after apply the shake effect position offset
---@param index number integer index of the item
function M:getListingPosAfterShakeEff(index)
    local selectable = self.selectable_array[index]

    local t = self.shake_max_time - selectable.timer
    local raw_pos = self:getListingPos(index)
    if t > 0 then
        -- shake effect has ended
        return raw_pos
    else
        -- modify the raw position, accounting for the shaking effect
        local x_offset = self.shake_amplitude * sin(t / self.shake_period)
        return raw_pos + Vec2(x_offset, 0)
    end
end

---move the focus over to a (new) item
---@param index number new index before range checking; can be out of range
function M:moveFocus(index)
    self.focused_index = index
    self:warpFocusedIndex()
    local new_index = self.focused_index

    -- shake the newly selected item
    local selectable_array = self.selectable_array
    selectable_array[new_index].timer = 0
end

---warp the focused index in range 1...#self.selectable_array
function M:warpFocusedIndex()
    -- handles boundary condition, warp the index
    local num_selectable = #self.selectable_array

    self.focused_index = (self.focused_index - 1) % num_selectable + 1
end

return M