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
local IndicesArray = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix_indices_array")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local StringByte = string.byte

---------------------------------------------------------------------------------------------------
---init

---@param tuning_ui TuningUI
function M:ctor(tuning_ui, matrix_title, ...)
    self.matrix = {
        {"s_script", "N/A", "nil"},
    }
    self.num_col = 3
    self.num_row = 1
    self.output_str = ""
    self.indices = IndicesArray()

    -- temporary state, no need to be saved/loaded
    self.tuning_ui = tuning_ui
    self.title = matrix_title
    self.cell_width = 90
    self:resetLocks()

    Widget.ctor(self, ...)
    self:addChild(function()
        self:_render()
    end)
end

function M:resetLocks()
    local locked_rows = {}
    for i = 1, self.num_row do
        locked_rows[i] = false
    end
    local locked_cols = {}
    for i = 1, self.num_col do
        locked_cols[i] = false
    end
    self.locked_rows = locked_rows
    self.locked_cols = locked_cols
end

---------------------------------------------------------------------------------------------------
---setters and getters

function M:setIndicesArray(indices)
    self.indices = indices
end

---@return TuningMatrixIndicesArray
function M:getIndicesArray()
    return self.indices
end

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
    self:resetLocks()
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

---@param index number insert row before this index
function M:insertRow(index)
    assert(index >= 1 and index <= self.num_row + 1, "Error: Insert row index out of range!")
    local n = self.num_row + 1
    self.num_row = n

    local row = {}
    row[1] = "label"
    for j = 2, self.num_col do
        row[j] = "0"
    end

    table.insert(self.matrix, index, row)
    table.insert(self.locked_rows, index, false)
end

---@param index number remove row at this index
function M:removeRow(index)
    local n = self.num_row - 1
    self.num_row = n

    table.remove(self.matrix, index)
    table.remove(self.locked_rows, index)
end

---@param index number insert column before this index
function M:insertColumn(index)
    assert(index >= MIN_COL_COUNT, "Error: The first two columns can not be inserted between!")
    assert(index <= self.num_col + 1, "Error: Insert column index out of range!")
    local n = self.num_col + 1
    self.num_col = n

    local matrix = self.matrix
    for i = 1, self.num_row do
        local row = matrix[i]
        local label = row[1]
        if label == "s_script" then
            table.insert(row, index, "nil")
        else
            table.insert(row, index, "0")
        end
    end
    table.insert(self.locked_cols, index, false)
end

---@param index number remove column at this index
function M:removeColumn(index)
    assert(index >= MIN_COL_COUNT, "Error: The first two columns can not be removed!")
    local n = self.num_col - 1
    self.num_col = n

    local matrix = self.matrix
    for i = 1, self.num_row do
        table.remove(matrix[i], index)
    end
    table.remove(self.locked_cols, index)
end

---------------------------------------------------------------------------------------------------
---imgui render

function M:renderResizeButtons()
    local ret
    ret = im.button("row+")
    if ret then
        self:insertRow(self.num_row + 1)
    end
    im.sameLine()
    ret = im.button("-##row-")
    if ret and self.num_row > MIN_ROW_COUNT then
        self:removeRow(self.num_row)
    end

    im.sameLine()

    ret = im.button("col+")
    if ret then
        self:insertColumn(self.num_col + 1)
    end
    im.sameLine()
    ret = im.button("-##col-")
    if ret and self.num_col > MIN_COL_COUNT then
        self:removeColumn(self.num_col)
    end
end

