---------------------------------------------------------------------------------------------------
---corefunc.lua
---desc: Defines core functions, which includes the game update and render functions.
---modifier:
---     Karl, 2021.2.12 replaced stage switching and stage group
---     related code
---------------------------------------------------------------------------------------------------

local profiler = profiler
local e = lstg.eventDispatcher
local coordinates = require("BHElib.coordinates_and_screen")

local abs = abs
local cos = cos
local sin = sin
local hypot = hypot
local pairs = pairs
local rawget = rawget

local ot = ObjTable()

---------------------------------------------------------------------------------------------------

function UserSystemOperation()
    --assistance of Polar coordinate system
    local polar--, radius, angle, delta, omiga, center
    --acceleration and gravity
    local alist--, accelx, accely, gravity
    --limitation of velocity
    local forbid--, vx, vy, v, ovx, ovy, cache
    --
    for i = 1, 32768 do
        local obj = ot[i]
        if obj then
            polar = rawget(obj, 'polar')
            if polar then
                local radius = polar.radius or 0
                local angle = polar.angle or 0
                local delta = polar.delta
                if delta then
                    polar.radius = radius + delta
                end
                local omiga = polar.omiga
                if omiga then
                    polar.angle = angle + omiga
                end
                local center = polar.center or { x = 0, y = 0 }
                radius = polar.radius
                angle = polar.angle
                obj.x = center.x + radius * cos(angle)
                obj.y = center.y + radius * sin(angle)
            end
            alist = rawget(obj, 'acceleration')
            if alist then
                local accelx = alist.ax
                if accelx then
                    obj.vx = obj.vx + accelx
                end
                local accely = alist.ay
                if accely then
                    obj.vy = obj.vy + accely
                end
                local gravity = alist.g
                if gravity then
                    obj.vy = obj.vy - gravity
                end
            end
            forbid = rawget(obj, 'forbidveloc')
            if forbid then
                local ovx = obj.vx
                local ovy = obj.vy
                local v = forbid.v
                if v and (v * v) < (ovx * ovx + ovy * ovy) then
                    local cache = v / hypot(ovx, ovy)
                    obj.vx = cache * ovx
                    obj.vy = cache * ovy
                    ovx = obj.vx
                    ovy = obj.vy
                end
                local vx = forbid.vx
                local vy = forbid.vy
                if vx and vx < abs(ovx) then
                    obj.vx = vx
                end
                if vy and vy < abs(ovy) then
                    obj.vy = vy
                end
            end
        end
    end
end

---------------------------------------------------------------------------------------------------

---update game state 1 time
local function _DoOneFrame()
    --SetTitle(setting.mod .. ' | FPS=' .. GetFPS() .. ' | Nobj=' .. GetnObj())
    UpdateObjList()
    GetInput()

    profiler.tic('ObjFrame')
    ObjFrame()--LPOOL.DoFrame() 执行对象的Frame函数
    profiler.toc('ObjFrame')

    -- update current stage group
    local stage_group = StageGroup.getRunningInstance()
    stage_group:update(1)

    profiler.tic('UserSystemOperation')
    UserSystemOperation()  --用于lua层模拟内核级操作
    profiler.toc('UserSystemOperation')

    BoundCheck()--执行边界检查

    profiler.tic('CollisionCheck')
    --碰撞检查
    CollisionCheck(GROUP_PLAYER, GROUP_ENEMY_BULLET)
    CollisionCheck(GROUP_PLAYER, GROUP_ENEMY)
    CollisionCheck(GROUP_PLAYER, GROUP_INDES)
    CollisionCheck(GROUP_ENEMY, GROUP_PLAYER_BULLET)
    CollisionCheck(GROUP_NONTJT, GROUP_PLAYER_BULLET)
    CollisionCheck(GROUP_ITEM, GROUP_PLAYER)
    profiler.toc('CollisionCheck')

    profiler.tic('UpdateXY')
    UpdateXY()--更新对象的XY坐标偏移量
    profiler.toc('UpdateXY')

    profiler.tic('AfterFrame')
    AfterFrame()--帧末更新函数
    profiler.toc('AfterFrame')

    -- test whether to start the next stage
    if stage_group:readyForNextStage() then
        stage_group:goToNextStage()
    end
