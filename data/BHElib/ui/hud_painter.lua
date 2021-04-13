---------------------------------------------------------------------------------------------------
---hud.lua
---desc: Implementation of stg HUD rendering
---modifier:
---     Karl, 2021.2.18, split from after_load.lua
---------------------------------------------------------------------------------------------------

---@type Coordinates
local scr = require("BHElib.coordinates_and_screen")

local M = {}

---------------------------------------------------------------------------------------------------
---performance profile

local _dt = {}
local _fps = 0
local _calc_t = 0
local function calcFPS(dt)
    _calc_t = _calc_t + 1
    table.insert(_dt, dt)
    if _calc_t % 30 == 0 then
        local sum = 0
        for _, v in ipairs(_dt) do
            sum = sum + v
        end
        _fps = 30000 / sum
        _dt = {}
    end
    return _fps
end

local pros = {
    'ObjFrame',
    --'UserSystemOp',
    'CollisionCheck',
    'UpdateXY',
    'AfterFrame',
    'RenderFunc',
    --'BeginScene',
    --'stagerender',
    --'BeforeRender',
    --'ObjRender',
    --'AfterRender',
    --'EndScene',
    'AppFrame::PF_Schedule',
    'AppFrame::PF_Visit',
    'AppFrame::PF_Render',
    'pullEvents',
    --'transform',
    --'trans_par',
    --'collision',
}
local _times = {}
local _timer = 0
local sw = lstg.StopWatch()

local function RenderPerformanceProfile(font_display)
    -- for performance profiling
    local dt = sw:get() * 1000
    sw:reset()
    local fps = calcFPS(dt)
    local str = ''
    --
    local t_sum = 0
    for i, v in ipairs(pros) do
        local tt = profiler.getAverage(v)
        t_sum = t_sum + tt
        _times[i] = tt * 1000
    end
    for i, v in ipairs(pros) do
        str = string.format('%s%s %.2f\n', str, v, _times[i])
    end

    RenderText(font_display, str, 730, 50, 0.5, 'right', 'bottom')
    --]]
    str = string.format('%.1f fps', fps)
    str = string.format('obj:%d\n', GetnObj()) .. str

    RenderText(font_display, str, 730, 0, 1, 'right', 'bottom')
end

---------------------------------------------------------------------------------------------------

function M.draw(img_background, background_scale, font_profile, img_border)
    scr.setRenderView("ui")

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

    SetFontState(font_profile, '', Color(0xFFFFFFFF))
    RenderPerformanceProfile(font_profile)
end

local _input = require("BHElib.input.input_and_recording")
local _coordinates = require("BHElib.coordinates_and_screen")

function M.drawKeys()
    local distance = 50
    local offsets = {
        {0, 0},
        {distance, 0},
        {distance * 2, 0},
        {distance, distance},
    }
    local function_keys = {
        "left",
        "down",
        "right",
        "up",
    }
    local normal_pos = {500, 100}
    local replay_pos = {500, 240}
    local text_color = Color(255, 60, 60, 60)
    local comment_color = Color(255, 255, 255, 255)

    for i = 1, 4 do
        -- draw keys at the position
        local offset = offsets[i]
        local key_name = function_keys[i]
        local x, y = offset[1] + normal_pos[1], offset[2] + normal_pos[2]
        if _input:isAnyDeviceKeyDown(key_name) then
            Render("image:button_pressed", x, y, 0, 1, 1)
        else
            Render("image:button_normal", x, y, 0, 1, 1)
        end
        local text_y = y + 14
        RenderTTF("font:menu", key_name, x, x, text_y, text_y, text_color, "center")
    end
    do
        local x, text_y = normal_pos[1] + distance, normal_pos[2] - distance * 0.5
        RenderTTF("font:menu", "device input", x, x, text_y, text_y, comment_color, "center")
    end

    for i = 1, 4 do
        -- draw keys at the position
        local offset = offsets[i]
        local key_name = function_keys[i]
        local x, y = offset[1] + replay_pos[1], offset[2] + replay_pos[2]
        if _input:isAnyRecordedKeyDown(key_name) then
            Render("image:button_pressed", x, y, 0, 1, 1)
        else
            Render("image:button_normal", x, y, 0, 1, 1)
        end
        local color = Color(255, 60, 60, 60)
        local text_y = y + 14
        RenderTTF("font:menu", key_name, x, x, text_y, text_y, text_color, "center")
    end
    do
        local x, text_y = replay_pos[1] + distance, replay_pos[2] - distance * 0.5
        RenderTTF("font:menu", "recorded input", x, x, text_y, text_y, comment_color, "center")
    end

    --mouse text
    do
        local x, y = _input:getMousePosition()
        local offx, offy = _coordinates.getUIOriginInRes()
        local sx, sy = _coordinates.getUIScale()
        x, y = x - offx / sx, y - offy / sy
        if _input:isMousePressed() then
            RenderTTF("font:menu", "mouse pressed", x, x, y, y, comment_color, "left")
        else
            RenderTTF("font:menu", "mouse", x, x, y, y, comment_color, "left")
        end
    end
    do
        local x, y = _input:getRecordedMousePosition()
        local offx, offy = _coordinates.getUIOriginInRes()
        local sx, sy = _coordinates.getUIScale()
        x, y = x - offx / sx, y - offy / sy - 20
        if _input:isRecordedMousePressed() then
            RenderTTF("font:menu", "mouse pressed (recorded)", x, x, y, y, comment_color, "left")
        else
            RenderTTF("font:menu", "mouse (recorded)", x, x, y, y, comment_color, "left")
        end
    end
end

function M.drawHudBackground(img_background, background_scale)
    Render(img_background, 320, 240, 0, background_scale, background_scale)
end

return M