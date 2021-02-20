-----------------------------------------------------------------------------------
---hud.lua
---desc: Implementation of stg HUD rendering
---modifier:
---     Karl, 2021.2.18, split from after_load.lua
-----------------------------------------------------------------------------------

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

    RenderText(font_display, str, 630, 50, 0.5, 'right', 'bottom')
    --]]
    str = string.format('%.1f fps', fps)
    str = string.format('obj:%d\n', GetnObj()) .. str

    RenderText(font_display, str, 630, 0, 1, 'right', 'bottom')
end

---------------------------------------------------------------------------------------------------

function M.draw(img_background, background_scale, font_profile_text, img_border)
    scr.setRenderView("ui")
    SetFontState(font_profile_text, '', Color(0xFFFFFFFF))

    _timer = _timer + 1

    -- render the hud background
    Render(img_background, 320, 240, 0, background_scale, background_scale)

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

return M