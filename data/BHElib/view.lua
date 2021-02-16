---------------------------------------------------------------------------------------------------
---view.lua
---date: 2021.2.15
---desc: Defines 3 view modes: "3d", "world", "ui", and provides interfaces to switch among them
---modifier:
---     Karl, 2021.2.14, re-formatted the file and modified some comments
---------------------------------------------------------------------------------------------------
---view3d

lstg.view3d = {
    eye  = { 0, 0, -1 },                -- camera position
    at   = { 0, 0, 0 },                 -- camera target position
    up   = { 0, 1, 0 },                 -- camera up, used for determining the orientation of the camera
    fovy = PI_2,                        -- controls size of spherical view field in vertical direction (in radians)
    z    = { 0, 2 },                    -- clipping plane, {near, far}
    fog  = { 0, 0, Color(0x00000000) }  -- fog param, {start, end, color}
}

---重置lstg.view3d的值
function Reset3D()
    lstg.view3d.eye = { 0, 0, -1 }
    lstg.view3d.at = { 0, 0, 0 }
    lstg.view3d.up = { 0, 1, 0 }
    lstg.view3d.fovy = PI_2
    lstg.view3d.z = { 1, 2 }
    lstg.view3d.fog = { 0, 0, Color(0x00000000) }
end

---设置lstg.view3d的值
function Set3D(key, a, b, c)
    if key == 'fog' then
        a = tonumber(a or 0)
        b = tonumber(b or 0)
        lstg.view3d.fog = { a, b, c }
        return
    end
    a = tonumber(a or 0)
    b = tonumber(b or 0)
    c = tonumber(c or 0)
    if key == 'eye' then
        lstg.view3d.eye = { a, b, c }
    elseif key == 'at' then
        lstg.view3d.at = { a, b, c }
    elseif key == 'up' then
        lstg.view3d.up = { a, b, c }
    elseif key == 'fovy' then
        lstg.view3d.fovy = a
    elseif key == 'z' then
        lstg.view3d.z = { a, b }
    end
end

---@param x number x in 3d coordinates
---@param y number y in 3d coordinates
---@param z number z in 3d coordinates
---@return number, number
function _3DToWorld(x, y, z)
    local view3d = lstg.view3d
    local m1 = math.Mat4:createPerspective(
            view3d.fovy,
            -(_world.r - _world.l) / (_world.t - _world.b),
            view3d.z[1], view3d.z[2])
    local eye = math.Vec3(view3d.eye[1], view3d.eye[2], view3d.eye[3])
    local target = math.Vec3(view3d.at[1], view3d.at[2], view3d.at[3])
    local up = math.Vec3(view3d.up[1], view3d.up[2], view3d.up[3])
    local m2 = math.Mat4:createLookAt(eye, target, up)
    local m = m1 * m2
    local v = m:transformVector(x, y, z, 1)
    local xx, yy, zz, ww = v.x, v.y, v.z, v.w
    xx = xx / ww
    yy = yy / ww
    xx = (xx + 1) * 0.5 * (_world.scrr - _world.scrl)
    yy = (yy + 1) * 0.5 * (_world.scrt - _world.scrb)
    return xx + _world.l, yy + _world.b
end

lstg.scale_3d = 0.007 * screen.scale

---------------------------------------------------------------------------------------------------
---set the metatable of global lstg.world

local _world
local _world_dirty = true

local mt_world = {
    __index    = function(t, k)
        return _world[k]
    end,
    __newindex = function(t, k, v)
        _world[k] = v
        _world_dirty = true
    end
}

local function SetWorldMetatable()
    _world = lstg.world
    lstg.world = setmetatable({}, mt_world)
end
SetWorldMetatable()

local _last_world = lstg.world

---------------------------------------------------------------------------------------------------
---view parameters

local scale  -- the value of ui_vp divided by ui_or
local ui_vp_l, ui_vp_r, ui_vp_b, ui_vp_t  -- rect of the whole window
local ui_or_l, ui_or_r, ui_or_b, ui_or_t  -- rect of the whole window after divied by scale, for SetOrtho
local world_vp_l, world_vp_r, world_vp_b, world_vp_t  -- world (play field) projected to the window coordinates
local world_or_l, world_or_r, world_or_b, world_or_t  -- world (play field) in play field coordinates, for SetOrtho

---print information about local variables to log file
local function WriteToLog()
    local fmt = '%.1f, %.1f, %.1f, %.1f'
    local ui_vp = string.format(fmt, ui_vp_l, ui_vp_r, ui_vp_b, ui_vp_t)
    local ui_or = string.format(fmt, ui_or_l, ui_or_r, ui_or_b, ui_or_t)
    local world_vp = string.format(fmt, world_vp_l, world_vp_r, world_vp_b, world_vp_t)
    local world_or = string.format(fmt, world_or_l, world_or_r, world_or_b, world_or_t)
    local t = {
        ui_vp        = ui_vp, ui_or = ui_or,
        world_vp     = world_vp, world_or = world_or,
        screen_scale = screen.scale
    }
    SystemLog('view params:\n' .. stringify(t))
end