end

---update game state k times, k depending on the value given by
---setting.render_skip + 1
function DoFrames()
    local factor = 1
    if setting.render_skip then
        factor = int(setting.render_skip) + 1
    end
    for _ = 1, factor do
        _DoOneFrame()
    end
end

---------------------------------------------------------------------------------------------------

local _process_one_task = async.processOneTask

---@~chinese 将被每帧调用以执行帧逻辑。返回`true`时会使游戏退出。
---
---@~english Will be invoked every frame to process all frame logic. Game will exit if it returns `true`.
---
function FrameFunc()
    -- -1
    if GetLastKey() == setting.keysys.snapshot and setting.allowsnapshot then
        Screenshot()
    end
    _process_one_task()

    -- 0
    e:dispatchEvent('onFrameFunc')  -- in case any event is registered
    DoFrames()  -- update the game

    -- 9
    if lstg.quit_flag then
        GameExit()
    end
    return lstg.quit_flag
end

---------------------------------------------------------------------------------------------------

---@~chinese 将被每帧调用以执行渲染指令。
---
---@~english Will be invoked every frame to process all render instructions.
---
function RenderFunc()
    local stage_group = StageGroup.getRunningInstance()
    if stage_group:readyForRender() then

        -- begin scene
        BeginScene()

        -- before render calls
        coordinates.setRenderView("ui")
        e:dispatchEvent('onBeforeRender')

        -- render calls
        stage_group:render()

        coordinates.setRenderView("game")
        profiler.tic('ObjRender')
        ObjRender()
        profiler.toc('ObjRender')

        -- after render calls
        e:dispatchEvent('onAfterRender')

        -- end scene
        e:dispatchEvent('beforeEndScene')
        EndScene()
        e:dispatchEvent('afterEndScene')

        ProcessCapturedScreens()
    end
end

---------------------------------------------------------------------------------------------------
---misc

---@~chinese 将在窗口失去焦点时调用。
---
---@~english Will be invoked when the window lose focus.
---
function FocusLoseFunc()
    e:dispatchEvent('onFocusLose')
end

---@~chinese 将在窗口重新获得焦点时调用。
---
---@~english Will be invoked when the window get focus.
---
function FocusGainFunc()
    e:dispatchEvent('onFocusGain')
end

---@~chinese 将在引擎初始化结束后调用。
---
---@~english Will be invoked after the initialization of engine finished.
---
function GameInit()
    SetViewMode 'ui'
    if stage.next_stage == nil then
        error(i18n 'Entrance stage not set')
    end
    SetResourceStatus 'stage'
end

local Director = cc.Director:getInstance()
function GameExit()
    print('GameExit')
    --require('jit.p').stop()
    require("setting.setting_util").saveSettingFile()
    print('FrameEnd')
    lstg.FrameEnd()
    print('FrameEnd finish')
    if plus and plus.isMobile() then
        Director:endToLua()
    else
        os.exit()
    end
end

function DrawCollider()
    local x, y = 0, 0
    DrawGroupCollider(GROUP_ENEMY_BULLET, Color(150, 163, 73, 164), x, y)
    DrawGroupCollider(GROUP_ENEMY, Color(150, 163, 73, 164), x, y)
    DrawGroupCollider(GROUP_INDES, Color(150, 163, 73, 20), x, y)
    DrawGroupCollider(GROUP_PLAYER, Color(100, 175, 15, 20), x, y)

    --DrawGroupCollider(GROUP_ITEM, Color(100, 175, 175, 175), x, y)
end

local show_collider = false

e:addListener('beforeEndScene', function()
    if KeyIsPressed('toggle_collider') then
        show_collider = not show_collider
    end
    if show_collider then
        DrawCollider()
    end
    coordinates.setRenderView("game")
end, 9)

function BentLaserData()
    return lstg.GameObjectBentLaser:create()
end

---------------------------------------------------------------------------------------------------