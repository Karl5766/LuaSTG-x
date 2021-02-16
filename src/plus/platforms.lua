---------------------------------------------------------------------------------------------------
---platforms.lua
---date: 2021.2.15
---desc: Defines some platform and language related stuffs
---modifier:
---     Karl, 2021.2.15, some small changes in formatting and renaming; renamed the file from
---     NativeAPI.lua to platforms.lua, and split some code to a new file named
---     local_directory_interfaces.lua
---------------------------------------------------------------------------------------------------

function plus.isMobile()
    return plus.is_mobile
end

function plus.isDesktop()
    return not plus.is_mobile
end

---------------------------------------------------------------------------------------------------

local function Setup()
    local osname = lstg.GetPlatform()
    plus.os = osname
    plus.is_mobile = osname == 'android' or osname == 'ios'
    if osname == 'android' then
        local native = require('platform.android.native')
        local info = native.getNativeInfo()
        plus.native_info = info
        local inf = '\n=== Native Info ===\n'
        for k, v in pairs(info) do
            inf = inf .. string.format('%s = %s\n', k, tostring(v))
        end
        SystemLog(inf)
    end
    local newWritablePath = require('platform.util').changeWritablePath()
    if newWritablePath then
        _writable_path = newWritablePath
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

local _platform = {
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

local function WriteAppInfoToLog()
    local info = {}
    local app = cc.Application:getInstance()
    info.platform = _platform[app:getTargetPlatform() + 1] or 'unknown'
    info.version = app:getVersion()
    info.language_code = app:getCurrentLanguageCode()
    info.language = _languages[app:getCurrentLanguage() + 1] or 'unknown'
    plus.language = info.language
    plus.platform = info.platform
end
WriteAppInfoToLog()

---------------------------------------------------------------------------------------------------