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
require('api')
if _platform_info.isMobile() then
    require('jit_test')
    -- define Print function
    _G.Print = function(...)
        local args = { ... }
        local narg = select('#', ...)
        for i = 1, narg do
            args[i] = tostring(args[i])
        end
        SystemLog(table.concat(args, '\t'))
    end
else
    -- define Print function
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

DoFile("plus/plus.lua")
DoFile("stringify.lua")

require('imgui.__init__')

if _ARGS and #_ARGS >= 2 then
    assert(loadstring(_ARGS[2]))()
end

--skip the launchers
require('app.views.MainScene').setSkip(true, true)

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

--SetResLoadInfo(true)
--require("jit.opt").start("sizemcode=1024", "maxmcode=1024")

DoFile('core/__init__.lua')
