---------------------------------------------------------------------------------------------------
---screen_metrics.lua
---date: 2021.2.27
---reference: src/api.lua
---desc: Defines ScreenMetrics, which deals with the recording and updating of the current screen
---     settings.
---------------------------------------------------------------------------------------------------

---@class ScreenMetrics
local M = {}

---the setting table serves as default init values
local _default_setting

---screen resolution in pixels
local _resx, _resy

---screen size (how big the screen is)
local _windowsize_w, _windowsize_h

---mouse visibility, display the mouse if is true
local _splash

---window title
local _title = "LuaSTG-x"  -- later set to default_setting.mod manually

---other window settings
local _windowed, _vsync

---------------------------------------------------------------------------------------------------

---initialize the screen metrics according to the given setting table;
---after first initialization, the window size is not up-to-date with the metrics, but the outside
---screen initialization functions can take this object and use its getters to help init the screen.
---
---this function should only be called on application startup
---@param default_setting table the default setting table
function M.init(default_setting)
    _default_setting = default_setting
    _resx = default_setting.resx
    _resy = default_setting.resy
    _windowsize_w = default_setting.windowsize_w
    _windowsize_h = default_setting.windowsize_h

    _windowed = default_setting.windowed
    _vsync = default_setting.vsync
    _splash = true  -- default to true since there is no corresponding entry in setting file
end

---------------------------------------------------------------------------------------------------
---screen resolution

---@return number, number the screen resolution width, height
function M.getScreenResolution()
    return _resx, _resy

    -- equivalently, after glv is initilized:
    -- local res = _glv:getDesignResolutionSize()
    -- return res.width, res.height
end

---@param res_width number screen resolution width in pixels
---@param res_height number screen resolution height in pixels
---@param glv OpenGLView if given, set the design resolution of this glview object
function M.setScreenResolution(res_width, res_height, glv)
    _resx = res_width
    _resy = res_height
    if glv then
        glv:setDesignResolutionSize(res_width, res_height, cc.ResolutionPolicy.SHOW_ALL)
    end
end

---save the screen resolution to setting table, so it will be written to disk on
---the termination of the application.
---@param res_width number resolution width, setting to be saved
---@param res_height number resolution height, setting to be saved
function M.rememberScreenResolution(res_width, res_height)
    _default_setting.resx = res_width
    _default_setting.resy = res_height
end

---------------------------------------------------------------------------------------------------
---screen size

function M.getScreenSize()
    return _windowsize_w, _windowsize_h
end

---set the size of the game window.
---
---note: screen size only applies in desktop, but not mobile.
---@param screen_width number screen width
---@param screen_height number screen height
function M.setScreenSize(screen_width, screen_height)
    local w = lstg.WindowHelperDesktop:getInstance()
    if not _windowed then
        error("ERROR: Attempt to set screen size on full screen mode!")
    end
    _windowsize_w, _windowsize_h = screen_width, screen_height
    w:setSize(cc.size(screen_width, screen_height))
end

---save the screen size to setting table, so it will be written to disk on
---the termination of the application.
---@param screen_width number screen width, setting to be saved
---@param screen_height number screen height, setting to be saved
function M.rememberScreenSize(screen_width, screen_height)
    _default_setting.resx = screen_width
    _default_setting.resy = screen_height
end

---------------------------------------------------------------------------------------------------
---windowed

---get if the game is in windowed mode
---@return boolean if the game is in windowed mode
function M.getWindowed()
    return _windowed
end

---set to windowed (true) or to full screen(false) modes
function M.setWindowed(is_windowed)
    _windowed = is_windowed

    local w = lstg.WindowHelperDesktop:getInstance()
    if is_windowed then
        w:setSize(cc.size(_windowsize_w, _windowsize_h))
        w:moveToCenter()
    else
        w:setFullscreen()
    end
end

---save the windowed setting to setting table, so it will be written to disk on
---the termination of the application.
function M.rememberWindowed(is_windowed)
    _default_setting.windowed = is_windowed
end

---------------------------------------------------------------------------------------------------
---vsync

function M.getVsync()
    return _vsync
end

function M.setVsync(is_vsync)
    _vsync = is_vsync
    local w = lstg.WindowHelperDesktop:getInstance()
    w:setVsync(is_vsync)  -- TOBEDEBUGGED
end

---save the vsync setting to setting table, so it will be written to disk on
---the termination of the application.
function M.rememberVsync(is_vsync)
    _default_setting.vsync = is_vsync
end

---------------------------------------------------------------------------------------------------
---cursor display

function M.getSplash()
    return _splash
end

---@~chinese 设置是否显示光标，默认显示
---
---@~english Set if the mouse cursor is displayed in game window. Default is `true`.
---
---@param is_splash boolean if true, the cursor will not be hidden when inside the game window
function M.setSplash(is_splash)
    _splash = is_splash

    local w = lstg.WindowHelperDesktop:getInstance()
    w:setCursorVisible(is_splash)
end

---------------------------------------------------------------------------------------------------
---window title

---get the title displayed in the upper left corner of the window
function M.getWindowTitle()
    return _title
end

---set the title displayed in the upper left corner of the window
---@param new_title string new title to be set as the window title
function M.setWindowTitle(new_title)
    _title = new_title

    local w = lstg.WindowHelperDesktop:getInstance()
    w:setTitle(new_title)
end

return M