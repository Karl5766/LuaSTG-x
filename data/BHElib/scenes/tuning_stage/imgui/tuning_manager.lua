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
local FS = require("file_system.file_system")

---------------------------------------------------------------------------------------------------

local im = imgui
local Remove = table.remove

---------------------------------------------------------------------------------------------------
---init

---@param tuning_ui TuningUI
function M:ctor(tuning_ui, ...)
    self.tuning_ui = tuning_ui

    self.num_locals = 0
    self.local_names = {}
    self.local_values = {}
    self.boss_fire_flag = true

    self.name_width = 180
    self.value_width = 210

    Widget.ctor(self, ...)
    self:addChild(function()
        self:_render()
    end)
end

---------------------------------------------------------------------------------------------------
---interfaces

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
    local ret = im.button("+local")
    if ret then
        self:appendLocal()
    end

    self:renderAddMatrixButtons()
    self:renderLoadManagerButtons()
end

function M:renderAddMatrixButtons()
    for key_str, matrix_save in pairs(InitTuningMatrixSaves) do
        local ret = im.button("+matrix"..key_str)
        if ret then
            self.tuning_ui:appendMatrixWindow(matrix_save, key_str)
        end
    end
end

function M:renderLoadManagerButtons()
    for key_str, manager_save in pairs(InitTuningManagerSaves) do
        local ret = im.button("local"..key_str)
        if ret then
            manager_save:writeBack(self)
        end
    end
end

local _backup_dir = "data/BHElib/scenes/tuning_stage/backups/"

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
            local file_info = FS.getBriefOfFilesInDirectory(_backup_dir)
            local file_names = {}
            for _, item in ipairs(file_info) do
                if not item.isDirectory then
                    file_names[#file_names + 1] = item.name
                end
            end
            for i = 1, #file_names do
                local file_name = file_names[i]
                if im.menuItem(file_name) then
                    self.tuning_ui:loadBackup(_backup_dir..file_name)
                end
            end
            if #file_names > 0 and im.menuItem("move backups to storage") then
                for i = 1, #file_names do
                    local file_name = file_names[i]
                    os.rename(_backup_dir..file_name, _backup_dir.."storage/"..file_name)
                end
            end
            im.endMenu()
        end
        if im.beginMenu("Save Backup") then
            if im.menuItem("Confirm") then
                local file_name = os.date("%Y_%m_%d_%H_%M_%S.bak")
                self.tuning_ui:saveBackup(_backup_dir..file_name)
            end
            im.endMenu()
        end
        im.endMenuBar()
    end

    im.separator()

    do
        local changed, value = im.checkbox("boss fire", self.boss_fire_flag)
        if changed then
            self.boss_fire_flag = value
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

---------------------------------------------------------------------------------------------------

function M.createWindow(...)
    local ret = require('imgui.widgets.Window')(...)
    ret:addChild(M())
    return ret
end

return M