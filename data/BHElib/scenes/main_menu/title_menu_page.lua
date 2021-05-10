---------------------------------------------------------------------------------------------------
---title_menu_page.lua
---author: Karl
---date: 2021.5.1
---desc: implements the title screen; specifically the menu selection part
---------------------------------------------------------------------------------------------------

local MenuPage = require("BHElib.scenes.menu.menu_page")

local M = LuaClass("menu.TitleMenuPage", MenuPage)

local SimpleMenuSelector = require("BHElib.ui.selectors.simple_menu_selector")
local MenuConst = require("BHElib.scenes.menu.menu_const")
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
    local start_game_option = Selectable("Start Game", start_game_choices)

    local start_replay_choices = {
        {MenuConst.CHOICE_GO_TO_MENUS, {}},  -- directly start game
        {MenuConst.CHOICE_SPECIFY, "game_mode", "all"},
        {MenuConst.CHOICE_SPECIFY, "is_replay", true}
    }
    local start_replay_option = Selectable("Start Replay", start_replay_choices)

    local exit_choices = {
        {MenuConst.CHOICE_EXIT}
    }
    local exit_option = Selectable("Exit Game", exit_choices)

    local ret = {start_game_option, start_replay_option, exit_option}
    return ret
end

---@param init_focused_index number initial position index of focused selectable
function M.__create(init_focused_index)
    -- create simple menu selector

    local width = Coordinates.getResolution()
    local ui_scale = Coordinates.getUIScale()
    width = width / ui_scale  -- convert to "ui" coordinates

    local center_x, center_y = Coordinates.getScreenCenterInUI()

    local selector = SimpleMenuSelector.shortInit(
            init_focused_index,
            1,
            width * 0.7,
            Vec2(center_x, center_y),
            CreateSelectableArray(),
            "Main Menu"
    )

    return MenuPage(selector)
end

return M