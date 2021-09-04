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

local function NoDCopy(matrix, num_col, row, var_name)
    for i = 1, num_col - 2 do
        local column = matrix[i]
        column[var_name] = row[i + 2]
    end
end

local function DCopy(chain, num_col, row, var_name)
    local d_name = "d_"..var_name
    chain[1][var_name] = row[2]
    for i = 1, num_col - 2 do
        local node = chain[i]
        node[d_name] = row[i + 2]
    end
end

local function ScriptCopy(chain, num_col, row, var_name)
    for i = 1, num_col - 1 do
        local node = chain[i]

        local value = row[i + 1]
        assert(type(value) == "table" or type(value) == "nil", "Error: type is "..type(value).."!")

        node[var_name] = value
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
            callback(chain, num_col, row, var_name)
        else
            assert(num_col >= #row - 1)
            if StringByte(var_name, 2) ~= 95 then
                -- d variable
                DCopy(chain, num_col, row, var_name)
            else
                -- no-d variable
                NoDCopy(chain, num_col, row, var_name)
            end
        end
    end

    chain[#chain]:add(output_column)
    chain.head = chain[1]
    chain.output_column = output_column
    chain.sparkAll = ChainSparkAll

    return chain
end

return M