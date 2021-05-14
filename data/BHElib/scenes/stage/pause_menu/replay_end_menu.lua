---------------------------------------------------------------------------------------------------
---replay_end_menu.lua
---author: Karl
---date: 2021.3.26
---desc: replay end menu is a pause menu displayed in the end of a replay
---------------------------------------------------------------------------------------------------

local ReplayEndMenu = {}

local PauseMenuManager = require("BHElib.scenes.stage.pause_menu.pause_menu")
local MenuPage = require("BHElib.scenes.menu.menu_page")

---@class ReplayEndMenuPage:PauseMenu
ReplayEndMenu.Page = LuaClass("menu.ReplayEndMenuPage", MenuPage)

---@class ReplayEndMenuManager:PauseMenuManager
ReplayEndMenu.Manager = LuaClass("menu.ReplayEndMenuManager", PauseMenuManager)

local SimpleMenuSelector = require("BHElib.ui.selectors.simple_menu_selector")
local ShakeEffListingSelector = require("BHElib.ui.selectors.shake_eff_listing_selector")
local MenuConst = require("BHElib.scenes.menu.menu_const")
local Coordinates = require("BHElib.coordinates_and_screen")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Vec2 = math.vec2
local Selectable = ShakeEffListingSelector.Selectable

---------------------------------------------------------------------------------------------------
---menu page

local function CreateSelectableArray()
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

---@param init_focused_index number initial position index of focused selectable
function ReplayEndMenu.Page.__create(init_focused_index)
    -- create simple menu selector

    local l, r, b, t = Coordinates.getPlayfieldBoundaryInGame()
    local height = (t - b) * 0.7

    local center_x, center_y = 0, 0

    local selector = SimpleMenuSelector.shortInit(
            init_focused_index,
            1,
            height,
            Vec2(center_x, center_y),
            CreateSelectableArray(),
            "End of Replay",
            90,
            90
    )

    return MenuPage(selector)
end

---------------------------------------------------------------------------------------------------
---menu manager

function ReplayEndMenu.Manager.__create(stage)
    local self = PauseMenuManager.__create(stage)
    return self
end

function ReplayEndMenu.Manager:createMenuPageFromClass(class_id)
    if class_id == "menu.ReplayEndMenuPage" then
        return ReplayEndMenu.Page(1)
    else
        error("ERROR: Unexpected menu page class!")
    end
end

function ReplayEndMenu.Manager:initMenuPages()
    local menu_pages = {
        {"menu.ReplayEndMenuPage", "pause_page"},
    }
    for i = 1, #menu_pages do
        local class_id, menu_id = unpack(menu_pages[i])
        local menu_page = self:setupMenuPageAtPos(class_id, menu_id, i)
        --menu_page:setLayer(LAYER_HUD - 1)
        menu_page:setRenderView("game")
    end

    -- setup choices
    -- currently no choices are needed

    local menu_page_array = self.menu_page_array
    local menu_id = menu_page_array:getMenuId(menu_page_array:getSize())
    local cur_menu_page = self.menu_page_pool:getMenuFromPool(menu_id)
    cur_menu_page:setPageEnter(true, self.transition_speed)
end

return ReplayEndMenu