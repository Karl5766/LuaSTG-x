---reference:
---     cjson manual, https://www.kyne.com.au/~mark/software/lua-cjson-manual.html

local M = {}

---format the string representation of setting table
---@param str string string to be formatted
---@return string formatted string
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

local FU = cc.FileUtils:getInstance()
local FS = require("file_system.file_system")

local _setting_path = FS.getWritablePath() .. 'setting/setting.ini'  -- setting file is at the main directory

---load global setting table from the setting file
function M.loadSettingFile()
    setting = {}
    local file_content_str = FU:getStringFromFile(_setting_path)

    if not (file_content_str and file_content_str ~= '') then
        lstg.SystemLog("ERROR: setting file does not exist.")
    end

    setting = cjson.decode(file_content_str)
end

---save global setting table to the setting file
function M.saveSettingFile()
    local str = M.encodeTest(setting)
    FU:writeStringToFile(str, _setting_path)
end

---------------------------------------------------------------------------------------------------
---debugging

---check if decode(format_json(encode(o))) is the same as o;
---if so, the result copy of o is returned; if not, an error will be thrown
---@param o any the object to test
---@return string, any an encoded formatted string copy and an decoded copy of os
function M.encodeTest(o)
    local str = cjson.encode(o)
    str = M.format_json(str)
    local result = cjson.decode(str)

    if not M.tableDeepEqual(result, o) then
        error(i18n 'error in parsing setting')
    end
    return str, result
end

local function IsVal(s)
    return s == 'boolean' or s == 'number' or s == 'string'
end

---deep table equality test;
---
---input tables can only contain "boolean", "number", "string" or "table" type values
---@param t1 table input table 1
---@param t2 table input table 2
---@return boolean if t1 == t2
function M.tableDeepEqual(t1, t2)
    -- test if every value in t1 is the same in t2
    for k1, v1 in pairs(t1) do
        local v2 = t2[k1]
        if v2 == nil then
            return false
        end
        local type1 = type(v1)
        if type1 ~= type(v2) then
            return false
        end
        if IsVal(type1) then  -- both are value type, but with differnet values
            if v1 ~= v2 then
                return false
            end
        elseif type1 == "table" then
            -- both are table, recursively compare them
            if not M.tableDeepEqual(v1, v2) then
                return false
            end
        else  -- not value types nor table type, v1 is of illegal type, raise an error
            error("ERROR: Tables to compare contain illegal value type!")
        end
    end

    -- t2 may still include keys that t1 does not have;
    -- test if both tables have the same keys
    for k, _ in pairs(t2) do
        if t1[k] == nil then
            return false
        end
    end

    -- if every test passes, t1 == t2
    return true
end

local function TableDeepEqualUnitTest()  -- for debug
    --expected: fffttft
    lstg.SystemLog(tostring(M.tableDeepEqual({1, 2}, {1})))
    lstg.SystemLog(tostring(M.tableDeepEqual({1}, {1, 2})))
    lstg.SystemLog(tostring(M.tableDeepEqual({7, "sk"}, {6, "sk"})))

    lstg.SystemLog(tostring(M.tableDeepEqual({3, 2}, {3, 2})))
    lstg.SystemLog(tostring(M.tableDeepEqual({"ecl", 5}, {"ecl", 5})))

    lstg.SystemLog(tostring(M.tableDeepEqual({1, 2, {7}}, {1, 2, {7}, 5})))
    lstg.SystemLog(tostring(M.tableDeepEqual({1, 2, {7}, 5}, {1, 2, {7}, 5})))
end

return M
