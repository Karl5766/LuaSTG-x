---------------------------------------------------------------------------------------------------
---title_menu_page.lua
---author: Karl
---date: 2021.5.1
---desc: implements the title screen; specifically the menu selection part
---------------------------------------------------------------------------------------------------

local MenuPage = require("BHElib.ui.menu.menu_page")

local M = LuaClass("menu.TitleMenuPage", MenuPage)

local SimpleMenuSelector = require("BHElib.ui.selectors.simple_menu_selector")
local ShakeEffListingSelector = require("BHElib.ui.selectors.shake_eff_listing_selector")
local MenuConst = require("BHElib.ui.menu.menu_global")
local Coordinates = require("BHElib.unclassified.coordinates_and_screen")
local FS = require("file_system.file_system")
local _init_callbacks = require("BHElib.scenes.main_menu.main_menu_page_init_callbacks")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Vec2 = math.vec2
local Vec4 = math.vec4
local Selectable = ShakeEffListingSelector.Selectable

---------------------------------------------------------------------------------------------------

local function CreateSelectableArray()
    local ret = {
        Selectable("Start Game", {
            {MenuConst.CHOICE_GO_TO_MENUS, {}}, -- directly start game
            {MenuConst.CHOICE_SPECIFY, "game_mode", "all"}
        }),
        Selectable("Start Replay",{
            {MenuConst.CHOICE_GO_TO_MENUS, {
                {_init_callbacks.ReplayLoader, "replay_loader"}
            }},
            {MenuConst.CHOICE_SPECIFY, "is_replay", true}
        }),
        Selectable("Exit Game", {
            {MenuConst.CHOICE_EXIT}
        })
    }
    return ret
end

---@param init_focused_index number initial position index of focused selectable
function M.__create(init_focused_index, temp_replay_file_path)
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
    local self = MenuPage(selector)
    self.temp_replay_file_path = temp_replay_file_path

    return self
end

---save replay to target path if the target path is specified
---@param menu_page_array MenuPageArray
function MenuPage:onCascade(menu_page_array)
    local target_path = menu_page_array:queryChoice("replay_path_for_write")
    if target_path ~= nil then
        if target_path then
            FS.copyFile(self.temp_replay_file_path, target_path)
        end
    end
end

return M