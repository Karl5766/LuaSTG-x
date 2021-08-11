---------------------------------------------------------------------------------------------------
---json_file_mirror.lua
---date: 2021.8.10
---desc: A class in which objects are designed to be mirror of a (json formatted) string file on disk.
---     Note the content of the object can not be of type "function", "userdata" or "thread", the
---     key type for the table variables can only be "number" or "string"
---------------------------------------------------------------------------------------------------

---@class JsonFileMirror
local M = LuaClass("JsonFileMirror")

local FS = require("file_system")
local FU = cc.FileUtils:getInstance()

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TurnStringToLuaObject
local TurnLuaObjectToString

---------------------------------------------------------------------------------------------------

---@param sync_file_path string the path of the text file to read/write
function M.__create(sync_file_path)
    local self = {}

    self.sync_file_path = sync_file_path

    return self
end

function M:ctor()
    self:syncFromFile()
end

---@return table a mirror of the content of the file
function M:getContent()
    return self.file_content
end

function M:syncToFile()
    FU:writeStringToFile(TurnLuaObjectToString(self.file_content), self.sync_file_path)
end

function M:syncFromFile()
    local sync_file_path = self.sync_file_path
    local file_content = {}
    if not FS.isFileExist(sync_file_path) then
        file_content = {}
    else
        -- score/mod_name/user_name.dat
        local alt_sync_file_path = FU:getSuitableFOpen(sync_file_path)
        if not FU:isFileExist(sync_file_path) then
            if FU:isFileExist(alt_sync_file_path) then
                -- sometimes the conversion is redundant (reason still unknown)
                sync_file_path = alt_sync_file_path
            else
                error(string.format("%s: %s", i18n "Can't find score file", sync_file_path))
            end
        end

        local data_str = FU:getStringFromFile(sync_file_path)
        if not data_str or data_str == '' then
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

return M