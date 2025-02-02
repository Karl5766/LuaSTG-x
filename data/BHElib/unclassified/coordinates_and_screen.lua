---------------------------------------------------------------------------------------------------
---coordinates_and_screen.lua
---date: 2021.2.16
---references: -x/src/core/view.lua, -x/src/core/screen.lua
---desc: Defines view modes, coordinates and their conversion functions
---------------------------------------------------------------------------------------------------
---coordinates (views)
---defines a few coordinate systems in respect to the screen resolution; each coordinate system is
---composed of an origin and two "rulers" that measures length in x and y directions; the unit of
---length of each system may not be the same; the rulers are always aligned with x and y axis
---each coordinates besides "res" is expressed in terms of another coordinates, meaning the position
---of the origin and the relative scale of the coordinates are calculated based on the other coordinate
---system when they are needed

---@class Coordinates
local M = {}

-- implicitly, all other coordinates take screen resolution coordinate "res" as the standard coordinates
-- the origin (0, 0) of "res" is at bottom left of the screen. Its units of x and y axis are in pixels

---"game": coordinates of the gameplay area
---this is a duplicated item, should be updated together
local _game_ui_x, _game_ui_y, _game_ui_x_unit, _game_ui_y_unit                      -- expressed in "ui" coordinates
local _game_x, _game_y, _game_x_unit, _game_y_unit                                  -- expressed in "res" coordinates
---"ui": coordinates of the hud
local _ui_x, _ui_y, _ui_x_unit, _ui_y_unit                                          -- expressed in "res" coordinates

---"3d": camera of the 3d background
---@type View3d
local _view3d

---dirty bit for setRenderView
local _dirty = true  -- true if viewport or ortho has changed after the last setRenderView call
local _current_render_view

---------------------------------------------------------------------------------------------------
---some rectangular areas

-- play field boundary
local _playfield_game_l, _playfield_game_r, _playfield_game_b, _playfield_game_t    -- expressed in "game" coordinates

-- out of bound deletion
local _bound_game_l, _bound_game_r, _bound_game_b, _bound_game_t                    -- expressed in "game" coordinates

-- 4:3 hud (not precisely the display area) expressed in units of the "ui" coordinate
local _hud_ui_width, _hud_ui_height = 640, 480

---------------------------------------------------------------------------------------------------
---cache functions

local pairs = pairs
local GetResolution  -- will be defined in the following code
local SetFog

---------------------------------------------------------------------------------------------------
---view conversions

---convert a point in "game" coordinates to a point in "ui" coordinates
---replay-compatible
---@param x number x coordinate in "game"
---@param y number y coordinate in "game"
---@return number, number x, y coordinates in "ui"
function M.gameToUI(x, y)
    x = x * _game_ui_x_unit + _game_ui_x
    y = y * _game_ui_y_unit + _game_ui_y
    return x, y
end
local GameToUI = M.gameToUI

---convert a point in "ui" coordinates to a point in "game" coordinates
---replay-compatible
---@param x number x coordinate in "ui"
---@param y number y coordinate in "ui"
---@return number, number x, y coordinates in "game"
function M.uiToGame(x, y)
    x = (x - _game_ui_x) / _game_ui_x_unit
    y = (y - _game_ui_y) / _game_ui_y_unit
    return x, y
end

---convert a point in "game" coordinates to a point in "res" coordinates
---@param x number x coordinate in "game"
---@param y number y coordinate in "game"
---@return number, number x, y coordinates in "res"
function M.gameToRes(x, y)
    x = x * _game_x_unit + _game_x
    y = y * _game_y_unit + _game_y
    return x, y
end
local GameToRes = M.gameToRes

---convert a point in "ui" coordinates to a point in "res" coordinates
---@param x number x coordinate in "ui"
---@param y number y coordinate in "ui"
---@return number, number x, y coordinates in "res"
function M.uiToRes(x, y)
    x = x * _ui_x_unit + _ui_x
    y = y * _ui_y_unit + _ui_y
    return x, y
end

---convert a point in "res" coordinates to a point in "ui" coordinates
---@param x number x coordinate in "res"
---@param y number y coordinate in "res"
---@return number, number x, y coordinates in "ui"
function M.resToUI(x, y)
    x = (x - _ui_x) / _ui_x_unit
    y = (y - _ui_y) / _ui_y_unit
    return x, y
