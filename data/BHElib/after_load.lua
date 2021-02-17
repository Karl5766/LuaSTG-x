---------------------------------------------------------------------------------------------------
---after_load.lua
---date: 2021.2.17
---desc:
---modifier:
---     Karl, 2021.2.17, moved profiling code up
---------------------------------------------------------------------------------------------------

local function loadModules()
    require('BHElib.ui.menu_task')
    require('BHElib.ui.arrange_string')
    require('BHElib.ui.stage_ui')
end
loadModules()

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

local function RenderPerformanceProfile()
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

    RenderText('menu', str, 630, 50, 0.25, 'right', 'bottom')
    --]]
    str = string.format('%.1f fps', fps)
    str = string.format('obj:%d\n', GetnObj()) .. str

    RenderText('menu', str, 630, 0, 0.5, 'right', 'bottom')
end

---------------------------------------------------------------------------------------------------

function ui.DrawFrame()
    lstg.eventDispatcher:dispatchEvent('ui.DrawFrame')

    SetViewMode('ui')
    SetFontState('menu', '', Color(0xFFFFFFFF))

    _timer = _timer + 1

    -- render the hud background
    Render('stage_bg', 320, 240, 0, 0.5)

    -- render a thin rectangular border
    SetImageState('white', '', color.Red)
    local w = lstg.world
    local l, r, b, t = w.scrl, w.scrr, w.scrb, w.scrt

    local sz = FindResSprite('white'):getSprite():getContentSize()
    local ww, hh = sz.width, sz.height
    Render('white', (l + r) / 2, t, 0, (r - l + 1) / ww, 2 / hh)
    Render('white', (l + r) / 2, b, 0, (r - l + 1) / ww, 2 / hh)
    Render('white', l, (t + b) / 2, 0, 2 / ww, (t - b + 1) / hh)
    Render('white', r, (t + b) / 2, 0, 2 / ww, (t - b + 1) / hh)
    SetImageState('white', '', color.White)

    RenderPerformanceProfile()
end

---------------------------------------------------------------------------------------------------