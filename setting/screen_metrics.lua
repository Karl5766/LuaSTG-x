---------------------------------------------------------------------------------------------------
---screen_metrics.lua
---date: 2021.2.27
---reference: src/api.lua
---desc: Defines ScreenMetrics, which deals with the recording and updating of the current screen
---     settings.
---------------------------------------------------------------------------------------------------

---@class ScreenMetrics
local M = {}

---@type JsonFileMirror
local _setting_file_mirror
local _setting_screen  -- a table under the setting table that stores screen information

---screen resolution in pixels
local _resx, _resy

---screen size (how big the screen is)
local _windowsize_w, _windowsize_h

---mouse visibility, display the mouse if is true
local _splash

---window title
local _title = "LuaSTG-x"  -- later set to mod name manually

---other window settings
local _windowed, _vsync

---------------------------------------------------------------------------------------------------

---initialize the screen metrics according to the given setting table;
---after first initialization, the window size is not up-to-date with the metrics, but the outside
---screen initialization functions can take this object and use its getters to help init the screen.
---
---this function should only be called on application startup
---@param setting_file_mirror JsonFileMirror the setting table that specifies the default init values
function M.init(setting_file_mirror)
    _setting_file_mirror = setting_file_mirror
    _setting_screen = _setting_file_mirror:getContent().screen

    _resx = _setting_screen.resx
    _resy = _setting_screen.resy
    _windowsize_w = _setting_screen.windowsize_w
    _windowsize_h = _setting_screen.windowsize_h

    _windowed = _setting_screen.windowed
    _vsync = _setting_screen.vsync
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
    _setting_screen.resx = res_width
    _setting_screen.resy = res_height
    _setting_file_mirror:syncToFile()
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
    _setting_screen.resx = screen_width
    _setting_screen.resy = screen_height
    _setting_file_mirror:syncToFile()
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
    _setting_screen.windowed = is_windowed
    _setting_file_mirror:syncToFile()
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
    _setting_screen.vsync = is_vsync
    _setting_file_mirror:syncToFile()
end

---------------------------------------------------------------------------------------------------
---cursor display

function M.getSplash()
    return _splash
end

---@~chinese 设置是否显示光标，默认显示
---
---@~english set if the mouse cursor is displayed in game window. Default is `true`.
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