end
local ResToUI = M.resToUI

---------------------------------------------------------------------------------------------------
---setters and getters

local _glv = cc.Director:getInstance():getOpenGLView()
local _scr_metrics = require("setting.screen_metrics")

---return the current resolution of the screen
---@return number, number current resolution width, height
function M.getResolution()
    return _scr_metrics.getScreenResolution()
end
GetResolution = M.getResolution

---initialize view3d
---@param view3d View3d specifies the initial parameters for 3d camera
function M.initView3d(view3d)
    _view3d = view3d
end

---@return View3d the 3d camera parameters
function M.getView3d()
    return _view3d
end

---modify screen resolution by setting the design resolution of GLView
---update "game" and "ui" coordinates since the they depend on the resolution
---@param res_width number screen resolution width
---@param res_height number screen resolution height
function M.setResolution(res_width, res_height)
    _scr_metrics.setScreenResolution(res_width, res_height, _glv)

    M.setUICoordinatesByResolution(_hud_ui_width, _hud_ui_height, res_width, res_height)
    M.setGameCoordinatesInUI(_game_ui_x, _game_ui_y, _game_ui_x_unit, _game_ui_y_unit)
end

---save the screen resolution to setting table, so it will be written to disk on
---the termination of the application.
---@param res_width number resolution width, setting to be saved
---@param res_height number resolution height, setting to be saved
function M.rememberResolution(res_width, res_height)
    _scr_metrics.rememberScreenResolution(res_width, res_height)
end

---@return number, number the origin of "ui" coordinates expressed in "res" coordinates
function M.getUIOriginInRes()
    return _ui_x, _ui_y
end

function M.getScreenCenterInUI()
    local w, h = GetResolution()
    return (w * 0.5 - _ui_x) / _ui_x_unit, (h * 0.5 - _ui_y) / _ui_y_unit
end

---return the scale of game coordinates in respect to the resolution
---@return number, number the scaling factors in x, y direction (in pixel)
function M.getGameScale()
    return _game_x_unit, _game_y_unit
end

---return the scale of ui coordinates in respect to the resolution
---@return number, number the scaling factors in x, y direction (in pixel)
function M.getUIScale()
    return _ui_x_unit, _ui_y_unit
end

---@return number, number, number, number l, r, b, t
function M.getPlayfieldBoundaryInGame()
    return _playfield_game_l, _playfield_game_r, _playfield_game_b, _playfield_game_t
end

---@return number, number, number, number l, r, b, t
function M.getPlayfieldBoundaryInUI()
    local game_ui_l, game_ui_b = GameToUI(_playfield_game_l, _playfield_game_b)
    local game_ui_r, game_ui_t = GameToUI(_playfield_game_r, _playfield_game_t)
    return game_ui_l, game_ui_r, game_ui_b, game_ui_t
end

---@return number, number, number, number l, r, b, t
function M.getPlayfieldBoundaryInRes()
    local game_res_l, game_res_b = GameToRes(_playfield_game_l, _playfield_game_b)
    local game_res_r, game_res_t = GameToRes(_playfield_game_r, _playfield_game_t)
    return game_res_l, game_res_r, game_res_b, game_res_t
end

---@return number, number, number, number l, r, b, t
function M.getOutOfBoundDeletionBoundaryInGame()
    return _bound_game_l, _bound_game_r, _bound_game_b, _bound_game_t
end

---return the viewport in "res" coordinates;
---@return number, number, number, number l, r, b, t
local function GetGameViewport()
    local l, r, b, t = M.getPlayfieldBoundaryInRes()
    return l, r, b ,t
end

---return the ortho in "game" coordinates;
---@return number, number, number, number l, r, b, t
local function GetGameOrtho()
    local screen_effect = require("BHElib.unclassified.screen_effect")
    local dx, dy = screen_effect:getPlayfieldDisplayOffset()
    return _playfield_game_l + dx, _playfield_game_r + dx, _playfield_game_b + dy, _playfield_game_t + dy
end

---return the boundary of window in "res" coordinates;
---@return number, number, number, number l, r, b, t
local function GetUIViewport()
    local w, h = GetResolution()
    return 0, w, 0, h
