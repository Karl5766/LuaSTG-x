---------------------------------------------------------------------------------------------------
---screen.lua
---date: 2021.2.12
---desc: Defines the CalcScreen method used to determine the width and height of screen
---modifier:
---     Karl, 2021.2.14, split part of the file to play_field_boundary.lua
---------------------------------------------------------------------------------------------------

screen = {}

-- for calcScreen()
local _screen_width = 640
local _screen_height = 480

---set the values under the global "screen" table by the values of setting.resx and setting.resy;
---
---screen.dx - x offset of the entire display area
---
---screen.dy - y offset of the entire display area
---
---screen.scale - scaling coefficient
function CalcScreen()
    local resx = setting.resx
    local resy = setting.resy
    if resx * _screen_height > resy * _screen_width then
        --适应高度
        local scale = resy / _screen_height
        screen.scale = scale
        local dx = (resx - scale * _screen_width) / scale / 2
        screen.dx = dx
        screen.dy = 0
    else
        --适应宽度
        local scale = resx / _screen_width
        screen.scale = scale
        local dy = (resy - scale * _screen_height) / scale / 2
        screen.dy = dy
        screen.dx = 0
    end
end
CalcScreen()