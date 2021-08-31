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

---------------------------------------------------------------------------------------------------

local im = imgui
local Remove = table.remove

---------------------------------------------------------------------------------------------------
---init

---@param tuning_ui TuningUI
function M:ctor(tuning_ui, ...)
    self.tuning_ui = tuning_ui

    self.num_locals = 0
    self.name_width = 60
    self.value_width = 180
    self.local_names = {}
    self.local_values = {}

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
    local ret = im.button("-matrix")
    if ret then
        local n = self.tuning_ui:getNumMatrices()
        if n >= 1 then
            self.tuning_ui:popMatrixWindow()
        end
    end
    im.sameLine()
    ret = im.button("+matrixStandardAcc")
    if ret then
        self.tuning_ui:appendMatrixWindow(InitTuningMatrixSaves.StandardAcc)
    end
    im.sameLine()
    ret = im.button("+local")
    if ret then
        self:appendLocal()
    end
end

function M:_render()
    im.setWindowFontScale(1.2)
    im.separator()
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