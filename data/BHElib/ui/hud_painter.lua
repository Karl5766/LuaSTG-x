---------------------------------------------------------------------------------------------------
---hud.lua
---desc: Implementation of stg HUD rendering
---references: -x/src/game/stage_ui.lua -x/src/game/after_load.lua THlib/ui/ui.lua
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

function M:drawPlayfieldOutline(img_border)
    scr.setRenderView("ui")

    _timer = _timer + 1

    -- render a thin rectangular border
    SetImageState(img_border, '', color.Red)
    local l, r, b, t = scr.getPlayfieldBoundaryInUI()

    local sprite_size = FindResSprite(img_border):getSprite():getContentSize()
    local ww, hh = sprite_size.width, sprite_size.height
    AlignedRender(img_border, (l + r) / 2, t, (r - l + 1) / ww, 2 / hh)
    AlignedRender(img_border, (l + r) / 2, b, (r - l + 1) / ww, 2 / hh)
    AlignedRender(img_border, l, (t + b) / 2, 2 / ww, (t - b + 1) / hh)
    AlignedRender(img_border, r, (t + b) / 2, 2 / ww, (t - b + 1) / hh)
    SetImageState(img_border, '', color.White)
end

function M:drawPerfromanceProfile(font_profile)
    SetFontState(font_profile, '', Color(0xFFFFFFFF))
    RenderPerformanceProfile(font_profile)
end

local _input = require("BHElib.input.input_and_recording")
local _coordinates = require("BHElib.coordinates_and_screen")

function M:drawKeys()
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
    local normal_pos = {-40, 100}
    local replay_pos = {-40, 240}
    local text_color = Color(255, 60, 60, 60)
    local comment_color = Color(255, 255, 255, 255)

    for i = 1, 4 do
        -- draw keys at the position
        local offset = offsets[i]
        local key_name = function_keys[i]
        local x, y = offset[1] + normal_pos[1], offset[2] + normal_pos[2]
        if _input:isAnyDeviceKeyDown(key_name) then
            AlignedRender("image:button_pressed", x, y)
        else
            AlignedRender("image:button_normal", x, y)
        end
        local text_y = y + 14
        RenderTTF("font:test", key_name, x, x, text_y, text_y, text_color, "center")
    end
    do
        local x, text_y = normal_pos[1] + distance, normal_pos[2] - distance * 0.5
        RenderTTF("font:test", "device input", x, x, text_y, text_y, comment_color, "center")
    end

    for i = 1, 4 do
        -- draw keys at the position
        local offset = offsets[i]
        local key_name = function_keys[i]
        local x, y = offset[1] + replay_pos[1], offset[2] + replay_pos[2]
        if _input:isAnyRecordedKeyDown(key_name) then
            AlignedRender("image:button_pressed", x, y)
        else
            AlignedRender("image:button_normal", x, y)
        end
        local color = Color(255, 60, 60, 60)
        local text_y = y + 14
        RenderTTF("font:test", key_name, x, x, text_y, text_y, text_color, "center")
    end
    do
        local x, text_y = replay_pos[1] + distance, replay_pos[2] - distance * 0.5
        RenderTTF("font:test", "recorded input", x, x, text_y, text_y, comment_color, "center")
    end

    --mouse text
    do
        local x, y = _input:getMousePositionInUI()
        if _input:isMousePressed() then
            RenderTTF("font:test", "mouse pressed", x, x, y, y, comment_color, "left")
        else
            RenderTTF("font:test", "mouse", x, x, y, y, comment_color, "left")
        end
    end
    do
        local x, y = _input:getRecordedMousePositionInUI()
        y = y - 20
        if _input:isRecordedMousePressed() then
            RenderTTF("font:test", "mouse pressed (recorded)", x, x, y, y, comment_color, "left")
        else
            RenderTTF("font:test", "mouse (recorded)", x, x, y, y, comment_color, "left")
        end
    end
end

function M:drawHudBackground(img_background, background_scale)
    AlignedRender(img_background, 320, 240, background_scale, background_scale)
end

---------------------------------------------------------------------------------------------------
---player resources

---each image will be displayed with rot = 0 and hscale, vscale = 1, 1
---@param resource_image string
---@param resource_image_outline string
---@param x number x coordinate position of first displayed image
---@param y number y coordinate position of first displayed image
---@param dx number x offset for each image afterwards
---@param dy number y offset for each image afterwards
---@param num_resource number
---@param max_display_num number maximum number of images that can be displayed
---@param scale number scale of the images
local function DisplayResource(
        resource_image,
        resource_image_outline,
        x,
        y,
        dx,
        dy,
        num_resource,
        max_display_num,
        scale)
    for i = 1, max_display_num do
        local cur_x, cur_y = x + dx * i, y + dy * i
        AlignedRender(resource_image_outline, cur_x, cur_y, scale)
        if num_resource >= i then
            AlignedRender(resource_image, cur_x, cur_y, scale)
        end
    end