end

---return the boundary of window in "ui" coordinates;
---@return number, number, number, number l, r, b, t
local function GetUIOrtho()
    local w, h = GetResolution()
    local window_res_l, window_res_b = ResToUI(0, 0)
    local window_res_r, window_res_t = ResToUI(w, h)
    return window_res_l, window_res_r, window_res_b, window_res_t
end

---set play field boundary in "game" coordinates
---@param left number x value of the left play field border
---@param right number x value of the right play field border
---@param bottom number y value of the bottom play field border
---@param top number y value of the top play field border
function M.setPlayFieldBoundary(left, right, bottom, top)
    _playfield_game_l = left
    _playfield_game_r = right
    _playfield_game_b = bottom
    _playfield_game_t = top

    _dirty = true
end

---set out of bound deletion boundary in "game" coordinates
---@param left number x value of the left bound border
---@param right number x value of the right bound border
---@param bottom number y value of the bottom bound border
---@param top number y value of the top bound border
function M.setOutOfBoundDeletionBoundary(left, right, bottom, top)
    _bound_game_l = left
    _bound_game_r = right
    _bound_game_b = bottom
    _bound_game_t = top
    SetBound(left, right, bottom, top)  -- call engine api
end

---@~chinese 切换渲染使用的坐标系。可选的三个坐标系为"game", "ui"或"3d"；
---
---@~chinese 改变模式后，所有对坐标系的改动才会应用在实际渲染上；Render，ObjRender等函数都受此函数影响
---
---@~english set the coordinate system used by the engine for rendering; the coordinates can be "game", "ui" or "3d";
---
---@~english only after setting the coordinates, all changes to the coordinates will be applied to actual rendering;
---
---@~english functions like Render or ObjRender are affected by this function
---aram mode string specifies the mode to set; can be "game", "ui" or "3d"
function M.setRenderView(coordinates_name)
    local is_dirty = _dirty or _view3d.dirty

    if is_dirty or coordinates_name ~= _current_render_view then
        _dirty = false
        _view3d.dirty = false

        _current_render_view = coordinates_name

        lstg.viewmode = coordinates_name
        if coordinates_name == "3d" then
            local fovy = _view3d.fovy
            local vec_z = _view3d.z
            local pos_eye = _view3d.eye
            local pos_at = _view3d.at
            local vec_up = _view3d.up
            local vec_fog = _view3d.fog

            -- play field width/height in "game" coordinates
            local playfield_width = _playfield_game_r - _playfield_game_l
            local playfield_height = _playfield_game_t - _playfield_game_b

            local vl, vr, vb, vt = GetGameViewport()
            SetViewport(vl, vr, vb, vt)

            SetPerspective(
                    pos_eye[1], pos_eye[2], pos_eye[3],
                    pos_at[1], pos_at[2], pos_at[3],
                    vec_up[1], vec_up[2], vec_up[3],
                    fovy,
                    playfield_width / playfield_height,
                    vec_z[1], vec_z[2])

            SetFog(vec_fog[1], vec_fog[2], vec_fog[3])

            local dx, dy, dz = pos_eye[1] - pos_at[1], pos_eye[2] - pos_at[2], pos_eye[3] - pos_at[3]
            SetImageScale(
                    sqrt(dx * dx + dy * dy + dz * dz) * 2
                            * tan(fovy * 0.5)
                            / (playfield_width / _game_x_unit * _ui_x_unit))

        elseif coordinates_name == "game" then

            -- set viewport and ortho to the size of the play field
            local l, r, b, t = GetGameViewport()
            -- set display region on screen ("viewport")
            SetViewport(l, r, b, t)  -- in "res"
            l, r, b, t = GetGameOrtho()
            SetOrtho(l, r, b, t)  -- in "game"

            SetFog()
            --SetImageScale((world.r-world.l)/(world.scrr-world.scrl))--usually it is 1
            SetImageScale(1)

        elseif coordinates_name == "ui" then

            -- set viewport and ortho to the size of the window
            local l, r, b, t = GetUIViewport()
            SetViewport(l, r, b, t)  -- in "res"
            l, r, b, t = GetUIOrtho()
            SetOrtho(l, r, b, t)  -- in "ui"

            SetFog()
            SetImageScale(1)

        else
            error(i18n 'Invalid arguement for setRenderView')
        end
    end
