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
---virtual methods

---retrieve the absolute position of the item of given index; the value of decimal input change may vary smoothly
---between index for smooth transition of selection
---@param index number index of the item; if this is not integer, then the result should given some interpolation between adjacent indices
---M:getListingPos(index)

---move the focus over to a (new) item
---@param index number new index before range checking; can be out of range
---M:moveFocus(index)

---if the focused index is outside the range of the list, execute warping so it is inside the list
---M:warpFocusedIndex()

---------------------------------------------------------------------------------------------------

---@param focused_index number index of the selected item when the selector is created
---@param init_pos_offset math.vec2 initial position offset
---@param selection_input InputManager the object for this selector to receive input from
function M.__create(selection_input, focused_index, init_pos_offset)
    local self = InteractiveSelector.__create(selection_input)
    self.focused_index = focused_index
    self.pos_offset = init_pos_offset
    return self
end

---@param pos_offset math.vec2
function M:setPositionOffset(pos_offset)
    self.pos_offset = pos_offset
end

---@return math.vec2
function M:getPositionOffset()
    return self.pos_offset
end

return M