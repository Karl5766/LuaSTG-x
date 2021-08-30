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

---------------------------------------------------------------------------------------------------

local function NonPropagateCopy(matrix, row, var_name)
    for i = 1, #row - 2 do
        local column = matrix[i]
        column[var_name] = row[i + 2]
    end
end

local function PropagateCopy(chain, row, var_name)
    local d_name = "d_"..var_name
    chain[1][var_name] = row[2]
    for i = 1, #row - 2 do
        local node = chain[i]
        node[d_name] = row[i + 2]
    end
end

local function NonPropagatePackList(chain, row, var_name)
    for i = 1, #row - 1 do
        local node = chain[i]

        local value = row[i + 1]
        assert(type(value) == "table" or type(value) == "nil", "Error: type is "..type(value).."!")

        node[var_name] = value
    end
end

local _special_var_lookup = {
    s_script = NonPropagatePackList
}

---@return table a table with .head set to the first column of the matrix
function M.MatrixInit(master, num_row, num_col, matrix, output_column)
    local chain = {}
    for i = 1, num_col do
        chain[i] = ParameterColumn(master, "matrix_unit", nil)
        if i > 1 then
            chain[i - 1]:set_next_list({chain[i]})
        end
    end

    for i = 1, #matrix do
        local row = matrix[i]
        local var_name = row[1]

        local callback = _special_var_lookup[var_name]
        if callback then
            callback(chain, row, var_name)
        else
            assert(num_col >= #row - 1)
            if StringByte(var_name, 2) ~= 95 then
                -- propagate variable
                PropagateCopy(chain, row, var_name)
            else
                -- non-propagate variable
                NonPropagateCopy(chain, row, var_name)
            end
        end
    end

    chain[#chain]:add(output_column)
    chain.head = chain[1]

    return chain
end

function M.GetChain(master, output_column)
    local center_at = ColumnScripts.default_center_at
    local ran_on_circle = ColumnScripts.ConstructSetRandomOnCircle("tx", "ty", 32)
    local offset = ColumnScripts.ConstructOffset("x", "y", "tx", "ty")
    local test_matrix = {
        {"s_script", nil, {ran_on_circle}, nil, {center_at, offset}},
        {"s_n", nil, INFINITE, 12, 7},
        {"s_dt", nil, 2, 0, 3},
        {"x", 0, 0, 30, 1},
        {"y", 0, 0, 0, 0},
        {"vx", 0, 0, 0, 0},
        {"vy", 3, 0, 0, 0.5},
    }
    local chain = M.MatrixInit(master, test_matrix, output_column)

    return chain
end

return M