end

---@~chinese 设置雾效果。若无参数，将关闭雾效果。否则开启雾效果。
---@~chinese - `near`为`-1`时，使用EXP1算法，`far`作为强度参数。
---@~chinese - `near`为`-2`时，使用EXP2算法，`far`作为强度参数。
---@~chinese - 否则，使用线性算法，`near, far`作为范围参数。
---
---@~english Set fog effect. Will clear fog effect if no parameters are passed, otherwise enable fog effect.
---@~english - If `near` is `-1`, EXP1 algorism will be used and `far` will be density parameter.
---@~english - If `near` is `-2`, EXP2 algorism will be used and `far` will be density parameter.
---@~english - Otherwise, linear algorism will be used and `near, far` will be range parameter.
---
---@param near number
---@param far number
---@param color lstg.Color 可选，默认为`0x00FFFFFF` | optional, default is `0x00FFFFFF`.
function M.setFog(near, far, color)
    local t = {}
    local fog_type
    if not near or near == far then
        -- no fog
        for k, _ in pairs(INTERNAL_MODE) do
            t[k] = '_' .. k
        end
    elseif near == -1 then
        -- exp1
        fog_type = 2
        for k, _ in pairs(INTERNAL_MODE) do
            t[k] = k .. '+fog2'
        end
    elseif near == -2 then
        -- exp2
        fog_type = 3
        for k, _ in pairs(INTERNAL_MODE) do
            t[k] = k .. '+fog3'
        end
    else
        -- linear
        fog_type = 1
        for k, _ in pairs(INTERNAL_MODE) do
            t[k] = k .. '+fog1'
        end
    end
    color = color or Color(0xff000000)
    for k, v in pairs(t) do
        local rm = lstg.RenderMode:getByName(k)
        local rm_fog = lstg.RenderMode:getByName(v)
        assert(rm, ("%q"):format(k))
        assert(rm_fog, ("%q"):format(v))
        rm:setProgram(rm_fog:getProgram())
        if fog_type then
            rm:setColor('u_fogColor', color)
            if fog_type == 1 then
                rm:setFloat('u_fogStart', near)
                rm:setFloat('u_fogEnd', far)
            else
                rm:setFloat('u_fogDensity', far)
            end
        end
    end
end
SetFog = M.setFog

---------------------------------------------------------------------------------------------------
---for updating and modifying the boundary

---setup "ui" coordinates by the given resolution size;
---this function will fit the 640*480 4:3 hud maximally to the given resolution size
---@param hud_ui_width number width of the hud in "ui" coordinates
---@param hud_ui_height number height of the hud in "ui" coordinates
---@param res_width number screen resolution width
---@param res_height number screen resolution height
function M.setUICoordinatesByResolution(hud_ui_width, hud_ui_height, res_width, res_height)
    -- calculate the offset and scale that can maximally fit the 4:3 hud into the screen
    _hud_ui_width = hud_ui_width
    _hud_ui_height = hud_ui_height
    local scale
    if res_width / _hud_ui_width > res_height / _hud_ui_height then
        -- 高度受限，适应高度
        scale = res_height / _hud_ui_height
        _ui_x = 0.5 * (res_width - scale * _hud_ui_width)  -- center hud in the x direction
        _ui_y = 0.0
    else
        -- 宽度受限，适应宽度
        scale = res_width / _hud_ui_width
        _ui_x = 0.0
        _ui_y = 0.5 * (res_height - scale * _hud_ui_height)  -- center hud in the y direction
    end

    -- assign the scale
    _ui_x_unit = scale
    _ui_y_unit = scale

    _dirty = true
end

---setup "game" coordinates in terms of "ui" coordinates
---@param x number x coordinate of the origin of "game" coordinates expressed in "ui" coordinates
---@param y number y coordinate of the origin of "game" coordinates expressed in "ui" coordinates
---@param x_unit number scale in x direction expressed in "ui" coordinates
---@param y_unit number scale in y direction expressed in "ui" coordinates
function M.setGameCoordinatesInUI(x, y, x_unit, y_unit)
    -- record the origin in "ui" in case the resolution needs to be changed
    _game_ui_x = x
    _game_ui_y = y
    _game_ui_x_unit = x_unit
    _game_ui_y_unit = y_unit

    -- calculate origin and scale in "res" coordinates
    _game_x = _ui_x + x * _ui_x_unit
    _game_y = _ui_y + y * _ui_y_unit
    _game_x_unit = _ui_x_unit * x_unit
    _game_y_unit = _ui_y_unit * y_unit

    _dirty = true
