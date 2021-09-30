---------------------------------------------------------------------------------------------------
---code_snapshot_buffer_save.lua
---author: Karl
---date: 2021.9.29
---desc:
---------------------------------------------------------------------------------------------------

---@class CodeSnapshotBufferSave
local M = LuaClass("CodeSnapshotBufferSave")

---------------------------------------------------------------------------------------------------
---init

---@param buffer CodeSnapshotBuffer
function M.__create(buffer)

    local self = {}

    if buffer then
        self.str = buffer:requestStr()
        self.is_sync = buffer.is_sync
    else
        -- need to be filled manually after init
    end

    return self
end

function M.shortInit(file_path)
    local save = M()
    local str = io.readfile(file_path)
    assert(str, "Error: Cannot load file from "..file_path.."!")
    save.str = str
    save.is_sync = true
    return save
end

---------------------------------------------------------------------------------------------------
---save file handling

---@param buffer CodeSnapshotBuffer
function M:writeBack(buffer)
    buffer.str = self.str
    buffer.is_sync = false
    buffer:changeSync(true)
end

---save the object to file at the current file cursor position
---@param file_writer SequentialFileWriter the object for writing to file
function M:writeToFile(file_writer)
    file_writer:writeVarLengthString(self.str)

    -- record sync status
    if self.is_sync then
        file_writer:writeUInt(1)
    else
        file_writer:writeUInt(0)
    end
end

---read the object from file at the current file cursor position
---@param file_reader SequentialFileReader the object for reading from file
function M:readFromFile(file_reader)
    self.str, self.is_sync = file_reader:readVarLengthString(), file_reader:readUInt() == 1
end

return M