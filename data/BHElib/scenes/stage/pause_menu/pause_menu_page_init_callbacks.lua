---------------------------------------------------------------------------------------------------
---pause_menu_page_init_callbacks.lua
---author: Karl
---date: 2021.7.7
---desc: implements the callbacks that initializes the pause menu menu pages
---------------------------------------------------------------------------------------------------

---@class PauseMenuPageInitCallbacks
local _callbacks = {}

local MenuConst = require("BHElib.scenes.menu.menu_const")
local ShakeEffListingSelector = require("BHElib.ui.selectors.shake_eff_listing_selector")
local Selectable = ShakeEffListingSelector.Selectable
local Coordinates = require("BHElib.coordinates_and_screen")
local SimpleMenuSelector = require("BHElib.ui.selectors.simple_menu_selector")
local MenuPage = require("BHElib.scenes.menu.menu_page")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Vec2 = math.vec2

---------------------------------------------------------------------------------------------------
---menu page init callbacks

local function CreateSelectableArrayForReplayEndMenu()
    local ret = {
        -- option display text, followed by the choices
        Selectable("Return to Main Menu", {
            {MenuConst.CHOICE_EXIT},
            {MenuConst.CHOICE_SPECIFY, "to_do", "quit_to_menu"},
        }),
        Selectable("Replay Again", {
            {MenuConst.CHOICE_EXIT},
            {MenuConst.CHOICE_SPECIFY, "to_do", "restart_scene_group"},
        }),
    }
    return ret
end

function _callbacks.ReplayEndMenuTitle(menu_manager)
    -- create simple menu selector

    local l, r, b, t = Coordinates.getPlayfieldBoundaryInGame()
    local height = (t - b) * 0.7

    local center_x, center_y = 0, 0

    local selector = SimpleMenuSelector.shortInit(
            1,
            1,
            height,
            Vec2(center_x, center_y),
            CreateSelectableArrayForReplayEndMenu(),
            "End of Replay",
            90,
            90
    )

    return MenuPage(selector)
end

local function CreateSelectableArrayForUserPauseMenu()
    local ret = {
        -- option display text, followed by the choices
        Selectable("Resume Game", {
            {MenuConst.CHOICE_EXIT},
            {MenuConst.CHOICE_SPECIFY, "to_do", "resume"},
        }),
        Selectable("Quit to Main Menu", {
            {MenuConst.CHOICE_EXIT},
            {MenuConst.CHOICE_SPECIFY, "to_do", "quit_to_menu"},
        }),
        Selectable("Restart the Game", {
            {MenuConst.CHOICE_EXIT},
            {MenuConst.CHOICE_SPECIFY, "to_do", "restart_scene_group"},
        }),
    }
    return ret
end

---@param init_focused_index number initial position index of focused selectable
function _callbacks.UserPauseMenuTitle(menu_manager)
    -- create simple menu selector

    local l, r, b, t = Coordinates.getPlayfieldBoundaryInGame()
    local height = (t - b) * 0.7

    local center_x, center_y = 0, 0

    local selector = SimpleMenuSelector.shortInit(
            1,
            1,
            height,
            Vec2(center_x, center_y),
            CreateSelectableArrayForUserPauseMenu(),
            "Pause Menu",
            90,
            90
    )

    return MenuPage(selector)
end

return _callbacks