---------------------------------------------------------------------------------------------------
---color.lua
---date created: 2021.11.5
---reference: THlib/bullet/bullet.lua
---desc: Bullet/Enemy color related mappings;
---------------------------------------------------------------------------------------------------

local M = {}

---------------------------------------------------------------------------------------------------

---each item is a {variable_name, common name} pair
M.color_list = {
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
}

M.all_color_indices = nil

---total number of color themes;
function M:init()
    local colors = self.color_list

    ---total number of color themes;
    NUM_COLOR_THEMES = #colors

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
end

function M:get_variable_name(color_index)
    return self.color_list[color_index][1]
end

function M:get_common_name(color_index)
    return self.color_list[color_index][2]
end

return M