function M:_render()
    local remove_flag = false
    if im.beginMenuBar() then
        if im.beginMenu("Matrix") then
            if im.menuItem("Create Copy") then
                local MatrixSave = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix_save")
                local save = MatrixSave(self)
                self.tuning_ui:appendMatrixWindow(save, self.title.."_")
            end
            im.endMenu()
        end
        im.sameLine()
        if im.beginMenu("Del") then
            if im.menuItem("Confirm") then
                remove_flag = true
            end
            im.endMenu()
        end
        im.sameLine()

        if im.beginMenu("Parents") then
            local indices = self.indices
            local matrices = self.tuning_ui:getMatrices()
            local to_del = nil
            for i = 1, indices:getNumIndices() do
                local title
                if indices:isMatrix(i) then
                    local matrix = matrices[indices:getMatrixIndex(i)]
                    title = matrix.title
                elseif indices:isBoss(i) then
                    title = "Boss"
                elseif indices:isMouse(i) then
                    title = "Mouse"
                end

                if im.beginMenu(title.."##"..tostring(i)) then
                    if im.menuItem("Confirm Deletion") then
                        to_del = i
                    end
                    im.endMenu()
                end
            end

            if im.beginMenu("Add Parent") then
                if im.menuItem("Boss") then
                    indices:appendBoss()
                end
                if im.menuItem("Mouse") then
                    indices:appendMouse()
                end
                for i = 1, #matrices do
                    local title = matrices[i].title
                    if im.menuItem(title) then
                        indices:appendMatrix(i)
                    end
                end
                im.endMenu()
            end

            if to_del then
                indices:removeIndex(to_del)
            end

            im.endMenu()
        end
        im.endMenuBar()
    end

    im.setWindowFontScale(1.2)
    im.separator()
    self:renderResizeButtons()

    local cell_width = self.cell_width
    local matrix = self.matrix
    local to_insert = nil
    local to_remove = nil
    for i = 1, self.num_row do
        local row = matrix[i]
        for j = 1, self.num_col do
            local label = "##i"..i.."_"..j
            im.setNextItemWidth(cell_width)

            local is_locked = self.locked_rows[i] or self.locked_cols[j]
            if is_locked then
                im.pushStyleColor(im.Col.Text, im.vec4(220/255, 220/255, 220/255, 1.0))
                im.pushStyleColor(im.Col.FrameBg, im.vec4(60/255, 60/255, 60/255, 1.0))
            end

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

            if is_locked then
                im.popStyleColor(2)
            end
            im.sameLine()
        end

        local is_pressed = im.button("before+##row"..i.."+")
        if is_pressed then
            to_insert = i
        end
        im.sameLine()
        is_pressed = im.button("-##row"..i.."-")
        if is_pressed then
            to_remove = i
        end

        im.sameLine()
        local is_locked = self.locked_rows[i] == true
        local name = "lock"
        if is_locked then
            name = "unlock"
        end
        is_pressed = im.button(name.."##lock_row"..i, im.vec2(cell_width, 24))
        if is_pressed then
            self.locked_rows[i] = not is_locked
        end
    end
    if to_insert then
        self:insertRow(to_insert)
    elseif to_remove then
        self:removeRow(to_remove)
    end

    local pressed = im.button("output control", im.vec2(cell_width * 2 + 8, 24))
    if pressed then
        ---@type tuning_ui.EditText
        self.tuning_ui:createEditCode(self, self.output_str, "Output Control")
    end
    im.sameLine()

    to_insert = nil
    to_remove = nil
    local button1_width = cell_width * 0.8 - 4
    local button2_width = cell_width * 0.2 - 4
    for i = 3, self.num_col do
        local is_pressed = im.button("before+##col"..i.."+", im.vec2(button1_width, 24))
        if is_pressed then
            to_insert = i
        end
        im.sameLine()
        is_pressed = im.button("-##col"..i.."-", im.vec2(button2_width, 24))
        if is_pressed then
            to_remove = i
        end
        if i ~= self.num_col then
            im.sameLine()
        end
    end
    for i = 1, self.num_col do
        if i ~= 1 then
            im.sameLine()
        end
        local is_locked = self.locked_cols[i] == true
        local name = "lock"
        if is_locked then
            name = "unlock"
        end
        local is_pressed = im.button(name.."##lock_col"..i, im.vec2(cell_width, 24))
        if is_pressed then
            self.locked_cols[i] = not is_locked
        end
    end

    if to_insert then
        self:insertColumn(to_insert)
    elseif to_remove then
        self:removeColumn(to_remove)
    end

    -- after render all other things
    if remove_flag then
        self.tuning_ui:removeMatrixWindow(self)
    end
end

function M:onEditCodeSave(str)
    self.output_str = str
end

return M