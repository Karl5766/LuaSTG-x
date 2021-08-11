---------------------------------------------------------------------------------------------------
---json_file_mirror.lua
---date: 2021.8.10
---reference: cjson manual, https://www.kyne.com.au/~mark/software/lua-cjson-manual.html
---desc: A class in which objects are designed to be mirror of a (json formatted) text file on disk.
---     Note the content of the object can not be of type "function", "userdata" or "thread", the
---     key type for the table variables can only be "number" or "string"
---------------------------------------------------------------------------------------------------

---@class JsonFileMirror
local M = LuaClass("JsonFileMirror")

local FS = require("file_system.file_system")
local FU = cc.FileUtils:getInstance()

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TurnStringToLuaObject
local TurnLuaObjectToString
local EncodeTest
local cjson = cjson

---------------------------------------------------------------------------------------------------

---args may have optional parameters:
---
---     allow_empty_init_file (boolean) - if true, make a new table when no init file is found; otherwise throw an error
---
---     file_not_found_message (string) - message displayed when file is not found (if allow_empty_init_file = false)
---
---     encode_test_flag (boolean) - do a encoding test when saving to computer
---
---@param sync_file_path string the path of the text file to read/write
---@param args table additional options
function M.__create(sync_file_path, args)
    local self = {}

    self.sync_file_path = sync_file_path

    args = args or {}
    self.encode_test_flag = args.encode_test_flag == true
    self.allow_empty_init_file = args.allow_empty_init_file == true
    self.file_not_found_message = args.file_not_found_message or "Can't find file"

    return self
end

function M:ctor()
    self:syncFromFile()
end

---should not assigning any value to a already existing sub-table of the content table,
---as there may be variable references to it
---@return table a mirror of the content of the file
function M:getContent()
    return self.file_content
end

---save file_content table to the file
function M:syncToFile()
    if self.encode_test_flag then
        local str = EncodeTest(self.file_content)
        FU:writeStringToFile(str, self.sync_file_path)
    else
        FU:writeStringToFile(TurnLuaObjectToString(self.file_content), self.sync_file_path)
    end
end

local function ErrorFileNotFound(self)
    error(string.format("%s: %s", self.file_not_found_message, self.sync_file_path))
end

---load file_content table from the file
function M:syncFromFile()
    local sync_file_path = self.sync_file_path
    local file_content = {}
    if not FS.isFileExist(sync_file_path) then
        if self.allow_empty_init_file then
            file_content = {}
        else
            ErrorFileNotFound(self)
        end
    else
        local alt_sync_file_path = FU:getSuitableFOpen(sync_file_path)
        if not FU:isFileExist(sync_file_path) then
            if FU:isFileExist(alt_sync_file_path) then
                -- sometimes the conversion is redundant (reason still unknown)
                sync_file_path = alt_sync_file_path
            else
                if not self.allow_empty_init_file then
                    ErrorFileNotFound(self)
                end
            end
        end

        local data_str = FU:getStringFromFile(sync_file_path)
        if not data_str or data_str == '' then
            if not self.allow_empty_init_file then
                ErrorFileNotFound(self)
            end
            Print("empty file content found; in json_file_mirror.lua.")
            data_str = [[{"_":0}]]
        end
        file_content = TurnStringToLuaObject(data_str)
    end
    self.file_content = file_content
end

---@param str string cjson encoded string
function M.turnStringToLuaObject(str)
    return cjson.decode(str)
end
TurnStringToLuaObject = M.turnStringToLuaObject

---@param object number|table
function M.turnLuaObjectToString(object)
    return cjson.encode(object)
end
TurnLuaObjectToString = M.turnLuaObjectToString

---format a json string representing a file's content
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

---------------------------------------------------------------------------------------------------
---debugging

---check if decode(format_json(encode(o))) is the same as o;
---if so, the result copy of o is returned; if not, an error will be thrown
---@param object any the object to test
---@return string, any an encoded formatted string copy and an decoded copy of os
function M.encodeTest(object)
    local str = cjson.encode(object)
    str = M.format_json(str)
    local result = cjson.decode(str)

    if not M.tableDeepEqual(result, object) then
        error(i18n "Error: Decoding an (formatted) encoded object gives different results!")
    end
    return str, result
end
EncodeTest = M.encodeTest

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