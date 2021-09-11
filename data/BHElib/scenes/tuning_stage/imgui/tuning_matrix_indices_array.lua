---------------------------------------------------------------------------------------------------
---tuning_matrix_indices_array.lua
---date created: 2021.9.10
---desc: Manages the reference indices of a matrix
---------------------------------------------------------------------------------------------------

---@class TuningMatrixIndicesArray
local M = LuaClass("TuningMatrixIndicesArray")

---------------------------------------------------------------------------------------------------
---init

function M.__create()
    return {
        indices = {0},
    }
end

function M:clone()
    local copy = M()
    copy.indices = table.deepcopy(self.indices)
    return copy
end

---------------------------------------------------------------------------------------------------

function M:onRemoveMatrix(matrix_index)
    local indices = self.indices
    for i = #indices, 1, -1 do
        local index = indices[i]
        if index == matrix_index then
            table.remove(indices, i)
        elseif index > matrix_index then
            indices[i] = index - 1
        end
    end
end

function M:appendBoss()
    local indices = self.indices
    indices[#indices + 1] = 0
end

function M:appendMouse()
    local indices = self.indices
    indices[#indices + 1] = -1
end

---@param index number a positive number indicating the index of the matrix
function M:appendMatrix(index)
    assert(index >= 1, "Error: Invalid index number!")
    local indices = self.indices
    indices[#indices + 1] = index
end

function M:removeIndex(i)
    table.remove(self.indices, i)
end

function M:getNumIndices()
    return #self.indices
end

function M:isBoss(i)
    return self.indices[i] == 0
end

function M:isMouse(i)
    return self.indices[i] == -1
end

function M:isMatrix(i)
    return self.indices[i] >= 1
end

function M:getMatrixIndex(i)
    assert(self.indices[i] >= 1, "Error: Attempt to get matrix index when the index type is non-matrix!")
    return self.indices[i]
end

---save the object to file at the current file cursor position
---@param file_writer SequentialFileWriter the object for writing to file
function M:writeToFile(file_writer)
    local indices = self.indices
    local num_indices = #indices
    if num_indices == 1 then
        file_writer:writeInt(indices[1])
    else
        file_writer:writeInt(-64)
        file_writer:writeUInt(num_indices)
        for j = 1, num_indices do
            file_writer:writeInt(indices[j])
        end
    end
end

---read the object from file at the current file cursor position
---@param file_reader SequentialFileReader the object for reading from file
function M:readFromFile(file_reader)
    local i = file_reader:readInt()
    local new_indices = {}
    if i == -64 then
        local num_indices = file_reader:readUInt()
        for j = 1, num_indices do
            local index = file_reader:readInt()
            new_indices[j] = index
        end
    else
        new_indices[1] = i
    end
    self.indices = new_indices
end

return M