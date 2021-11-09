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

---@param text string text to display
---@param choices any describes result of selecting the item
function Selectable.__create(text, choices)
    local self = {}
    self.timer = math.huge
    self.text = text
    self.choices = choices
    return self
end

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Vec2 = math.vec2
local sin = sin

---------------------------------------------------------------------------------------------------

---@param selection_input InputManager the object for this selector to receive input from
---@param focused_index number initial focused index
---@param menu_body_pos math.vec2 initial position offset
---@param shake_max_time number duration of the shaking effect
---@param shake_amplitude number amplitude of the shaking effect; shaking only occurs in x direction
---@param shake_period number period of harmonic (sine) motion of shaking effect in frames
---@param pos_increment math.vec2 increment in position between each two menu selectables
---@param blink_speed number speed of selectable blinking
---@param blink_color_a math.vec4 blinking color; of form {r, g, b, a}
---@param blink_color_b math.vec4 blinking color; of form {r, g, b, a}
---@param normal_color math.vec4 color of the text when they are not blinking; of form {r, g, b, a}
---@param selectable_array table an array of selectables in this menu
function M.__create(
        selection_input,
        focused_index,
        menu_body_pos,
        shake_max_time,
        shake_amplitude,
        shake_period,
        pos_increment,
        blink_speed,
        blink_color_a,
        blink_color_b,
        normal_color,
        selectable_array
)
    local self = ListingSelector.__create(selection_input, focused_index, menu_body_pos, pos_increment)
    self.shake_max_time = shake_max_time
    self.shake_amplitude = shake_amplitude
    self.shake_period = shake_period

    self.blink_speed = blink_speed
    self.blink_color_a = blink_color_a
    self.blink_color_b = blink_color_b
    self.normal_color = normal_color

    self.selectable_array = selectable_array
    return self
end

---for modification purposes
function M:getSelectableArray(selectable_array)
    return self.selectable_array
end

function M:setShakeCoeff(shake_max_time, shake_amplitude, shake_period)
    self.shake_max_time = shake_max_time
    self.shake_amplitude = shake_amplitude
    self.shake_period = shake_period
end

function M:resetShakeTimer(timer_value)
    local selectable_array = self.selectable_array
    for i = 1, #selectable_array do
        selectable_array[i].timer = timer_value
    end
end

---@param dt number time elapsed since last update
function M:updateShakeTimer(dt)
    local selectable_array = self.selectable_array
    for i = 1, #selectable_array do
        local selectable = selectable_array[i]
        selectable.timer = selectable.timer + dt
    end
end

function M:select(i)
    self.is_selecting = false
    self.selected_choice = self.selectable_array[i].choices
end

---@param index number index of the selectable in the selectable array
function M:renderSelectable(index)
    local body_text_obj = self.body_text_obj
    local item_pos = self.menu_body_pos + self:getListingPosOffsetAfterShakeEff(index)
    local color_vec
    -- the selected selectable will blink
    if index == self.focused_index then
        local lerp_coeff = 0.5 + 0.5 * sin(self.timer * self.blink_speed)
        color_vec = self.blink_color_a * lerp_coeff + self.blink_color_b * (1 - lerp_coeff)
    else
        color_vec = self.normal_color
    end
    body_text_obj:setFontColor(Color(color_vec.w, color_vec.x, color_vec.y, color_vec.z))

    body_text_obj:setText(self.selectable_array[index].text)
    body_text_obj:render(item_pos.x, item_pos.y)
end

---return the position of a selectable item after apply the shake effect position offset
---@param index number integer index of the item
function M:getListingPosOffsetAfterShakeEff(index)
    local selectable = self.selectable_array[index]

    local t = self.shake_max_time - selectable.timer
    local raw_pos = self:getListingPosOffset(index)
    if t < 0 then
        -- shake effect has ended
        return raw_pos
    else
        -- modify the raw position, accounting for the shaking effect
        local x_offset = self.shake_amplitude * sin(t / self.shake_period * 180)
        return raw_pos + Vec2(x_offset, 0)
    end
end

return M