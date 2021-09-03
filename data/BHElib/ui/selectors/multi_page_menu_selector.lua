---------------------------------------------------------------------------------------------------
---multi_page_menu_selector.lua
---author: Karl
---date: 2021.5.11
---desc: Defines a selector for text menu that has multiple pages
---------------------------------------------------------------------------------------------------

local ShakeEffListingSelector = require("BHElib.ui.selectors.shake_eff_listing_selector")
local SimpleMenuSelector = require("BHElib.ui.selectors.simple_menu_selector")

---@class MultiPageMenuSelector:SimpleMenuSelector
local M = LuaClass("selectors.MultiPageMenuSelector", SimpleMenuSelector)

---------------------------------------------------------------------------------------------------

---@param selection_input InputManager the object for this selector to receive input from
---@param focused_index number initial focused index
---@param menu_body_pos math.vec2 initial position of the menu body
---@param shake_max_time number duration of the shaking effect
---@param shake_amplitude number amplitude of the shaking effect; shaking only occurs in x direction
---@param shake_period number period of harmonic (sine) motion of shaking effect in frames
---@param blink_speed number speed of selectable blinking
---@param blink_color_a math.vec4 blinking color; of form {r, g, b, a}
---@param blink_color_b math.vec4 blinking color; of form {r, g, b, a}
---@param normal_color math.vec4 color of the text when they are not blinking; of form {r, g, b, a}
---@param title_pos_offset math.vec2 title position relative to the body of the menu
---@param title_text_obj ui.TextClass text object describing how the title text should look; require everything
---@param body_text_obj ui.TextClass text object describing how the body text should look; require everything except text and color
---@param pos_increment math.vec2 increment in position between each two menu selectables
---@param all_selectable table an array of all selectables in this menu
---@param transition_fly_directions table an array of numbers specifying the transition flying direction in degrees
---@param transition_fly_distances table an array of numbers specifying the transition flying distance
function M.__create(
        selection_input,
        focused_index,
        menu_body_pos,
        shake_max_time,
        shake_amplitude,
        shake_period,
        blink_speed,
        blink_color_a,
        blink_color_b,
        normal_color,
        title_pos_offset,
        title_text_obj,
        body_text_obj,
        pos_increment,
        all_selectable,
        num_selectable_in_page,
        num_pages,
        transition_fly_directions,
        transition_fly_distances)
    local self = SimpleMenuSelector.__create(
            selection_input,
            focused_index,
            menu_body_pos,
            shake_max_time,
            shake_amplitude,
            shake_period,
            blink_speed,
            blink_color_a,
            blink_color_b,
            normal_color,
            title_pos_offset,
            title_text_obj,
            body_text_obj,
            pos_increment,
            {},
            transition_fly_directions,
            transition_fly_distances
    )

    self.all_selectable = all_selectable
    self.num_selectable_in_page = num_selectable_in_page
    self.num_pages = num_pages
    self.page_index = 1


    self.menu_body_pos = menu_body_pos
    self.title_pos_offset = title_pos_offset
    self.title_text_obj = title_text_obj
    self.body_text_obj = body_text_obj

    return self
end

---analogy to moveFocusTo(); flip to a new page, and load options into selectable_array
---page index starts at 1;
---focus index may be out of range when this function is called, the function needs to warp it in place and play selection effect
---@param index number page number to flip to; may be out of range
function M:flipPageTo(index)
    -- cleanup the current page
    self:resetShakeTimer(math.huge)

    -- calculate the next page
    index = (index - 1) % self.num_pages + 1
    self.page_index = index

    self:loadSelectableArray(index)

    self:moveFocusTo(self.focused_index)
end

---@param index number page number
function M:loadSelectableArray(index)
    assert(index >= 1 and index <= self.num_pages, "Error: Page index out of range!")
    local num_item = self.num_selectable_in_page
    local selectable_array = self.selectable_array
    local base_index = num_item * (index - 1)
    for i = 1, num_item do
        local selectable = self.all_selectable[base_index + i]
        selectable_array[i] = selectable
    end
end

function M:renderSelectable(index)
    if self.selectable_array[index] == nil then
        self:renderDummySelectable(index)
    else
        ShakeEffListingSelector.renderSelectable(self, index)
    end
end

function M:renderDummySelectable(index)
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

