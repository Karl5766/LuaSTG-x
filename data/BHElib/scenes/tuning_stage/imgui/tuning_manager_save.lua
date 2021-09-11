---------------------------------------------------------------------------------------------------
---desc: Manages saving and loading of a tuning manager
---------------------------------------------------------------------------------------------------

---@class TuningManagerSave
local M = LuaClass("TuningManagerSave")

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
            boss_fire_flag = manager.boss_fire_flag,
            file_name_prefix = manager.file_name_prefix,
            context_str = manager.context_str,
        }
    else
        self = {
            boss_fire_flag = true,
            file_name_prefix = "Matrix",
        }  -- need to be manually filled
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
    manager.boss_fire_flag = self.boss_fire_flag
    manager.file_name_prefix = self.file_name_prefix
    manager.context_str = self.context_str
end

---save the object to file at the current file cursor position
---@param file_writer SequentialFileWriter the object for writing to file
function M:writeToFile(file_writer)
    file_writer:writeUInt(self.num_locals)
    file_writer:writeVarLengthStringArray(self.local_names)
    file_writer:writeVarLengthStringArray(self.local_values)
    if self.boss_fire_flag then
        file_writer:writeByte(1)
    else
        file_writer:writeByte(0)
    end
    file_writer:writeVarLengthString(self.file_name_prefix)
    file_writer:writeVarLengthString(self.context_str)
end

---read the object from file at the current file cursor position
---@param file_reader SequentialFileReader the object for reading from file
function M:readFromFile(file_reader)
    self.num_locals = file_reader:readUInt()
    self.local_names = file_reader:readVarLengthStringArray()
    self.local_values = file_reader:readVarLengthStringArray()
    self.boss_fire_flag = file_reader:readByte() == 1
    self.file_name_prefix = file_reader:readVarLengthString()
    self.context_str = file_reader:readVarLengthString()
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

    local ret = "\n"  -- separates the context string and the locals

    for i = 1, self.num_locals do
        ret = ret..("local "..local_names[i].."="..local_values[i].."\n")
    end

    return self.context_str..ret
end

return M