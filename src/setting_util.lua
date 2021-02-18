local M = {}

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
            return M.compare(v, v2)
        else
            return false
        end
    end
    return true
end

local FU = cc.FileUtils:getInstance()
local FS = require("file_system")

local _setting_path = FS.getWritablePath() .. 'setting'
local _setting = {}
function M.loadSettingFile()
    local file_content_str = FU:getStringFromFile(_setting_path)
    _setting = DeSerialize(Serialize(setting))
    setting = {}
    setmetatable(setting, {
        __newindex = function(t, k, v)
            _setting[k] = v
            if k == 'res_ratio' then
                local ratio = v[1] / v[2]
                setting.resx = math.ceil(setting.resy * ratio / 2) * 2
            elseif k == 'resy' then
                local ratio = setting.res_ratio[1] / setting.res_ratio[2]
                setting.resx = math.ceil(v * ratio / 2) * 2
            end
        end,
        __index    = _setting
    })

    if file_content_str and file_content_str ~= '' then
        local s = DeSerialize(file_content_str)
        for k, v in pairs(s) do
            setting[k] = v
        end
    end
end

function M.saveSettingFile()
    assert(setting and getmetatable(setting))
    local t = getmetatable(setting).__index
    local s = M.format_json(Serialize(t))
    assert(M.compare(DeSerialize(s), t))
    FU:writeStringToFile(s, _setting_path)
end

return M
