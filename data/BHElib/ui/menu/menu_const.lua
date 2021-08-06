---------------------------------------------------------------------------------------------------
---menu_actions.lua
---author: Karl
---date: 2021.5.1
---desc: defines constants values in menus; menus abide to using them by default
---------------------------------------------------------------------------------------------------
---cache variables and functions

local Vec2 = math.vec2
local Vec4 = math.vec4

---------------------------------------------------------------------------------------------------

local M = {
    font_name           = "font:menu",
    font_size           = 0.625,
    line_height         = 24,
    char_width          = 20,
    num_width           = 12.5,
    title_color         = Vec4(255, 255, 255, 255),  -- r, g, b, a
    unfocused_color     = Vec4(128, 128, 128, 255),
    focused_color_a     = Vec4(255, 255, 255, 255),
    focused_color_b     = Vec4(255, 192, 192, 255),
    blink_speed         = 7,
    shake_time          = 9,
    shake_period        = 9,
    shake_range         = 3,
    --符卡练习每页行数
    sc_pr_line_per_page = 12,
    -- 符卡练习每行高度
    sc_pr_line_height   = 22,
    --符卡练习每行宽度
    sc_pr_width         = 320,
    sc_pr_margin        = 8,
    rep_font_size       = 0.6,
    rep_line_height     = 20,
}

---going back to the previous menu that spawned this menu; play the exit animation for this menu
---@param t number exit time in frames
M.CHOICE_GO_BACK = 1

---exit all the menus; play their exit animations simultaneously
---@param t number exit time in frames
M.CHOICE_EXIT = 2

---go to menus in an array of menus in order
---@param menus table an array of {class_id, menu_id} specifying the id for the menu class and the menu
M.CHOICE_GO_TO_MENUS = 3

---insert a choice into menu page array
---@param key string
---@param value any
M.CHOICE_SPECIFY = 4

---execute a given function, passing menu_manager as the first parameter
M.CHOICE_EXECUTE = 5

---send a cascade signal to all of the parents of this page
M.CHOICE_CASCADE = 6

M.IN_FORWARD = 1
M.IN_BACKWARD = 2
M.OUT_FORWARD = 3
M.OUT_BACKWARD = 4
M.OTHER = 5

return M