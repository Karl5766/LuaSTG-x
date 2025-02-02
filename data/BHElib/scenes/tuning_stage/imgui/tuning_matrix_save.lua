---------------------------------------------------------------------------------------------------
---desc: Manages saving and loading of a tuning matrix
---------------------------------------------------------------------------------------------------

---@class TuningMatrixSave
local M = LuaClass("TuningMatrixSave")

---------------------------------------------------------------------------------------------------

local JsonFileMirror = require("file_system.json_file_mirror")
local IndicesArray = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix_indices_array")
local CodeSnapshotBufferSave = require("BHElib.scenes.tuning_stage.imgui.code_snapshot_buffer_save")

---------------------------------------------------------------------------------------------------
---cache variables and functions

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
            output_control_save = CodeSnapshotBufferSave(matrix.output_control),
            indices = matrix:getIndicesArray():clone(),
            matrix_title = matrix.matrix_title,
            tail_script = matrix.tail_script
        }
    else
        self = {
            indices = IndicesArray(),
            output_control_save = CodeSnapshotBufferSave(),
        }  -- needs to be filled manually
    end
    return self
end

---------------------------------------------------------------------------------------------------
---interfaces

---@param matrix im.TuningMatrix
function M:writeBack(matrix)
    matrix.num_row = self.num_row
    matrix.num_col = self.num_col
    matrix.matrix = table.deepcopy(self.matrix)
    self.output_control_save:writeBack(matrix.output_control)
    matrix:setIndicesArray(self.indices:clone())
    matrix.matrix_title = self.matrix_title
    matrix.tail_script = self.tail_script
end

---save the object to file at the current file cursor position
---@param file_writer SequentialFileWriter the object for writing to file
function M:writeToFile(file_writer)
    file_writer:writeUInt(self.num_row)
    file_writer:writeUInt(self.num_col)
    file_writer:writeVarLengthString(JsonFileMirror.turnLuaObjectToString(self.matrix))
    self.indices:writeToFile(file_writer)
    file_writer:writeVarLengthString(self.matrix_title)
    file_writer:writeVarLengthString(self.tail_script)
    self.output_control_save:writeToFile(file_writer)
end

---read the object from file at the current file cursor position
---@param file_reader SequentialFileReader the object for reading from file
function M:readFromFile(file_reader)
    self.num_row = file_reader:readUInt()
    self.num_col = file_reader:readUInt()
    self.matrix = JsonFileMirror.turnStringToLuaObject(file_reader:readVarLengthString())
    local indices = IndicesArray()
    indices:readFromFile(file_reader)
    self.indices = indices
    self.matrix_title = file_reader:readVarLengthString()
    self.tail_script = file_reader:readVarLengthString()
    self.output_control_save:readFromFile(file_reader)
end

---@param str string the intermediate string field representation
local function GetTableForCommaSeparatedField(str, row_label)

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
        local is_incrementable = StringByte(row_label, 2) ~= 95
        local is_script = row_label == "s_script"

        for j = 1, self.num_col do
            local str

            -- deal with default values first
            -- default value is used only if a value is not provided
            -- otherwise use the provided value
            local input_str = row[j]
            if input_str ~= "" and (is_incrementable or j ~= 2) then
                -- use provided
                str = input_str

                -- now handle case by case:
                -- label field - add quotes
                -- second column - no need to do anything
                -- s_script field - put in brackets; need to take tail script into consideration
                -- other fields - put in brackets
                if j == 1 then
                    str = "\""..row[j].."\""
                elseif j >= 3 then
                    if j == self.num_col and is_script then
                        -- dealt with in the code below
                    else
                        str = "{"..str.."}"
                    end
                end
            else
                -- use default
                str = "nil"
                if (j == 2 and is_incrementable) or (j >= 3 and not is_script) then
                    str = "0"
                end
            end

            if j == self.num_col and is_script then
                local tail_script = self.tail_script
                if str == "nil" then
                    str = "{"..tail_script.."}"
                else
                    str = "{"..str..","..tail_script.."}"
                end
            end

            row_str = row_str..(str..",")
        end

        row_str = row_str.."},\n"
        ret = ret..row_str
    end

    ret = ret.."}"

    return ret
end

function M:getLuaString()
    local matrix_str = self:getMatrixLuaString()
    local ret = matrix_str.."\n"..(self.output_control_save.str)
    return ret
end

function M:getIndices()
    return self.indices
end

return M