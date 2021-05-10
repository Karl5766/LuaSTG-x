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
local MenuConst = require("BHElib.scenes.menu.menu_const")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Vec2 = math.vec2
local Vec4 = math.vec4
local sin = sin
local cos = cos

---------------------------------------------------------------------------------------------------

---@class SimpleMenuSelector.Selectable
M.Selectable = LuaClass("SimpleMenuSelector.Selectable", ShakeEffListingSelector.Selectable)
local Selectable = M.Selectable

---@param init_timer_value number the initial time value of the shaking timer
---@param text string text to display
---@param choices any describes result of selecting the item
function Selectable.__create(text, choices)
    local self = ShakeEffListingSelector.Selectable(math.huge)
    self.text = text
    self.choices = choices
    return self
end

---------------------------------------------------------------------------------------------------

---@param selection_input InputManager the object for this selector to receive input from
---@param focused_index number initial focused index
---@param init_pos_offset math.vec2 initial position offset of the menu body
---@param shake_max_time number duration of the shaking effect
---@param shake_amplitude number amplitude of the shaking effect; shaking only occurs in x direction
---@param shake_period number period of harmonic (sine) motion of shaking effect in frames
---@param blink_speed number speed of selectable blinking
---@param blink_color_a math.vec4 blinking color; of form {r, g, b, a}
---@param blink_color_b math.vec4 blinking color; of form {r, g, b, a}
---@param normal_color math.vec4 color of the text when they are not blinking; of form {r, g, b, a}
---@param title_pos_offset math.vec2 title position relative to the body of the menu
---@param title_text_obj ui.TextObject text object describing how the title text should look; require everything
---@param body_text_obj ui.TextObject text object describing how the body text should look; require everything except text and color
---@param pos_increment math.vec2 increment in position between each two menu selectables
---@param selectable_array table an array of selectables in this menu
---@param transition_fly_directions table an array of numbers specifying the transition flying direction in degrees
---@param transition_fly_distances table an array of numbers specifying the transition flying distance
function M.__create(
            selection_input,
            focused_index,
            init_pos_offset,
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
    local self = ShakeEffListingSelector.__create(selection_input, focused_index, init_pos_offset, shake_max_time, shake_amplitude, shake_period)

    self.blink_speed = blink_speed
    self.blink_color_a = blink_color_a
    self.blink_color_b = blink_color_b
    self.normal_color = normal_color

    self.init_pos_offset = init_pos_offset
    self.title_pos_offset = title_pos_offset
    self.title_text_obj = title_text_obj
    self.body_text_obj = body_text_obj
    self.pos_increment = pos_increment
    self.selectable_array = selectable_array
    self.transition_fly_directions = transition_fly_directions
    self.transition_fly_distances = transition_fly_distances

    return self
end

---set the base position of the menu
---@param pos_offset math.vec2
function M:setPosition(pos_offset)
    self.init_pos_offset = pos_offset
    self:updatePosition()
end

function M:continueMenu()
    local state = self.transition_state
    local del_flag = self:getTransitionProgress() == 0 and (state == MenuConst.OUT_BACKWARD or state == MenuConst.OUT_FORWARD)
    return not del_flag
end

function M:isInputEnabled()
    return self.is_selecting and self.transition_progress == 1
end

---@param dt number time elapsed since last update
function M:update(dt)
    InteractiveSelector.update(self, dt)

    self:updateShakeTimer(dt)

    self:updatePosition()
end

function M:updatePosition()
    -- calculate position of the menu by transition progress
    local base_pos = self.init_pos_offset
    local p = self.transition_progress
    local distance = (1 - p) ^ 2 * self.transition_fly_distances[self.transition_state]
    local direction = self.transition_fly_directions[self.transition_state]
    self.pos_offset = base_pos + Vec2(cos(direction), sin(direction)) * distance
end

---test for and process user input on the menu
function M:processInput()
    local input = self.selection_input

    local focused_index = self.focused_index
    -- moving through options
    if input:isAnyDeviceKeyJustChanged("up", false, true) then
        self:moveFocus(focused_index - 1)
    elseif input:isAnyDeviceKeyJustChanged("down", false, true) then
        self:moveFocus(focused_index + 1)
    end

    -- selecting an option
    if input:isAnyDeviceKeyJustChanged("select", false, true) then
        self:select(focused_index)
    end
end

function M:select(i)
    self.is_selecting = false
    self.selected_choice = self.selectable_array[i].choices
end

---@param index number
---@return math.vec2 the relative postion of the option in relation to the selector
function M:getListingPos(index)
    return self.pos_increment * (index - 1)
end

function M:render()
    -- render title
    local pos = self.pos_offset + self.title_pos_offset
    self.title_text_obj:render(pos.x, pos.y)

    -- render body
    local body_text_obj = self.body_text_obj
    for index = 1, #self.selectable_array do
        local item_pos = self.pos_offset + self:getListingPosAfterShakeEff(index)
        local color_vec
        -- the selected selectable will blink
        if index == self.focused_index then
            local lerp_coeff = 0.5 + 0.5 * sin(self.timer * self.blink_speed)
            color_vec = self.blink_color_a * lerp_coeff + self.blink_color_b * (1 - lerp_coeff)
        else
            color_vec = self.normal_color
        end
        body_text_obj:set_color(lstg.Color(color_vec.w, color_vec.x, color_vec.y, color_vec.z))

        body_text_obj:set_text(self.selectable_array[index].text)
        body_text_obj:render(item_pos.x, item_pos.y)
    end
end

local Input = require("BHElib.input.input_and_recording")
local MenuConst = require("BHElib.scenes.menu.menu_const")
local TextObject = require("BHElib.ui.text_object")

---@param init_focused_index number initial value of the selected index
---@param scale number scaling of the displayed text size and line height
---@param fly_distance number distance of travelling when transition in/out
---@param relative_pos math.vec2 relative position of the menu page
---@param selectable_array table an array of SimpleMenuSelector.Selectable objects
---@param menu_page_title string text title of the page
function M.shortInit(init_focused_index, scale, fly_distance, relative_pos, selectable_array, menu_page_title, enter_dir, exit_dir)
    -- create simple menu selector
    local text_line_height = MenuConst.line_height * scale
    local text_align = {"center"}
    local title_color = MenuConst.title_color
    local title_text_object = TextObject(
            menu_page_title,
            Color(title_color.w, title_color.x, title_color.y, title_color.z),
            MenuConst.font_name,
            MenuConst.font_size * scale,
            text_align
    )
    local body_text_object = TextObject(
            nil,
            nil,
            MenuConst.font_name,
            MenuConst.font_size * scale,
            text_align
    )
    local transition_fly_directions = {
        [InteractiveSelector.IN_FORWARD] = enter_dir or -180,
        [InteractiveSelector.IN_BACKWARD] = exit_dir or 0,
        [InteractiveSelector.OUT_FORWARD] = exit_dir or 0,
        [InteractiveSelector.OUT_BACKWARD] = enter_dir or -180,
    }
    local transition_fly_distances = {
        [InteractiveSelector.IN_FORWARD] = fly_distance,
        [InteractiveSelector.IN_BACKWARD] = fly_distance,
        [InteractiveSelector.OUT_FORWARD] = fly_distance,
        [InteractiveSelector.OUT_BACKWARD] = fly_distance,
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