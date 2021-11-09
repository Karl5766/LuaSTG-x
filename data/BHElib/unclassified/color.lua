---------------------------------------------------------------------------------------------------
---color.lua
---date created: 2021.11.5
---reference: THlib/bullet/bullet.lua
---desc: Bullet/Enemy color related mappings;
---------------------------------------------------------------------------------------------------

local M = {}

---------------------------------------------------------------------------------------------------

---each item is a {variable_name, common name} pair
M.all_color_list = {
    {"COLOR_DEEP_RED", "deep red"},
    {"COLOR_RED", "red"},
    {"COLOR_DEEP_PURPLE", "deep purple"},
    {"COLOR_PURPLE", "purple"},
    {"COLOR_DEEP_BLUE", "deep blue"},
    {"COLOR_BLUE", "blue"},
    {"COLOR_ROYAL_BLUE", "royal blue"},
    {"COLOR_CYAN", "cyan"},
    {"COLOR_DEEP_GREEN", "deep green"},
    {"COLOR_GREEN", "green"},
    {"COLOR_CHARTREUSE", "chartreuse"},
    {"COLOR_YELLOW", "yellow"},
    {"COLOR_GOLDEN_YELLOW", "golden yellow"},
    {"COLOR_ORANGE", "orange"},
    {"COLOR_DEEP_GRAY", "deep gray"},
    {"COLOR_GRAY", "gray"},

    {"COLOR_PINK", "pink"},
}

M.all_color_indices = nil

---total number of color themes;
function M:init()
    local colors = self.all_color_list

    ---total number of color themes;
    TOTAL_NUM_COLORS = #colors

    M.all_color_indices = {}
    for i, info in ipairs(colors) do
        M.all_color_indices[i] = i
    end

    ---COLOR_DEEP_RED = 1
    ---COLOR_RED = 2
    ---... etc.
    for i, info in ipairs(colors) do
        local variable_name = info[1]
        _G[variable_name] = i
    end


    ---each of the follows uses a subset of colors

    M.touhou_theme = {
        COLOR_DEEP_RED, COLOR_RED, COLOR_DEEP_PURPLE, COLOR_PURPLE,
        COLOR_DEEP_BLUE, COLOR_BLUE, COLOR_ROYAL_BLUE, COLOR_CYAN,
        COLOR_DEEP_GREEN, COLOR_GREEN, COLOR_CHARTREUSE, COLOR_YELLOW,
        COLOR_GOLDEN_YELLOW, COLOR_ORANGE, COLOR_DEEP_GRAY, COLOR_GRAY,
    }

    M.touhou_theme_half = {
        COLOR_RED, COLOR_PURPLE,
        COLOR_BLUE, COLOR_CYAN,
        COLOR_GREEN, COLOR_YELLOW,
        COLOR_ORANGE, COLOR_GRAY,
    }

    M.touhou_theme_other_half = {
        COLOR_DEEP_RED, COLOR_DEEP_PURPLE,
        COLOR_DEEP_BLUE, COLOR_ROYAL_BLUE,
        COLOR_DEEP_GREEN, COLOR_CHARTREUSE,
        COLOR_GOLDEN_YELLOW, COLOR_DEEP_GRAY,
    }

    M.mugenri_theme = {
        COLOR_RED, COLOR_ORANGE, COLOR_YELLOW, COLOR_GREEN, COLOR_BLUE,
        COLOR_PURPLE, COLOR_PINK, COLOR_GRAY, COLOR_DEEP_GRAY,
    }

    -- basically reversed order
    M.mugenri_theme_animated = {
        COLOR_DEEP_GRAY, COLOR_GRAY, COLOR_PINK, COLOR_PURPLE,
        COLOR_BLUE, COLOR_GREEN, COLOR_YELLOW, COLOR_ORANGE, COLOR_RED,
    }

    M.fire_bullet_theme = {
        COLOR_RED
    }
end

function M:get_variable_name(color_index)
    return self.all_color_list[color_index][1]
end

function M:get_common_name(color_index)
    return self.all_color_list[color_index][2]
end

return M