---test for and process user input on the menu
function M:processInput()
    ---@type InputManager
    local input = self.selection_input

    local page_index_diff = 0
    local focused_index_diff = 0
    if input:isAnyKeyJustChanged("left", false, true) then
        page_index_diff = -1
    elseif input:isAnyKeyJustChanged("right", false, true) then
        page_index_diff = 1
    end
    if page_index_diff == 0 then  -- only check for up down movement if no page flip has happened
        -- moving through options
        if input:isAnyKeyJustChanged("up", false, true) then
            focused_index_diff = -1
        elseif input:isAnyKeyJustChanged("down", false, true) then
            focused_index_diff = 1
        end
        local focused_index = self.focused_index + focused_index_diff
        if focused_index <= 0 then
            page_index_diff = -1
        elseif focused_index > self.num_selectable_in_page then
            page_index_diff = 1
        end
    end

    if page_index_diff ~= 0 then
        self.focused_index = self.focused_index + focused_index_diff
        self:flipPageTo(self.page_index + page_index_diff)
    elseif focused_index_diff ~= 0 then
        self:moveFocusTo(self.focused_index + focused_index_diff)
    end

    -- selecting an option
    if input:isAnyKeyJustChanged("select", false, true) then
        self:select(self.focused_index)
    end
end

function M:select(i)
    local item = self.selectable_array[i]
    if item.choices ~= nil then
        ShakeEffListingSelector.select(self, i)
    end
end

function M:globalMoveFocus(index)
    local page_index = math.ceil(index / self.num_selectable_in_page)

    self.focused_index = index  -- will be warped to the correct position in this following function
    self:flipPageTo(math.clamp(page_index, 1, self.num_pages))
end

---------------------------------------------------------------------------------------------------
---shorter init parameter list

local MenuConst = require("BHElib.ui.menu.menu_global")
local InteractiveSelector = require("BHElib.ui.selectors.interactive_selector")
local Input = require("BHElib.input.input_and_recording")
local TextClass = require("BHElib.ui.text_class")
local Vec2 = math.vec2

---@param init_global_focused_index number
---@param scale number scaling of the displayed text size and line height
---@param fly_distance number distance of travelling when transition in/out
---@param relative_pos math.vec2 relative position of the menu page
---@param all_selectable table an array of SimpleMenuSelector.Selectable objects
---@param num_selectable_in_page number number of options max in one page
---@param num_pages number number of pages total
---@param menu_page_title string text title of the page
function M.shortInit(init_global_focused_index,
                     scale,
                     fly_distance,
                     relative_pos,
                     all_selectable,
                     menu_page_title,
                     num_selectable_in_page,
                     num_pages,
                     enter_dir,
                     exit_dir)
    -- create simple menu selector
    local text_line_height = MenuConst.line_height * scale
    local text_align = {"center"}
    local title_color = MenuConst.title_color
    local title_text_object = TextClass(
            menu_page_title,
            Color(title_color.w, title_color.x, title_color.y, title_color.z),
            MenuConst.font_name,
            MenuConst.font_size * scale,
            unpack(text_align))
    local body_text_object = TextClass(
            nil,
            nil,
            MenuConst.font_name,
            MenuConst.font_size * scale,
            unpack(text_align))
    local transition_fly_directions = {
        [MenuConst.IN_FORWARD] = enter_dir or -180,
        [MenuConst.IN_BACKWARD] = exit_dir or 0,
        [MenuConst.OUT_FORWARD] = exit_dir or 0,
        [MenuConst.OUT_BACKWARD] = enter_dir or -180,
    }
    local transition_fly_distances = {
        [MenuConst.IN_FORWARD] = fly_distance,
        [MenuConst.IN_BACKWARD] = fly_distance,
        [MenuConst.OUT_FORWARD] = fly_distance,
        [MenuConst.OUT_BACKWARD] = fly_distance,
    }

    local selector = M(
            Input,
            1,
            relative_pos,
            MenuConst.shake_time,
            MenuConst.shake_range,
            MenuConst.shake_period,
            MenuConst.blink_speed,
            MenuConst.focused_color_a,
            MenuConst.focused_color_b,
            MenuConst.unfocused_color,
            Vec2(0, 2 * text_line_height),
            title_text_object,
            body_text_object,
            Vec2(0, -text_line_height),
            all_selectable,
            num_selectable_in_page,
            num_pages,
            transition_fly_directions,
            transition_fly_distances)
    selector:globalMoveFocus(init_global_focused_index)

    return selector
end

return M