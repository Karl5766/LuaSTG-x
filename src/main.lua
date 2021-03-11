--
--lstg.DoFile('jit_test.lua')
local fu = cc.FileUtils:getInstance()
fu:setPopupNotify(false)
-- note: GLView is opened in display.lua
-- it's necessary for FrameInit
require('config')
require('cocos.init')
setmetatable(_G, nil)
-- package.path may not end with ';'
package.path = package.path .. ';?/__init__.lua;'
require('cc.ext')
require('cc.to_string')
require('cc.color')
require('i18n')
require('audio')

local _path = {}
local _path_rec = {}
for _, v in ipairs(fu:getSearchPaths()) do
    local p = string.gsub(v, '\\', '/')
    p = string.gsub(p, '//', '/')
    if not _path_rec[p] then
        table.insert(_path, p)
        _path_rec[p] = true
    end
end
fu:setSearchPaths(_path)

local sp = fu:getSearchPaths()
local _sp = '=== Search Path ===\n{'
for _, v in ipairs(sp) do
    _sp = string.format('%s\n    %q', _sp, v)
end
lstg.SystemLog(_sp .. '\n}')

local function main()
    lstg.SystemLog('start main')
    lstg.FrameInit()
    local platform = lstg.GetPlatform()
    if platform == 'android' then
        -- change src path to 'sdcard/lstg/src' if it exists
        local sd = require('platform.android.native').getSDCardPath()
        if sd and sd ~= '' then
            local src = sd .. '/lstg/src'
            if fu:isDirectoryExist(src) then
                local paths = {}
                for _, v in ipairs(sp) do
                    if v ~= 'assets/src/' then
                        table.insert(paths, v)
                    end
                end
                table.insert(paths, src)
                fu:setSearchPaths(paths)
                lstg.SystemLog(string.format('change src path to %q', src))
            end
        end
        require('platform.android.native').setOrientationLandscape()
    end
    lstg.DoFile('launch.lua')
    lstg.SystemLog('start app')
    require("app.MyApp"):create():run()
end

---note: in app.run, only __G__TRACKBACK__ will take effect
---@param message string error message
---@return string error message
__G__TRACKBACK__ = function(message)
    message = debug.traceback(message, 3)

    local DebugUtil = require("util.debug_util")
    DebugUtil.error(message, "Error")
    lstg.SystemLog('caught error in main')

    return message
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    lstg.SystemLog('=== Error Message ===\n' .. msg)
end
