---reference:
---     cjson manual, https://www.kyne.com.au/~mark/software/lua-cjson-manual.html

local M = {}

---format the string representation of setting table
function M.format_json(str)
    local ret = ''
    local indent = '    '
    local level = 0
    local in_string = false
    for i = 1, #str do
        local s = string.sub(str, i, i)
        if s == '{' and (not in_string) then
            level = level + 1
            ret = ret .. '{\n' .. string.rep(indent, level)
        elseif s == '}' and (not in_string) then
            level = level - 1
            ret = string.format(
                    '%s\n%s}', ret, string.rep(indent, level))
        elseif s == '"' then
            in_string = not in_string
            ret = ret .. '"'
        elseif s == ':' and (not in_string) then
            ret = ret .. ': '
        elseif s == ',' and (not in_string) then
            ret = ret .. ',\n'
            ret = ret .. string.rep(indent, level)
        elseif s == '[' and (not in_string) then
            level = level + 1
            ret = ret .. '[\n' .. string.rep(indent, level)
        elseif s == ']' and (not in_string) then
            level = level - 1
            ret = string.format(
                    '%s\n%s]', ret, string.rep(indent, level))
        else
            ret = ret .. s
        end
    end
    return ret
end

local function isval(s)
    return s == 'boolean' or s == 'number' or s == 'string'
end

function M.compare(t1, t2)
    for k, v in pairs(t1) do
        local v2 = t2[k]
        if v2 == nil then
            return false
        end
        local ty = type(v)
        if ty ~= type(v2) then
            return false
        end
        if isval(ty) then
            if v ~= v2 then
                return false
            end
        elseif ty == 'table' then
            return M.compare(v, v2)  -- TOBEDEBUGGED
        else
            return false
        end
    end
    return true
end

local FU = cc.FileUtils:getInstance()
local FS = require("file_system")

local _setting_path = FS.getWritablePath() .. 'setting/setting'  -- setting file is at the main directory

---load global setting table from the setting file
function M.loadSettingFile()
    local file_content_str = FU:getStringFromFile(_setting_path)
    setting = {}

    if file_content_str and file_content_str ~= '' then
        local s = cjson.decode(file_content_str)
        for k, v in pairs(s) do
            setting[k] = v
        end
    end
end

---save global setting table to the setting file
function M.saveSettingFile()
    local t = setting
    local s = SerializeTest(t)
    FU:writeStringToFile(s, _setting_path)
end

---update the screen and sound settings according to the values set in global setting table
function M.updateScreenSoundFromSetting()
    local _glv = cc.Director:getInstance():getOpenGLView()
    SetVsync(setting.vsync)
    _glv:setDesignResolutionSize(
            setting.resx, setting.resy, cc.ResolutionPolicy.SHOW_ALL)
    SetTitle(setting.mod)
    SetSEVolume(setting.sevolume / 100)
    SetBGMVolume(setting.bgmvolume / 100)

    local size = _glv:getDesignResolutionSize()
    SystemLog(string.format('DesignRes = %d, %d', size.width, size.height))
    size = _glv:getFrameSize()
    SystemLog(string.format('FrameSize = %d, %d', size.width, size.height))
    SystemLog(string.format('Scale     = %.3f, %.3f', _glv:getScaleX(), _glv:getScaleY()))
    --SystemLog('setting = \n' .. stringify(_setting))
    --SystemLog('screen = \n' .. stringify(screen))
end

---check if decode(format_json(encode(o))) is the same as o;
---if so, the result copy of o is returned
---@param o any the object to test
function SerializeTest(o)
    local str = cjson.encode(o)
    str = setting_util.format_json(str)
    local result = cjson.decode(str)

    if not setting_util.compare(result, o) then
        error(i18n 'error in parsing setting')
    end
    return result
end

return M
