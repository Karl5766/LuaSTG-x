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
function M.__create(focused_index)
    local self = InteractiveSelector.__create()
    self.focused_index = focused_index
    self.pos_offset = Vec2(0, 0)
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

---retrieve the absolute position of the item of given index; the value of decimal input change may vary smoothly
---between index for smooth transition of selection
---@param index number index of the item; if this is not integer, then the result should given some interpolation between adjacent indices
function M:getListingPos(index)
end

---move the focus over to a (new) item
---@param diff_index number raw change in index before range checking; positive means forward change; negative means backward change; can be 0
function M:moveFocus(diff_index)
end

function M:warpFocusedIndex()
end