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

---使用RenderText渲染分数
---@param font_name string
---@param score number
---@param x number
---@param y number
---@param size number
---@param align string
local function DisplayScore(font_name, score, x, y, size, align)
    local format_str = "%d"
    local three_digits = {}
    if score >= 100000000000 then
        format_str = "99,999,999,999"
    else
        local i = 1
        while score >= 1000 do
            local cur_section = int(score % 1000)
            three_digits[i] = cur_section
            score = math.floor(score / 1000)
            i = i + 1
            format_str = format_str..",%03d"
        end
        three_digits[i] = int(score % 1000)
        -- reverse the array
        for j = 1, math.floor(i / 2) do
            local k = i + 1 - j
            local temp = three_digits[k]
            three_digits[k] = three_digits[j]
            three_digits[j] = temp
        end
    end
    RenderText(font_name, string.format(format_str, unpack(three_digits)), x, y, size, align)
end

---@param stage Stage
---@param font_name string
function M:drawScore(stage, font_name)
    DisplayScore(
            font_name,
            stage:getScore(),
            622,
            414,
            0.43,
            "right")
end

function M:drawPlayfieldOutlineWithBackground(img_background, background_scale, img_border)
    scr.setRenderView("ui")

    _timer = _timer + 1

    -- render the hud background
    M:drawHudBackground(img_background, background_scale)

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
            Render("image:button_pressed", x, y, 0, 1, 1)
        else
            Render("image:button_normal", x, y, 0, 1, 1)
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
            Render("image:button_pressed", x, y, 0, 1, 1)
        else
            Render("image:button_normal", x, y, 0, 1, 1)
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
    Render(img_background, 320, 240, 0, background_scale, background_scale)
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
local function DisplayResource(
        resource_image,
        resource_image_outline,
        x,
        y,
        dx,
        dy,
        num_resource,
        max_display_num)
    for i = 1, max_display_num do
        local cur_x, cur_y = x + dx * i, y + dy * i
        Render(resource_image_outline, cur_x, cur_y, 0, 1, 1)
        if num_resource >= i then
            Render(resource_image, cur_x, cur_y, 0, 1, 1)
        end
    end
end

---@param player Prefab.Player
---@param font_name string
function M:drawPlayerResources(player, font_name)
    local base_x = 520
    local base_y = 344
    local dx = 13
    local dy = 0

    local num_life, num_bomb, num_graze = player:getPlayerResources()
    local max_display_num = 8
    DisplayResource(
            "image:icon_life",
            "image:icon_life_outline",
            base_x,
            base_y,
            dx,
            dy,
            num_life,
            max_display_num)
    DisplayResource(
            "image:icon_bomb",
            "image:icon_bomb_outline",
            base_x,
            base_y - 48,
            dx,
            dy,
            num_bomb,
            max_display_num)
    RenderText(
            font_name,
            tostring(num_graze),
            636,
            262,
            0.4,
            "right")
end

return M