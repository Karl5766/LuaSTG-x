---------------------------------------------------------------------------------------------------
---tuning_matrix.lua
---author: Karl
---date: 2021.8.29
---reference: src/imgui/ui/Console.lua
---desc: Defines a matrix ui for tuning parameter matrices
---------------------------------------------------------------------------------------------------

local Widget = require('imgui.Widget')

---@class im.TuningMatrix:im.Widget
local M = LuaClass("im.TuningMatrix", Widget)

local MIN_ROW_COUNT = 1
local MIN_COL_COUNT = 3

---------------------------------------------------------------------------------------------------

local im = imgui

---------------------------------------------------------------------------------------------------
---cache variables and functions

local StringByte = string.byte

---------------------------------------------------------------------------------------------------
---init

---@param tuning_ui TuningUI
function M:ctor(tuning_ui, ...)
    self.matrix = {
        {"s_script", "N/A", "nil"},
    }
    self.num_col = 3
    self.num_row = 1
    self.cell_width = 60
    self.output_str = ""
    self.tuning_ui = tuning_ui

    Widget.ctor(self, ...)
    self:addChild(function()
        self:_render()
    end)
end

---------------------------------------------------------------------------------------------------
---setters and getters

---copy values from the input matrix to self.matrix
---@param matrix table entries can be only strings or have nil, numbers that can be turned to strings
function M:copyFromMatrix(matrix)
    local target_matrix = self.matrix
    for i = 1, min(#matrix, self.num_row) do
        local row = matrix[i]
        local target_row = target_matrix[i]
        local row_label = row[1]

        assert(type(row_label) == "string",
                "Error: matrix labels should be strings! got "..tostring(row_label).." instead.")
        for j = 1, min(#row, self.num_col) do
            if j == 2 and StringByte(row_label, 2) == 95 then
                target_row[j] = "N/A"
            else
                target_row[j] = tostring(row[j])
            end
        end
        if self.num_col > #row then
            if row_label == "s_script" then
                for j = #row + 1, self.num_col do
                    target_row[j] = "nil"
                end
            else
                for j = #row + 1, self.num_col do
                    target_row[j] = "0"
                end
            end
        end
    end
end

---@param num_row number
---@param num_col number
function M:resizeTo(num_row, num_col)
    assert(num_row >= 1 and num_col >= 2, "Error: Invalid matrix size!")
    self.num_col = num_col
    self.num_row = num_row

    local matrix = self.matrix
    local new_matrix = {}

    for i = 1, num_row do
        local row = {}
        row[1] = "label"
        for j = 2, num_col do
            row[j] = "0"
        end

        new_matrix[i] = row
    end

    self.matrix = new_matrix
    self:copyFromMatrix(matrix)  -- copy from the old matrix
end

---@param i number row number
---@param str string the string to set to
function M:setRowLabel(i, str)
    local row = self.matrix[i]
    row[1] = str
    if StringByte(str, 2) == 95 then
        row[2] = "N/A"
    else
        if row[2] == "N/A" then
            row[2] = "0"
        end
    end

end

---------------------------------------------------------------------------------------------------
---imgui render

function M:renderResizeButtons()
    local ret = im.button("-row")
    if ret then
        if self.num_row > MIN_ROW_COUNT then
            self:resizeTo(self.num_row - 1, self.num_col)
        end
    end
    im.sameLine()
    ret = im.button("+row")
    if ret then
        self:resizeTo(self.num_row + 1, self.num_col)
    end
    im.sameLine()
    ret = im.button("-col")
    if ret then
        if self.num_col > MIN_COL_COUNT then
            self:resizeTo(self.num_row, self.num_col - 1)
        end
    end
    im.sameLine()
    ret = im.button("+col")
    if ret then
        self:resizeTo(self.num_row, self.num_col + 1)
    end
end

function M:_render()
    im.setWindowFontScale(1.2)
    im.separator()
    self:renderResizeButtons()

    local pressed = im.button("output control")
    if pressed then
        ---@type tuning_ui.EditText
        self.tuning_ui:createEditCode(self, self.output_str)
    end

    local matrix = self.matrix
    local cell_width = self.cell_width
    for i = 1, self.num_row do
        local row = matrix[i]
        for j = 1, self.num_col do
            local label = "##i"..i.."_"..j
            im.setNextItemWidth(cell_width)

            local text = row[j]

            if j == 1 then
                local changed, str = im.inputText(label, text, im.ImGuiInputTextFlags.EnterReturnsTrue)
                if changed then
                    self:setRowLabel(i, str)
                end
            else
                local changed, str = im.inputText(label, text, im.ImGuiInputTextFlags.None)
                if changed then
                    if j == 2 then
                        local row_label = row[1]
                        if StringByte(row_label, 2) == 95 then
                            -- do nothing
                        else
                            row[j] = str
                        end
                    else
                        row[j] = str
                    end
                end
            end

            if j ~= self.num_col then
                im.sameLine()
            end
        end
    end
end

function M:onEditCodeSave(str)
    self.output_str = str
end

---------------------------------------------------------------------------------------------------

function M.createWindow(...)
    local ret = require('imgui.widgets.Window')(...)
    ret:addChild(M())
    return ret
end

return M