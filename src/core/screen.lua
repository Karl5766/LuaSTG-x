---------------------------------------------------------------------------------------------------
---screen.lua
---date: 2021.2.12
---desc: Defines the lstg.calcScreen method used to determine the width and height of screen
---modifier:
---     Karl, 2021.2.14, split part of the file to play_field_boundary.lua
---------------------------------------------------------------------------------------------------

screen = {}

---set the values under the global "screen" table by the values of setting.resx and setting.resy;
---
---screen.width - width of the screen
---
---screen.height - height of the screen
---
---screen.dx - x offset of the entire display area
---
---screen.dy - y offset of the entire display area
---
---screen.scale - scaling coefficient
function lstg.calcScreen()
    local resx = setting.resx
    local resy = setting.resy
    ---屏幕宽度
    screen.width = 640
    ---屏幕高度
    screen.height = 480
    if resx * screen.height > resy * screen.width then
        --适应高度
        local scale = resy / screen.height
        screen.scale = scale
        local dx = (resx - scale * screen.width) / scale / 2
        screen.dx = dx
        screen.dy = 0
    else
        --适应宽度
        local scale = resx / screen.width
        screen.scale = scale
        local dy = (resy - scale * screen.height) / scale / 2
        screen.dy = dy
        screen.dx = 0
    end
end
lstg.calcScreen()