end

---------------------------------------------------------------------------------------------------
---debugging

---turn the metrics of a view into a string for output
---@param mode string the view mode to output information about
---@return string human-readable info of the view
function M.getViewModeInfo(mode)
    local ret = ''
    if mode == "3d" then
        local game_vp_l, game_vp_r, game_vp_b, game_vp_t = GetGameViewport()

        local vp_str = string.format(
                'vp: (%.1f, %.1f, %.1f, %.1f)',
                game_vp_l, game_vp_r, game_vp_b, game_vp_t)
        ret = string.format("%s\n%s", vp_str, _view3d:getStringRepr())
    elseif mode == "game" then
        local game_vp_l, game_vp_r, game_vp_b, game_vp_t = GetGameViewport()
        local game_or_l, game_or_r, game_or_b, game_or_t = GetGameOrtho()

        local vp = string.format(
                'vp: (%.1f, %.1f, %.1f, %.1f)',
                game_vp_l, game_vp_r, game_vp_b, game_vp_t)
        local or_ = string.format(
                'or: (%.1f, %.1f, %.1f, %.1f)',
                game_or_l, game_or_r, game_or_b, game_or_t)
        ret = string.format(
                '%s\n%s',
                vp, or_)
    elseif mode == "ui" then
        local ui_vp_l, ui_vp_r, ui_vp_b, ui_vp_t = GetUIViewport()
        local ui_or_l, ui_or_r, ui_or_b, ui_or_t = GetUIOrtho()

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

---------------------------------------------------------------------------------------------------
---initializing

---print information about viewport/ortho inputs to log file
local function WriteToLog()
    local fmt = '%.1f, %.1f, %.1f, %.1f'

    local game_vl, game_vr, game_vb, game_vt = GetGameViewport()
    local game_ol, game_or, game_ob, game_ot = GetGameOrtho()
    local ui_vl, ui_vr, ui_vb, ui_vt = GetUIViewport()
    local ui_ol, ui_or, ui_ob, ui_ot = GetUIOrtho()

    local ui_viewport = string.format(fmt, ui_vl, ui_vr, ui_vb, ui_vt)
    local ui_ortho = string.format(fmt, ui_ol, ui_or, ui_ob, ui_ot)
    local game_viewport = string.format(fmt, game_vl, game_vr, game_vb, game_vt)
    local game_ortho = string.format(fmt, game_ol, game_or, game_ob, game_ot)
    local t = {
        ui_vp        = ui_viewport,     ui_ortho = ui_ortho,
        game_vp     = game_viewport,    world_ortho = game_ortho,
        screen_scale = _ui_x_unit
    }
    SystemLog("view params:\n" .. stringify(t))

    local scale = _glv:getDesignResolutionSize().height / 480
    SystemLog(string.format(
            'by default, ui scale = %.3f should be the same as screen.scale = %.3f', scale, _ui_x_unit))
end

---initialize coordinate systems;
---the design resolution of GLView should be set when is function is called
function M.initGameCoordinates()
    -- the "game" coordinates depends on "ui"; "3d" depends on "game", so the order of setup is important

    -- setup "ui" coordinates
    local res_width, res_height = M.getResolution()
    M.setUICoordinatesByResolution(640, 480, res_width, res_height)

    -- setup "game" coordinates
    local game_center_ui_x, game_center_ui_y = 320, 240  -- in "ui" cooridinates
    M.setGameCoordinatesInUI(game_center_ui_x, game_center_ui_y, 1, 1)

    M.setPlayFieldBoundary(-192, 192, -224, 224)
    M.setOutOfBoundDeletionBoundary(-224, 224, -256, 256)

    -- setup "3d" coordinates
    local View3d = require("BHElib.background.view3d")
    M.initView3d(View3d())

    -- previous changes are enforced by setting the render view
    M.setRenderView("ui")

    WriteToLog()
end

return M