---------------------------------------------------------------------------------------------------
---simple_menu_selector.lua
---author: Karl
---date: 2021.4.30
---desc: Defines a selector for simple text menus
---------------------------------------------------------------------------------------------------

local ShakeEffListingSelector = require("BHElib.ui.selectors.shake_eff_listing_selector")

---@class SimpleMenuSelector:ShakeEffListingSelector
local M = LuaClass("selectors.SimpleMenuSelector", ShakeEffListingSelector)

local InteractiveSelector = require("BHElib.ui.selectors.interactive_selector")
local MenuConst = require("BHElib.ui.menu.menu_global")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Vec2 = math.vec2
local Vec4 = math.vec4
local sin = sin
local cos = cos

---------------------------------------------------------------------------------------------------

---@param selection_input InputManager the object for this selector to receive input from
---@param focused_index number initial focused index
---@param reference_pos math.vec2 position of reference
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
---@param selectable_array table an array of selectables in this menu
---@param transition_fly_directions table an array of numbers specifying the transition flying direction in degrees
---@param transition_fly_distances table an array of numbers specifying the transition flying distance
function M.__create(
            selection_input,
            focused_index,
            reference_pos,
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
            selectable_array,
            transition_fly_directions,
            transition_fly_distances)
    local self = ShakeEffListingSelector.__create(
            selection_input,
            focused_index,
            reference_pos,
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

    self.reference_pos = reference_pos
    self.title_pos_offset = title_pos_offset
    self.title_text_obj = title_text_obj
    self.body_text_obj = body_text_obj
    self.transition_fly_directions = transition_fly_directions
    self.transition_fly_distances = transition_fly_distances

    return self
end

---------------------------------------------------------------------------------------------------
---getters and setters

function M:continueMenu()
    local state = self.transition_state
    local del_flag = self:getTransitionProgress() == 0 and (state == MenuConst.OUT_BACKWARD or state == MenuConst.OUT_FORWARD)
    return not del_flag
end

function M:isInputEnabled()
    return self.is_selecting and self.transition_progress == 1
end

---------------------------------------------------------------------------------------------------
---update functions

---calculate position of the menu by transition progress
function M:updateMenuDisplay()
    local reference_pos = self.reference_pos
    local p = self.transition_progress
    local state = self.transition_state
    local distance = (1 - p) ^ 2 * self.transition_fly_distances[state]
    local direction = self.transition_fly_directions[state]
    self.menu_body_pos = reference_pos + Vec2(cos(direction), sin(direction)) * distance
end

---@param dt number time elapsed since last update
function M:update(dt)
    InteractiveSelector.update(self, dt)

    self:updateShakeTimer(dt)
end

---test for and process user input on the menu
function M:processInput()
    local input = self.selection_input

    local focused_index = self.focused_index
    -- moving through options
    if input:isAnyDeviceKeyJustChanged("up", false, true) then
        self:moveFocusTo(focused_index - 1)
    elseif input:isAnyDeviceKeyJustChanged("down", false, true) then
        self:moveFocusTo(focused_index + 1)
    end

    -- selecting an option
    if input:isAnyDeviceKeyJustChanged("select", false, true) then
        self:select(focused_index)
    end
end

function M:exit()
    self.is_selecting = false
    self.selected_choice = {
        {MenuConst.CHOICE_GO_BACK}
    }
end

---------------------------------------------------------------------------------------------------
---render

function M:render()
    -- render title
    local pos = self.menu_body_pos + self.title_pos_offset
    self.title_text_obj:render(pos.x, pos.y)

    -- render body
    for index = 1, #self.selectable_array do
        self:renderSelectable(index)
    end
end

---------------------------------------------------------------------------------------------------
---shorter init parameter list

local Input = require("BHElib.input.input_and_recording")
local TextClass = require("BHElib.ui.text_class")

---@param init_focused_index number initial value of the selected index
---@param scale number scaling of the displayed text size and line height
---@param fly_distance number distance of travelling when transition in/out
---@param relative_pos math.vec2 relative position of the menu page
---@param selectable_array table an array of SimpleMenuSelector.Selectable objects
---@param menu_page_title string text title of the page
function M.shortInit(init_focused_index,
                     scale,
                     fly_distance,
                     relative_pos,
                     selectable_array,
                     menu_page_title,
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
            init_focused_index,
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
            selectable_array,
            transition_fly_directions,
            transition_fly_distances
    )

    return selector
end

return M