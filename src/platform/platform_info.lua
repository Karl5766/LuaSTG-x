---------------------------------------------------------------------------------------------------
---platform_info.lua
---date: 2021.2.15
---desc: Defines some platform and language related stuffs
---modifier:
---     Karl, 2021.2.15, some small changes in formatting and renaming; renamed the file from
---     NativeAPI.lua to platforms.lua, and split some code to a new file named
---     local_directory_interfaces.lua
---     Karl, 2021.2.18, moved functions and variables from plus namespace into a class
---------------------------------------------------------------------------------------------------

---@class PlatformInfo
---@brief manages platform information about the device
local M = {}

local _is_mobile
local _os_name
local _native_info
local _platform
local _language

---return if the current platform is a mobile
function M.isMobile()
    return _is_mobile
end

---return if the current platform is not a mobile
function M.isDesktop()
    return not _is_mobile
end

---return the name of the operating system
function M.getOSName()
    return _os_name
end

---return the platform name
function M.getPlatform()
    return _platform
end

---------------------------------------------------------------------------------------------------

local function Setup()
    local osname = lstg.GetPlatform()
    _os_name = osname
    _is_mobile = osname == 'android' or osname == 'ios'
    if osname == 'android' then
        local native = require('platform.android.native')
        local info = native.getNativeInfo()
        _native_info = info
        local inf = '\n=== Native Info ===\n'
        for k, v in pairs(info) do
            inf = inf .. string.format('%s = %s\n', k, tostring(v))
        end
        SystemLog(inf)
    end
end
Setup()

---------------------------------------------------------------------------------------------------

local _languages = {
    'english',
    'chinese',
    'french',
    'italian',
    'german',
    'spanish',
    'dutch',
    'russian',
    'korean',
    'japanese',
    'hungarian',
    'portuguese',
    'arabic',
    'norwegian',
    'polish',
    'turkish',
    'ukrainian',
    'romanian',
    'bulgarian',
    'belarusian',
}

local _platforms = {
    'Windows',
    'Linux',
    'macOS',
    'Android',
    'iPhone',
    'iPad',
    'BlackBerry',
    'NACL',
    'Emscripten',
    'Tizen',
    'WinRT',
    'WP8',
}

local function InitAppInfo()
    local info = {}
    local app = cc.Application:getInstance()
    info.platform = _platforms[app:getTargetPlatform() + 1] or 'unknown'
    info.version = app:getVersion()
    info.language_code = app:getCurrentLanguageCode()
    info.language = _languages[app:getCurrentLanguage() + 1] or 'unknown'
    _language = info.language
    _platform = info.platform
end
InitAppInfo()

return M