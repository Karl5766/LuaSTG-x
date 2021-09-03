---------------------------------------------------------------------------------------------------
---desc: Manages saving and loading of a tuning manager
---------------------------------------------------------------------------------------------------

---@class TuningManagerSave
local M = LuaClass("TuningManagerSave")

---------------------------------------------------------------------------------------------------

local JsonFileMirror = require("file_system.json_file_mirror")

---------------------------------------------------------------------------------------------------
---init

---@param manager im.TuningManager
function M.__create(manager)
    local self
    if manager then
        self = {
            num_locals = manager.num_locals,
            local_names = table.deepcopy(manager.local_names),
            local_values = table.deepcopy(manager.local_values),
        }
    else
        self = {}  -- need to be manually filled
    end
    return self
end

---------------------------------------------------------------------------------------------------
---interfaces

---@param manager im.TuningManager
function M:writeBack(manager)
    manager.num_locals = self.num_locals
    manager.local_names = table.deepcopy(self.local_names)
    manager.local_values = table.deepcopy(self.local_values)
end

---save the object to file at the current file cursor position
---@param file_writer SequentialFileWriter the object for writing to file
function M:writeToFile(file_writer)
    file_writer:writeUInt(self.num_locals)
    file_writer:writeVarLengthStringArray(self.local_names)
    file_writer:writeVarLengthStringArray(self.local_values)
end

---read the object from file at the current file cursor position
---@param file_reader SequentialFileReader the object for reading from file
function M:readFromFile(file_reader)
    self.num_locals = file_reader:readUInt()
    self.local_names = file_reader:readVarLengthStringArray()
    self.local_values = file_reader:readVarLengthStringArray()
end

function M:loadLocalArray(locals)
    self.num_locals = #locals
    self.local_names = {}
    self.local_values = {}
    for i = 1, #locals do
        local name, value = unpack(locals[i])
        self.local_names[i] = name
        self.local_values[i] = value
    end
end

---@return string
function M:getLuaString()
    local local_names = self.local_names
    local local_values = self.local_values

    local ret = ""

    for i = 1, self.num_locals do
        ret = ret..("local "..local_names[i].."="..local_values[i].."\n")
    end

    return ret
end

return M