---------------------------------------------------------------------------------------------------
---listing_selector.lua
---author: Karl
---date: 2021.4.29
---desc: Defines a selector class, which display a list where multiple items are visible to the
---     user at the same time, and the user can scroll around or move the focus to select one item
---------------------------------------------------------------------------------------------------

local InteractiveSelector = require("BHElib.ui.selectors.interactive_selector")

---@class ListingSelector:InteractiveSelector
local M = LuaClass("selectors.ListingSelector", InteractiveSelector)

local Vec2 = math.vec2

---------------------------------------------------------------------------------------------------

---@param focused_index number index of the selected item when the selector is created
---@param menu_body_pos math.vec2 base position of the menu body
---@param selection_input InputManager the object for this selector to receive input from
function M.__create(selection_input, focused_index, menu_body_pos, pos_increment)
    local self = InteractiveSelector.__create(selection_input)
    self.focused_index = focused_index
    self.menu_body_pos = menu_body_pos
    self.pos_increment = pos_increment
    return self
end

---set the position of the menu body
---@param menu_body_pos math.vec2
function M:setPosition(menu_body_pos)
    self.menu_body_pos = menu_body_pos
    self:updateMenuDisplay()
end

---retrieve the absolute position of the item of given index; the value of decimal input change may vary smoothly
---between index for smooth transition of selection
---@param index number index of the item; if this is not integer, then the result should given some interpolation between adjacent indices
---@return math.vec2 the relative postion of the option in relation to the selector
function M:getListingPosOffset(index)
    return self.pos_increment * (index - 1)
end

---move the focus over to a (new) item
---@param index number new index before range checking; can be out of range
function M:moveFocusTo(index)
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