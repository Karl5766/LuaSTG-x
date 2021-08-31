---------------------------------------------------------------------------------------------------
---desc: Manages saving and loading of a tuning matrix
---------------------------------------------------------------------------------------------------

---@class TuningMatrixSave
local M = LuaClass("TuningMatrixSave")

---------------------------------------------------------------------------------------------------

local StringByte = string.byte

---------------------------------------------------------------------------------------------------
---init

---@param matrix im.TuningMatrix
function M.__create(matrix)

    local self
    if matrix then
        self = {
            num_row = matrix.num_row,
            num_col = matrix.num_col,
            matrix = table.deepcopy(matrix.matrix),
            output_str = matrix.output_str
        }
    else
        self = {}  -- needs to be filled manually
    end
    return self
end

---------------------------------------------------------------------------------------------------
---interfaces

function M:writeBack(matrix)
    matrix.num_row = self.num_row
    matrix.num_col = self.num_col
    matrix.matrix = table.deepcopy(self.matrix)
    matrix.output_str = self.output_str
end

---get string representation of the matrix in lua code
---@return string a representation of the matrix
function M:getMatrixLuaString()
    local ret = tostring(self.num_row)..","..tostring(self.num_col)..",".."{\n"

    local matrix = self.matrix
    -- append string row by row
    for i = 1, self.num_row do
        local row = matrix[i]
        local row_label = row[1]
        local row_str = "{"

        for j = 1, self.num_col do
            local str
            if j == 1 then
                str = "\""..row[j].."\""
            elseif j == 2 and StringByte(row_label, 2) == 95 then
                str = "nil"
            else
                str = row[j]
            end
            if str ~= "nil" and row_label == "s_script" and j >= 2 then
                row_str = row_str..("{"..str.."},")
            else
                row_str = row_str..(str..",")
            end
        end

        row_str = row_str.."},\n"
        ret = ret..row_str
    end

    ret = ret.."}"

    return ret
end

function M:getLuaString()
    local matrix_str = self:getMatrixLuaString()
    local ret = matrix_str.."\n"..self.output_str
    return ret
end

return M