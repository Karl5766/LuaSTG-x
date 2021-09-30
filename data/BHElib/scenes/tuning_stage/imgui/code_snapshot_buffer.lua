---------------------------------------------------------------------------------------------------
---code_snapshot_buffer.lua
---author: Karl
---date: 2021.9.29
---desc: Defines code snapshots. Code snapshots are large string fields that can be either 1)
---     edited through an imgui EditText interface or modified from a text file at disk (presumably
---     through an IDE like Intellij);
---     the entire string will be copied to save file on a save, and when load the string will be
---     synced to the disk
---     Note there is a distinction between sync file and save file, the former are for modification
---     purposes and contains only the code snapshot, the latter is a save file about all the data
---     present in the ui that need to be saved, not just this buffer.
---------------------------------------------------------------------------------------------------

---@class CodeSnapshotBuffer
local M = LuaClass("CodeSnapshotBuffer")

---------------------------------------------------------------------------------------------------
---init

---@param tuning_ui TuningUI
---@param title string
---@param file_path string the file on disk to sync from
function M.__create(tuning_ui, title, file_path)

    local self = {}

    self.str = ""
    self.is_sync = false

    self.title = title
    assert(file_path and type(file_path) == "string", "Error: file path must be valid string!")
    self.file_path = file_path
    self.tuning_ui = tuning_ui

    return self
end

---------------------------------------------------------------------------------------------------
---getter and setter

---@return string the string object currently hold by the object
function M:requestStr()
    if self.is_sync then
        local success, str = self:readSyncFileContent()
        if success then
            return str
        else
            return self.str
        end
    else
        return self.str
    end
end

function M:onEditCodeSave(str)
    if not self.is_sync then
        self.str = str
    end
end

function M:isSync()
    return self.is_sync
end

---@param is_sync boolean sync or unsync between object and disk file
function M:changeSync(is_sync)
    local prev_sync = self.is_sync
    if prev_sync == is_sync then
        return
    end

    if is_sync then
        -- start syncing, first copy current content to disk,
        -- then after that the buffer will copy string back on demand (may bypass self.str)
        self:syncToFile()
    else
        -- stop syncing, this will result in current file content brought from disk to buffer
        self:syncFromFile()
    end
    self.is_sync = is_sync
end

---------------------------------------------------------------------------------------------------
---sync file

function M:syncFromFile()
    local success, str = self:readSyncFileContent()
    if success then
        self.str = str
    else
        print("Error: Code snapshot buffer fails to read file!")
    end
end

function M:syncToFile()
    local success = self:writeSyncFileContent(self.str)
    if not success then
        print("Error: Code snapshot buffer fails to write to file!")
    end
end

---@return boolean,string success flag and result string
function M:readSyncFileContent()
    local str = io.readfile(self.file_path)
    if str then
        return true, str
    else
        return false, self.str
    end
end

---@return boolean success flag
function M:writeSyncFileContent(str)
    return io.writefile(self.file_path, str, "w+b")
end

---------------------------------------------------------------------------------------------------
---edit code

function M:openEditCode()
    self.tuning_ui:createEditCode(self, self.str, self.title)
end

---------------------------------------------------------------------------------------------------
---imgui

local im = imgui

function M:renderSyncButtons(cell_width)
    local prefix
    if self:isSync() then
        prefix = "Unsync "
    else
        prefix = "Sync "
    end

    if cell_width then
        local pressed = im.button(prefix..self.title, im.vec2(cell_width, 24))
        if pressed then
            self:changeSync(not self:isSync())
        end
    else
        local pressed = im.button(prefix..self.title)
        if pressed then
            self:changeSync(not self:isSync())
        end
    end
end

function M:renderEditButtons()
    local pressed = im.button(self.title)
    if pressed then
        self:openEditCode()
    end
end

return M