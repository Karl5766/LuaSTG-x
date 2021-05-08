---------------------------------------------------------------------------------------------------
---main_menu_page.lua
---author: Karl
---date: 2021.5.1
---desc: implements MainMenuPage
---------------------------------------------------------------------------------------------------

local MenuPage = require("BHElib.scenes.menu.menu_page")

local M = LuaClass("menu.MainMenuPage", MenuPage)

local Input = require("BHElib.input.input_and_recording")
local SimpleMenuSelector = require("BHElib.ui.selectors.simple_menu_selector")
local MenuConst = require("BHElib.scenes.menu.menu_const")
local TextObject = require("BHElib.ui.text_object")
local InteractiveSelector = require("BHElib.ui.selectors.interactive_selector")
local Coordinates = require("BHElib.coordinates_and_screen")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Vec2 = math.vec2
local Vec4 = math.vec4
local Selectable = SimpleMenuSelector.Selectable

---------------------------------------------------------------------------------------------------

local function CreateSelectableArray()
    local start_game_choices = {
        {MenuConst.CHOICE_GO_TO_MENUS, {}},  -- directly start game
        {MenuConst.CHOICE_SPECIFY, "game_mode", "all"}
    }
    local start_game_option = Selectable(600, "Start Game", start_game_choices)

    local start_replay_choices = {
        {MenuConst.CHOICE_GO_TO_MENUS, {}},  -- directly start game
        {MenuConst.CHOICE_SPECIFY, "game_mode", "all"},
        {MenuConst.CHOICE_SPECIFY, "is_replay", true}
    }
    local start_replay_option = Selectable(600, "Start Replay", start_replay_choices)

    local exit_choices = {
        {MenuConst.CHOICE_EXIT}
    }
    local exit_option = Selectable(600, "Exit Game", exit_choices)

    local ret = {start_game_option, start_replay_option, exit_option}
    return ret
end

---@param init_focused_index number initial position index of focused selectable
function M.__create(init_focused_index)
    -- create simple menu selector
    local text_line_height = MenuConst.line_height
    local text_align = {"center"}
    local title_color = MenuConst.title_color
    local title_text_object = TextObject(
            "Main Menu",
            Color(title_color.w, title_color.x, title_color.y, title_color.z),
            MenuConst.font_name,
            MenuConst.font_size,
            text_align
    )
    local body_text_object = TextObject(
            nil,
            nil,
            MenuConst.font_name,
            MenuConst.font_size,
            text_align
    )
    local transition_fly_directions = {
        [InteractiveSelector.IN_FORWARD] = 180,
        [InteractiveSelector.IN_BACKWARD] = 0,
        [InteractiveSelector.OUT_FORWARD] = 0,
        [InteractiveSelector.OUT_BACKWARD] = 180,
    }
    local width = Coordinates.getResolution()
    local ui_scale = Coordinates.getUIScale()
    width = width / ui_scale  -- convert to "ui" coordinates
    local distance = width * 0.7
    local transition_fly_distances = {
        [InteractiveSelector.IN_FORWARD] = distance,
        [InteractiveSelector.IN_BACKWARD] = distance,
        [InteractiveSelector.OUT_FORWARD] = distance,
        [InteractiveSelector.OUT_BACKWARD] = distance,
    }

    local center_x, center_y = Coordinates.getScreenCenterInUI()
    local selector = SimpleMenuSelector(
            Input,
            init_focused_index,
            Vec2(center_x, center_y),
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
            CreateSelectableArray(),
            transition_fly_directions,
            transition_fly_distances
    )

    local self = MenuPage(selector)
    return self
end

return M