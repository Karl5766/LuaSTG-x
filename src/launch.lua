--- version info
_luastg_version = 0x1000
_luastg_min_support = 0x1000

local __internal = {}
for k, v in pairs(lstg) do
    _G[k] = v
    __internal = v
end
lstg._internal = __internal
require('core.respool')

UnitList = ObjList
GetnUnit = GetnObj
cjson = cjson or json
math.mod = math.mod or math.fmod
string.gfind = string.gfind or string.gmatch
collectgarbage("setpause", 100)

for _, ns in ipairs({ cc, ccb, ccui, lstg }) do
    for _, v in pairs(ns) do
        local mt = getmetatable(v)
        if mt and (v.create or v.new) then
            if v.create then
                mt.__call = function(t, ...)
                    return t:create(...)
                end
            else
                mt.__call = function(t, ...)
                    return t:new(...)
                end
            end
        end
    end
end

--- keycode
KEY = require('keycode')

function DoFile(path)
    Print('[load] ' .. path)
    return lstg.DoFile(path)
end

local _platform_info = require("platform.platform_info")
DoFile('plus/plus.lua')
DoFile('stringify.lua')

setting = require('default_setting')
setting = SerializeTest(setting)
require("setting_util").loadSettingFile()

require('api')
if _platform_info.isMobile() then
    require('jit_test')
    _G.Print = function(...)
        local args = { ... }
        local narg = select('#', ...)
        for i = 1, narg do
            args[i] = tostring(args[i])
        end
        SystemLog(table.concat(args, '\t'))
    end
else
    -- define print/Print function
    _G.Print = function(...)
        local args = { ... }
        local narg = select('#', ...)
        for i = 1, narg do
            args[i] = tostring(args[i])
        end
        lstg.Print(table.concat(args, '\t'))
        if lstg._onPrint then
            lstg._onPrint(...)
        end
    end
end
print = Print

require('imgui.__init__')

if _ARGS and #_ARGS >= 2 then
    assert(loadstring(_ARGS[2]))()
    setting.mod_info = nil
end

--skip the launchers
require('app.views.MainScene').setSkip(true, true)

local glv = cc.Director:getInstance():getOpenGLView()

SetSplash(true)
SetTitle('LuaSTG-x')
ChangeVideoMode(
        setting.windowsize_w,
        setting.windowsize_h,
        setting.windowed,
        setting.vsync
)
if setting.render_skip == 1 then
    SetFPS(30)
else
    SetFPS(60)
end
SetSEVolume(setting.sevolume / 100)
SetBGMVolume(setting.bgmvolume / 100)

function lstg.loadSetting(change_vm)
    --if change_vm and (not setting.windowed) then
    --    ChangeVideoMode(0,0,false, setting.vsync)
    --else
    --    SetVsync(setting.vsync)
    --end
    SetVsync(setting.vsync)
    glv:setDesignResolutionSize(
            setting.resx, setting.resy, cc.ResolutionPolicy.SHOW_ALL)
    SetTitle(setting.mod)
    SetSEVolume(setting.sevolume / 100)
    SetBGMVolume(setting.bgmvolume / 100)

    local size = glv:getDesignResolutionSize()
    SystemLog(string.format('DesignRes = %d, %d', size.width, size.height))
    size = glv:getFrameSize()
    SystemLog(string.format('FrameSize = %d, %d', size.width, size.height))
    SystemLog(string.format('Scale     = %.3f, %.3f', glv:getScaleX(), glv:getScaleY()))
    --SystemLog('setting = \n' .. stringify(_setting))
    --SystemLog('screen = \n' .. stringify(screen))
end

--SetResLoadInfo(true)
--require("jit.opt").start("sizemcode=1024", "maxmcode=1024")

DoFile('core/__init__.lua')
