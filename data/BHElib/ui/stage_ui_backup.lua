-----------------------------------------------------------------------------------
---stage_ui.lua
---Copyright (C) 2018-2020 Xrysnow. All rights reserved.
---desc: Implementation of stg HUD rendering
---modifier:
---     Karl, 2021.2.18, split the DrawFrame() function to menu_2d_background.lua
-----------------------------------------------------------------------------------

local M = {}

function M.draw()
    local cur_font = "font:hud_default"

    local diff = "Easy"

    RenderText(cur_font, diff, 580, 466, 0.5, 'center')

    local line_x = 560
    local xx
    local yy = 402
    Render('line_1', line_x, yy, 0, 1, 1)
    yy = yy - 32
    Render('line_2', line_x, yy, 0, 1, 1)
    yy = yy - 36
    Render('line_3', line_x, yy, 0, 1, 1)
    yy = yy - 48
    Render('line_4', line_x, yy, 0, 1, 1)
    yy = yy - 42
    Render('line_5', line_x, yy, 0, 1, 1)
    yy = yy - 23
    Render('line_6', line_x, yy, 0, 1, 1)
    yy = yy - 22
    Render('line_7', line_x, yy, 0, 1, 1)

    -- high score
    SetFontState(cur_font, '', Color(0xFFADADAD))
    RenderScore(cur_font, 0, 636, 420, 0.43, 'right')

    -- current score
    SetFontState(cur_font, '', Color(0xFFFFFFFF))
    RenderScore(cur_font, 0, 636, 388, 0.43, 'right')

    -- life and bomb
    yy = 332
    xx = 608
    RenderText(cur_font, string.format('%d/5', 0), xx, yy, 0.35, 'left')
    RenderText(cur_font, string.format('%d/5', 0), xx, yy - 48, 0.35, 'left')
    
    SetFontState(cur_font, '', Color(0xFFCD6600))
    SetFontState(cur_font, '', Color(0xFF22D8DD))

    -- render power
    xx = 636
    yy = 262

    RenderText(cur_font, '', 0, 0)
    RenderText(cur_font, string.format('%d.    /4.',
            math.floor(lstg.var.power / 100)),
            xx - 16, yy, 0.4, 'right')

    RenderText(cur_font, string.format('      %d%d        00',
            math.floor((lstg.var.power % 100) / 10),
            math.floor(lstg.var.power % 10)),
            xx + 1, yy - 3.5, 0.3, 'right')
end

return M