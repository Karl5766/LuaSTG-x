---------------------------------------------------------------------------------------------------
---ParameterMatrix.lua
---author: Karl
---date created: 2021.3.18
---desc: experimental parameter control method of using a matrix to store all information about a
---     pattern
---------------------------------------------------------------------------------------------------

---@class ParameterMatrix
local M = {}

local ParameterColumn = require("BHElib.scripts.linear_tuning.parameter_column")
local ColumnScripts = require("BHElib.scripts.linear_tuning.column_scripts")

---------------------------------------------------------------------------------------------------

local StringByte = string.byte
local type = type

---------------------------------------------------------------------------------------------------

local function CopyNumericalFieldItem(column, var_name, field, script_var_name)
    local field_type = type(field)
    if field_type == "number" then
        column[var_name] = field
    elseif field_type == "function" then
        column:addScript(field(script_var_name))
    else
        print("Error: Unrecognized matrix increment field type "..field_type.."!")
    end
end

---interpret input item; if it is a number then set d_var to that value;
---if it is a function then wrap it with var_name and add to column script
local function CopyNumericalField(matrix, var_name, entry_col_index, input_item, script_var_name)
    local column = matrix[entry_col_index]
    local input_item_type = type(input_item)
    if  input_item_type == "table" then
        for i = 1, #input_item do
            CopyNumericalFieldItem(column, var_name, input_item[i], script_var_name)
        end
    else
        CopyNumericalFieldItem(column, var_name, input_item, script_var_name)
    end
end

local function NoDCopy(matrix, num_columns, row, entry_row_name)
    for i = 1, num_columns do
        CopyNumericalField(matrix, entry_row_name, i, row[i + 2], entry_row_name)
    end
end

local function DCopy(matrix, num_columns, row, entry_row_name)
    local d_name = "d_"..entry_row_name
    matrix[1][entry_row_name] = row[2]
    for i = 1, num_columns do
        CopyNumericalField(matrix, d_name, i, row[i + 2], entry_row_name)
    end
end

local function ScriptCopy(chain, num_columns, row, var_name)
    for i = 1, num_columns do
        local column = chain[i]

        local value = row[i + 2]
        local value_type = type(value)
        assert(value_type == "table" or value_type == "nil",
                "Error: type is "..type(value).."!")

        if value_type == "table" then
            for i = 1, #value do
                local script = value[i]
                column:addScript(script)
            end
        end
    end
end

local _special_var_lookup = {
    s_script = ScriptCopy
}

function M.SetChainMaster(chain, master)
    for i, v in ipairs(chain) do
        v.s_master = master
    end
    chain.output_column.s_master = master
end

local function ChainSparkAll(self, master)
    M.SetChainMaster(self, master)
    self.head:spark()
end

---@return table a table with .head set to the first column of the matrix
function M.ChainInit(master, num_row, num_col, matrix, output_column)
    local chain = {}
    local num_columns = num_col - 2
    for i = 1, num_columns do
        chain[i] = ParameterColumn(master, "matrix_unit_"..i, nil)
        if i > 1 then
            chain[i - 1]:setNextList({chain[i]})
        end
    end

    ---increment fields and other fields go first
    for i = 1, #matrix do
        local row = matrix[i]
        local var_name = row[1]

        local callback = _special_var_lookup[var_name]
        if callback == nil then
            assert(num_columns >= #row - 2)
            if StringByte(var_name, 2) ~= 95 then
                -- d variable
                DCopy(chain, num_columns, row, var_name)
            else
                -- no-d variable
                NoDCopy(chain, num_columns, row, var_name)
            end
        end
    end

    ---then script fields go
    for i = 1, #matrix do
        local row = matrix[i]
        local var_name = row[1]

        local callback = _special_var_lookup[var_name]
        if callback then
            callback(chain, num_columns, row, var_name)
        end
    end

    chain[#chain]:add(output_column)
    chain.head = chain[1]
    chain.output_column = output_column
    chain.sparkAll = ChainSparkAll

    return chain
end

return M