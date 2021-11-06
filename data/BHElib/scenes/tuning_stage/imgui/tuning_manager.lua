---------------------------------------------------------------------------------------------------
---tuning_manager.lua
---author: Karl
---date: 2021.8.29
---reference: src/imgui/ui/Console.lua
---desc: Defines a ui that manages the matrices and the lua code context of the matrices
---------------------------------------------------------------------------------------------------

local Widget = require('imgui.Widget')

---@class im.TuningManager:im.Widget
local M = LuaClass("im.TuningManager", Widget)

---------------------------------------------------------------------------------------------------

local InitTuningMatrixSaves = require("BHElib.scenes.tuning_stage.imgui.init_tuning_matrix_saves")
local InitTuningManagerSaves = require("BHElib.scenes.tuning_stage.imgui.init_tuning_manager_saves")
local CodeSnapshotBuffer = require("BHElib.scenes.tuning_stage.imgui.code_snapshot_buffer")
local FS = require("file_system.file_system")

---------------------------------------------------------------------------------------------------

local im = imgui
local Remove = table.remove

---------------------------------------------------------------------------------------------------
---init

local _backup_dir = "data/BHElib/scenes/tuning_stage/backups/"

---@param tuning_ui TuningUI
function M:ctor(tuning_ui, ...)
    self.tuning_ui = tuning_ui

    self.num_locals = 0
    self.local_names = {}
    self.local_values = {}
    self.boss_fire_flag = true
    self.file_name_suffix = ""

    self.backup_dir = _backup_dir
    self.name_width = 150
    self.value_width = 240

    -- context control
    self.context_control = CodeSnapshotBuffer(tuning_ui, "Context Control", self:getSyncFilePath())
    self.context_control:changeSync(true)

    if not FS.isFileExist(_backup_dir) then
        FS.createDirectory(_backup_dir)
    end

    Widget.ctor(self, ...)
    self:addChild(function()
        self:_render()
    end)
end

---------------------------------------------------------------------------------------------------
---interfaces

function M:getSyncFilePath()
    return "data/BHElib/scenes/tuning_stage/code/context_control.lua"
end

function M:appendLocal()
    local i = self.num_locals + 1
    self.num_locals = i
    self.local_names[i] = "var"
    self.local_values[i] = "0"
end

---@param index number the index of the local variable to remove
function M:removeLocal(index)
    local n = self.num_locals
    assert(1 <= index and index <= n, "Error: Index out of range!")

    Remove(self.local_names, index)
    Remove(self.local_values, index)
    self.num_locals = n - 1
end

---------------------------------------------------------------------------------------------------
---imgui render

function M:renderButtons()
    self:renderAddMatrixButtons()
end

function M:renderAddMatrixButtons()
    for key_str, matrix_save in pairs(InitTuningMatrixSaves) do
        local ret = im.button("+matrix"..key_str)
        if ret then
            self.tuning_ui:appendMatrixWindow(matrix_save, matrix_save.matrix_title)
        end
    end
end

--function M:renderLoadManagerButtons()
--    for key_str, manager_save in pairs(InitTuningManagerSaves) do
--        local ret = im.button("local"..key_str)
--        if ret then
--            manager_save:writeBack(self)
--        end
--    end
--end

---@param dir_path string the path where backups are located
function M:renderLoadBackupMenu(dir_path)
    local file_info = FS.getBriefOfFilesInDirectory(dir_path)
    local dirs = {}
    local file_names = {}
    for _, item in ipairs(file_info) do
        if item.isDirectory then
            dirs[#dirs + 1] = item
        else
            file_names[#file_names + 1] = item.name
        end
    end
    for i = 1, #dirs do
        local dir = dirs[i]
        if im.beginMenu(dir.name.."##directory") then
            self:renderLoadBackupMenu(dir_path..dir.name.."/")
            im.endMenu()
        end
    end
    for i = 1, #file_names do
        local file_name = file_names[i]
        if im.beginMenu(file_name) then
            if im.menuItem("Replace") then
                self.tuning_ui:loadBackup(dir_path..file_name, 0)
            end
            if im.menuItem("Append Matrices") then
                self.tuning_ui:loadBackup(dir_path..file_name, 1)
            end
            if im.menuItem("Load Manager Save") then
                self.tuning_ui:loadBackup(dir_path..file_name, 2)
            end
            im.endMenu()
        end
    end
    if dir_path == _backup_dir and #file_names > 0 and im.menuItem("move backups to storage") then
        for i = 1, #file_names do
            local storage_path = dir_path.."storage/"
            if not FS.isFileExist(storage_path) then
                FS.createDirectory(storage_path)
            end
            local file_name = file_names[i]
            os.rename(dir_path..file_name, storage_path..file_name)
        end
    elseif dir_path == _backup_dir.."auto/" and im.beginMenu("Delete Automatic Backups") then
        if im.menuItem("Confirm") then
            for i = 1, #file_names do
                local file_name = file_names[i]
                os.remove(dir_path..file_name)
            end
        end
        im.endMenu()
    end
end

function M:_render()
    im.setWindowFontScale(1.1)

    if im.beginMenuBar() then
        if im.beginMenu("End Stage") then
            if im.menuItem("Confirm") then
                local Callbacks = require("BHElib.scenes.stage.stage_transition_callbacks")
                self.tuning_ui:callStageTransition(Callbacks.createMenuAndSaveReplay)
            end
            im.endMenu()
        end
        if im.beginMenu("Load Backup") then
            self:renderLoadBackupMenu(_backup_dir)
            im.endMenu()
        end
        if im.beginMenu("Save Backup") then
            if im.menuItem("Confirm") then
                local file_name = os.date("%Y%m%d_%H%M%S_")..self.file_name_suffix..".bak"
                self.tuning_ui:saveBackup(_backup_dir..file_name)
            end
            im.endMenu()
        end
        im.endMenuBar()
    end

    im.separator()

    do
        local ret = im.button("+local")
        if ret then
            self:appendLocal()
        end

        im.sameLine()

        local changed, value = im.checkbox("boss fire", self.boss_fire_flag)
        if changed then
            self.boss_fire_flag = value
        end

        im.sameLine()

        local control = self.context_control
        control:renderSyncButtons()
        if not control:isSync() then
            control:renderEditButtons()
        end

        local str
        im.setNextItemWidth(self.value_width - 30)
        changed, str = im.inputText("File Name", self.file_name_suffix)
        if changed then
            self.file_name_suffix = str
        end
    end

    self:renderButtons()

    local local_names = self.local_names
    local local_values = self.local_values
    local num_locals = self.num_locals
    local to_del = nil
    for i = 1, num_locals do
        im.setNextItemWidth(self.name_width)
        local changed, str = im.inputText("##name"..tostring(i), local_names[i], im.ImGuiInputTextFlags.None)
        if changed then
            local_names[i] = str
        end

        im.sameLine()

        im.setNextItemWidth(self.value_width)
        changed, str = im.inputText("##value"..tostring(i), local_values[i], im.ImGuiInputTextFlags.None)
        if changed then
            local_values[i] = str
        end

        im.sameLine()

        local pressed = im.button("-##btn"..i)
        if pressed then
            to_del = i
        end
    end
    if to_del then
        self:removeLocal(to_del)
    end
end

return M