---initialize/reset local variables according to values in global setting and screen tables
local function LoadViewParams()
    local screen = screen
    local setting = setting

    scale = screen.scale

    ui_vp_l = 0
    ui_vp_r = setting.resx
    ui_vp_b = 0
    ui_vp_t = setting.resy
    ui_or_l = -screen.dx
    ui_or_r = (setting.resx / scale - screen.dx)
    ui_or_b = -screen.dy
    ui_or_t = (setting.resy / scale - screen.dy)

    world_vp_l = (_world.scrl + screen.dx) * scale
    world_vp_r = (_world.scrr + screen.dx) * scale
    world_vp_b = (_world.scrb + screen.dy) * scale
    world_vp_t = (_world.scrt + screen.dy) * scale
    world_or_l = _world.l
    world_or_r = _world.r
    world_or_b = _world.b
    world_or_t = _world.t

    _world_dirty = false
    --local x0,y0=WorldToScreen(0,0)
    --local x1,y1=WorldToScreen(1,1)
    --SystemLog(string.format('WorldToScreen: %f, %f, %f, %f',x0,y0,x1,y1))
    WriteToLog()

    local check = world_or_l ~= world_or_r
    check = check and world_or_b ~= world_or_t
    if not check then
        error('error in loadViewParams')
    end
end
LoadViewParams()

---------------------------------------------------------------------------------------------------

local sqrt = math.sqrt
local tan = math.tan

--- 强行设置视角模式，分别对应坐标系
--- 'world': lstg.world
--- 'ui': screen
--- '3d': lstg.view3d
---@param mode string specifies the mode to set; can be 'world', 'ui', or '3d'
function ForceSetViewMode(mode)
    lstg.viewmode = mode
    if mode == '3d' then
        local view3d = lstg.view3d
        local cur_world = lstg.world
        SetViewport(
                world_vp_l, world_vp_r, world_vp_b, world_vp_t)
        SetPerspective(
                view3d.eye[1], view3d.eye[2], view3d.eye[3],
                view3d.at[1], view3d.at[2], view3d.at[3],
                view3d.up[1], view3d.up[2], view3d.up[3],
                view3d.fovy,
                (cur_world.r - cur_world.l) / (cur_world.t - cur_world.b),
                view3d.z[1], view3d.z[2])

        SetFog(view3d.fog[1], view3d.fog[2], view3d.fog[3])

        local dx, dy, dz = view3d.eye[1] - view3d.at[1], view3d.eye[2] - view3d.at[2], view3d.eye[3] - view3d.at[3]
        SetImageScale(
                sqrt(dx * dx + dy * dy + dz * dz) * 2
                        * tan(view3d.fovy * 0.5)
                        / (cur_world.scrr - cur_world.scrl))

    elseif mode == 'world' then
        SetViewport(
                world_vp_l, world_vp_r, world_vp_b, world_vp_t)
        SetOrtho(
                world_or_l, world_or_r, world_or_b, world_or_t)
        SetFog()
        --SetImageScale((world.r-world.l)/(world.scrr-world.scrl))--usually it is 1
        SetImageScale(1)

    elseif mode == 'ui' then
        SetViewport(
                ui_vp_l, ui_vp_r, ui_vp_b, ui_vp_t)
        SetOrtho(
                ui_or_l, ui_or_r, ui_or_b, ui_or_t)
        SetFog()
        SetImageScale(1)

    else
        error(i18n 'Invalid arguement for SetViewMode')
    end
end

--- 设置视角模式，分别对应坐标系
--- 'world': lstg.world
--- 'ui': screen
--- '3d': lstg.view3d
---@param mode string specifies the mode to set; can be 'world', 'ui', or '3d'
function SetViewMode(mode)
    if lstg.world ~= _last_world then
        _last_world = lstg.world
        SetWorldMetatable()
        LoadViewParams()
    elseif _world_dirty then
        LoadViewParams()
    elseif lstg.viewmode == mode then
        return
    end
    ForceSetViewMode(mode)
end

---turn the metrics of a view into a string for output
---@param mode string the view mode to output information about
---@return string human-readable info of the view
function GetViewModeInfo(mode)
    local ret = ''
    if mode == '3d' then
        local view3d = lstg.view3d
        local vp = string.format(
                'vp: (%.1f, %.1f, %.1f, %.1f)',
                world_vp_l, world_vp_r, world_vp_b, world_vp_t)
        local eye = string.format(
                'eye: (%.1f, %.1f, %.1f)',
                view3d.eye[1], view3d.eye[2], view3d.eye[3])
        local at = string.format(
                'at: (%.1f, %.1f, %.1f)',
                view3d.at[1], view3d.at[2], view3d.at[3])
        local up = string.format(
                'up: (%.1f, %.1f, %.1f)',
                view3d.up[1], view3d.up[2], view3d.up[3])
        local others = string.format(
                'fovy: %.2f z: (%.1f, %.1f)',
                view3d.fovy, view3d.z[1], view3d.z[2])
        ret = string.format(
                '%s\n%s\n%s\n%s\n%s',
                vp, eye, at, up, others)
    elseif mode == 'world' then
        local vp = string.format(
                'vp: (%.1f, %.1f, %.1f, %.1f)',
                world_vp_l, world_vp_r, world_vp_b, world_vp_t)
        local or_ = string.format(
                'or: (%.1f, %.1f, %.1f, %.1f)',
                world_or_l, world_or_r, world_or_b, world_or_t)
        ret = string.format(
                '%s\n%s',
                vp, or_)
    elseif mode == 'ui' then
        local vp = string.format(
                'vp: (%.1f, %.1f, %.1f, %.1f)',
                ui_vp_l, ui_vp_r, ui_vp_b, ui_vp_t)
        local or_ = string.format(
                'or: (%.1f, %.1f, %.1f, %.1f)',
                ui_or_l, ui_or_r, ui_or_b, ui_or_t)
        ret = string.format(
                '%s\n%s',
                vp, or_)
    end
    return ret
end