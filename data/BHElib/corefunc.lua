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

    local platform_info = require("platform.platform_info")
    if platform_info.isMobile() then
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