-- 0 - disable debug info, 1 - less debug info, 2 - verbose debug info
DEBUG = 0

-- use framework, will disable all deprecated API, false - use legacy API
CC_USE_FRAMEWORK = true

-- show FPS on screen
CC_SHOW_FPS = true

-- disable create unexpected global variable
CC_DISABLE_GLOBAL = false

-- for module display
CC_DESIGN_RESOLUTION = {
    width     = 1708,
    height    = 960,
    autoscale = "SHOW_ALL",
    callback  = function(framesize)
        return { autoscale = "SHOW_ALL" }
    end
}

--
local M = {}

require('cocos.cocos2d.json')
local json = cjson or json

---@type ScreenMetrics
local _scr_metrics
local function InitSetting()
    require("setting.setting_util").loadSettingFile()
    _scr_metrics = require("setting.screen_metrics")
    _scr_metrics.init(setting)
end
InitSetting()

local _resizable = true
local _transparent = false

if lstg.glfw and _transparent then
    local g = require('platform.glfw')
    -- Init() is necessary for following functions
    g.Init()
    g.WindowHint(g.GLFW_TRANSPARENT_FRAMEBUFFER, g.GLFW_TRUE)
    cc.Director:getInstance():setClearColor({ r = 0, g = 0, b = 0, a = 0 })
end

local function InitGLView()
    local director = cc.Director:getInstance()
    local _glv = director:getOpenGLView()
    local title = 'LuaSTG-x'  -- initial title, can be modified by SetTitle()

    local function create_rect(_x, _y, _width, _height)
        return { x = _x, y = _y, width = _width, height = _height }
    end
    if not _glv then
        -- init _glv instance
        local w, h = _scr_metrics.getScreenSize()
        if _scr_metrics.getWindowed() then
            if _resizable and lstg.glfw then
                _glv = cc.GLViewImpl:createWithRect(title, create_rect(0, 0, w, h), 1, true)
            else
                _glv = cc.GLViewImpl:createWithRect(title, create_rect(0, 0, w, h))
            end
        else
            _glv = cc.GLViewImpl:createWithFullScreen(title)
        end
        director:setOpenGLView(_glv)
        if cc.Configuration then
            local cfg = cc.Configuration:getInstance()
            local backend_device = cfg:getValue('renderer', 'N/A')
            local backend_version = cfg:getValue('version', 'N/A')
            lstg.SystemLog(('Backend device: %s'):format(backend_device))
            lstg.SystemLog(('Backend version: %s'):format(backend_version))
        end
    end

    _scr_metrics.setVsync(_scr_metrics.getVsync())  -- init set vsync after making sure glv is created
    _scr_metrics.setSplash(_scr_metrics.getSplash())  -- show cursor

    if setting.render_skip == 1 then
        lstg.SetFPS(30)
    else
        lstg.SetFPS(60)
    end
end
InitGLView()

return M