end

---add commas every three digits to separators large numbers
---@param integer number a non-negative integer
---@return string the number in string representation after adding separators
local function AddThousandSeparator(integer)
    local format_str = "%d"
    local three_digits = {}
    if integer >= 100000000000 then
        format_str = "99,999,999,999"
    else
        local i = 1
        while integer >= 1000 do
            local cur_section = int(integer % 1000)
            three_digits[i] = cur_section
            integer = math.floor(integer / 1000)
            i = i + 1
            format_str = format_str..",%03d"
        end
        three_digits[i] = int(integer % 1000)
        -- reverse the array
        for j = 1, math.floor(i / 2) do
            local k = i + 1 - j
            local temp = three_digits[k]
            three_digits[k] = three_digits[j]
            three_digits[j] = temp
        end
    end
    return string.format(format_str, unpack(three_digits))
end

---separate n% to its integer part and decimal part
---@param n number a non-negative integer
---@return string, string string representations of their integer and decimal parts
local function GetPercentRepresentation(n)
    local int_repr = tostring(int(n / 100))
    local mant_repr = tostring(int(n % 100))  -- mantissa
    if #mant_repr == 1 then
        mant_repr = "0"..mant_repr
    end
    return int_repr, mant_repr
end

---display num%/max_num%
---@param num number
local function DisplayPercent(num, x, y)
    local num_i, num_m = GetPercentRepresentation(num)

    local font_name = "font:test"

    -- render different sized fonts
    RenderText(font_name,
            string.format(" %s.", num_i),
            x - 16, y, 0.4, "right")
    RenderText(font_name,
            string.format("        %s", num_m),
            x, y - 3.5, 0.3, "right")
end

---@param stage Stage
---@param font_name string
function M:drawResources(stage, font_name)
    -- left and right boundaries
    local left_x = 515
    local right_x = 720
    local middle_x = 620  -- where the lines are centered

    local base_y = 434  -- base y position
    local relative_y = base_y  -- descend this number as drawing goes on from top to bottom

    local dx = 13
    local dy = 0
    local player = stage:getPlayer()

    local player_resource = player:getPlayerResource()
    local max_display_num = 8

    AlignedRender("image:icon_normal_title", middle_x, relative_y, 0.7)

    relative_y = relative_y - 40

    AlignedRender("image:icon_hiscore_title", left_x, relative_y, 1.05)
    RenderText(font_name,
            AddThousandSeparator(stage:getScore()),
            right_x,
            relative_y,
            0.43,
            "right")
    AlignedRender("image_array:icon_line1", middle_x, relative_y - 20, 1.05)

    relative_y = relative_y - 40

    AlignedRender("image:icon_score_title", left_x, relative_y, 1.05)
    RenderText(font_name,
            AddThousandSeparator(stage:getScore()),
            right_x,
            relative_y,
            0.43,
            "right")
    AlignedRender("image_array:icon_line2", middle_x, relative_y - 20, 1.05)

    relative_y = relative_y - 45

    AlignedRender("image:icon_life_title", left_x, relative_y, 1)
    DisplayResource(
            "image:icon_life",
            "image:icon_life_outline",
            left_x + 90,
            relative_y - 4,
            dx,
            dy,
            player_resource.num_life,
            max_display_num,
            1.1)
    AlignedRender("image_array:icon_line3", middle_x, relative_y - 20, 1.05)

    relative_y = relative_y - 36

    AlignedRender("image:icon_bomb_title", left_x, relative_y, 1.05)
    DisplayResource(
            "image:icon_bomb",
            "image:icon_bomb_outline",
            left_x + 90,
            relative_y - 4,
            dx,
            dy,
            player_resource.num_bomb,
            max_display_num,
            1.1)
    AlignedRender("image_array:icon_line4", middle_x, relative_y - 20, 1.05)

    relative_y = relative_y - 50

    AlignedRender("image:icon_power_title", left_x + 2, relative_y - 5, 0.85)
    DisplayPercent(player_resource.num_power, right_x, relative_y)
    AlignedRender("image_array:icon_line5", middle_x, relative_y - 20, 1.05)

    relative_y = relative_y - 30

    AlignedRender("image:icon_graze_title", left_x + 27, relative_y - 5, 0.85)
    RenderText(
            font_name,
            tostring(player_resource.num_graze),
            right_x,
            relative_y,
            0.4,
            "right")
    AlignedRender("image_array:icon_line7", middle_x, relative_y - 20, 1.05)
end

return M