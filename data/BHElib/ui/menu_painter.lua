---------------------------------------------------------------------------------------------------
---menu_painter.lua
---desc: Implementation of menu rendering
---------------------------------------------------------------------------------------------------

---@type Coordinates
local _scr = require("BHElib.coordinates_and_screen")

---@class MenuPainter
local M = {}

---------------------------------------------------------------------------------------------------
---draw functions

function M.draw(img_background, background_scale, font_profile_text, img_border)
    SetFontState(font_profile_text, '', Color(0xFFFFFFFF))

    _timer = _timer + 1

    -- render the hud background
    M.drawHudBackground(img_background, background_scale)

    -- render a thin rectangular border
    SetImageState(img_border, '', color.Red)
    local l, r, b, t = scr.getPlayfieldBoundaryInUI()

    local sprite_size = FindResSprite(img_border):getSprite():getContentSize()
    local ww, hh = sprite_size.width, sprite_size.height
    Render(img_border, (l + r) / 2, t, 0, (r - l + 1) / ww, 2 / hh)
    Render(img_border, (l + r) / 2, b, 0, (r - l + 1) / ww, 2 / hh)
    Render(img_border, l, (t + b) / 2, 0, 2 / ww, (t - b + 1) / hh)
    Render(img_border, r, (t + b) / 2, 0, 2 / ww, (t - b + 1) / hh)
    SetImageState(img_border, '', color.White)

    RenderPerformanceProfile(font_profile_text)
end

---@param text string
---@param font_name string
---@param font_size number
---@param font_align table an array of strings that specifies the alignment options
---@param color lstg.Color
---@param x number
---@param y number
function M.drawTextTitle(text, font_name, font_align, color, x, y)
    RenderTTF(font_name, text, x, x, y, y, color, unpack(font_align))
end

---@param text_font_name string name of the font for displaying both the title and the options
---@param title_color table {r, g, b}
---@param option_text_array table an array of options' text content
---@param option_unselected_color table {r, g, b}
---@param option_selected_color_blink1 table {r, g, b}
---@param option_selected_color_blink2 table {r, g, b}
---@param select_index number index of the selected option, starting from 1
---@param font_align table an array of strings that specifies the alignment options E.g. {"center", "vcenter"}
function M.drawTextMenuPage(text_font_name,
                            title_text,
                            title_color,
                            option_text_array,
                            option_unselected_color,
                            option_selected_color_blink1,
                            option_selected_color_blink2,
                            option_text_line_height,
                            select_index,
                            center_x,
                            center_y,
                            transparency,
                            blink_timer,
                            blink_speed,
                            shake_timer,
                            shake_amplitude,
                            shake_speed,
                            font_align)

    local top_y = center_y + (#option_text_array - 1) * option_text_line_height * 0.5
    M.drawTextTitle(
            title_text,
            text_font_name,
            font_align,
            Color(transparency * 255, unpack(title_color)),
            center_x,
            top_y + option_text_line_height
    )
    for i = 1, #option_text_array do
        local option_x = center_x
        local option_y = top_y - i * option_text_line_height
        local option_text = option_text_array[i]

        local color = option_unselected_color

        if i == select_index then
            -- modify color and option_x
            color = {}
            local k = cos(blink_timer * blink_speed) ^ 2
            for j = 1, 3 do
                color[j] = option_selected_color_blink1[j] * k + option_selected_color_blink2[j] * (1 - k)
            end

            option_x = option_x + shake_amplitude * sin(shake_speed * shake_timer)
        end

        -- display the text
        local finalColor = Color(transparency * 255, unpack(color))
        RenderTTF(
                text_font_name,
                option_text,
                option_x,
                option_x,
                option_y,
                option_y,
                finalColor,
                unpack(font_align)
        )
    end
end

return M