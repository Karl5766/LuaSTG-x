---------------------------------------------------------------------------------------------------
---hot_iter.lua
---author: Karl
---date created: 2021.11.4
---desc: An iterator that allows changing parameter in a live setting; also handles some events
---------------------------------------------------------------------------------------------------

---@class HotIter
local M = LuaClass("HotIter")

---------------------------------------------------------------------------------------------------

local lstg_event_dispatcher = lstg.eventDispatcher
function M.ReloadOnChange(label)
    local function OnBroadcastReloadChains(iter, broadcast_label, value)
        if label == broadcast_label then
            lstg_event_dispatcher:dispatchEvent("reloadChains")
        end
    end
    return OnBroadcastReloadChains
end

---------------------------------------------------------------------------------------------------

function M.__create()
    local self = {}
    self.item_map = {}
    self.index_history = {}
    self.listeners = {}
    return self
end

---------------------------------------------------------------------------------------------------
---adding items and accessing data

function M:addItem(label, item)
    local item_map = self.item_map
    assert(item_map[label] == nil, "Error: Attempting to add the same label twice!")
    item_map[label] = item
    if self.index_history[label] then
        local index_history = self.index_history
        item.i = index_history[label].i or item.i
        item.j = index_history[label].j or item.j

        -- the history index may not be valid; in that case, reset them to 1
        local item_array = item.array or item.matrix
        if item.i > #item_array or item.i < 1 then
            item.i = 1
        end
        if item.j and (item.j > #item_array[item.i] or item.j < 1) then
            item.j = 1
        end
        index_history[label] = nil
    end
end

function M:addRegisterer(label, registerer)
    self.item_map[label].registerer = registerer
end

---@param label string an id identifying the array
---@param array table an array of element to iterate from
---@param listener table need to have a method called onBroadcast(iter, label, value)
function M:registerWithListener(label, array, listener, init_index)
    init_index = init_index or 1
    self:addItem(label, {
        dimension = 1,
        array = array,
        i = init_index,
    })
    if listener then
        self:addListener(listener)
    end
end

function M:register(label, array, init_index)
    self:registerWithListener(label, array, M.ReloadOnChange(label), init_index)
end

---@param label string an id identifying the array
---@param matrix table an array of element to iterate from
---@param listener table need to have a method called onBroadcast(iter, label, value)
function M:registerMatrixWithListener(label, matrix, listener, init_col, init_row)
    init_col = init_col or 1
    init_row = init_row or 1
    self:addItem(label, {
        dimension = 2,
        matrix = matrix,
        i = init_col,
        j = init_row,
    })
    if listener then
        self:addListener(listener)
    end
end

function M:registerMatrix(label, matrix, init_col, init_row)
    self:registerWithListener(label, matrix, M.ReloadOnChange(label), init_col, init_row)
end

function M:removeItem(label)
    self.item_map[label] = nil
end

function M:getValue(label)
    local item = self.item_map[label]
    if item.dimension == 1 then
        return item.array[item.i]
    else
        return item.matrix[item.i][item.j]
    end
end

function M:get(label)
    local item = self.item_map[label]
    if item.registerer then
        return item.registerer
    end
    return self:getValue(label)
end

---@param listener table need to have a method called onBroadcast(iter, label, value)
function M:addListener(listener)
    table.insert(self.listeners, listener)
end

---------------------------------------------------------------------------------------------------
---modification

---copy the index information from the previous iter
function M:inheritIndices(iter)
    local prev_item_map = iter.item_map
    local item_map = self.item_map
    for label, prev_item in pairs(prev_item_map) do
        local item = item_map[label]
        if item and item.dimension == prev_item.dimension then
            item.i = prev_item.i
            item.j = prev_item.j
        elseif item == nil then
            local index = {}
            index.i = prev_item.i
            index.j = prev_item.j
            self.index_history[label] = index
        end
    end
end

---whenever an index is changed, trigger an index change event
function M:broadcastChanges(label)
    local new_val = self:getValue(label)
    for i, listener in ipairs(self.listeners) do
        listener(self, label, new_val)
    end
end

---increment the index for the given label; only works on 1d array
function M:incIndex(label, inc_index)
    local item = self.item_map[label]
    local size = #item.array
    item.i = (item.i + inc_index - 1) % size + 1
    self:broadcastChanges(label)
end

---increment the index for the given label; only works on matrix
---increment on i applies first, then increment on j applies
---if some rows have different lengths, then when switching from longer row to shorter row
---the j index will be bounded right if out of range
function M:incIndexMatrix(label, inc_i, inc_j)
    local item = self.item_map[label]

    if inc_i ~= 0 then
        local num_row = #item.matrix
        local new_i = (item.i + inc_i - 1) % num_row + 1
        item.i = new_i
        local num_col = #(item.matrix[new_i])
        if item.j > num_col then
            item.j = num_col
        end
    end
    if inc_j ~= 0 then
        local num_col = #(item.matrix[item.i])
        item.j = (item.j + inc_j - 1) % num_col + 1
    end
    self:broadcastChanges(label)
end

---produce an array of sets of callbacks
---an 1d array will have 2 callbacks for (i -= 1, i += 1)
---a 2d matrix will have 4 callbacks for (i -= 1, i += 1, j -= 1, j += 1)
function M:getButtonCallbacks()
    -- order of access is not currently specified because there is no need
    local ret = {}
    for label, item in pairs(self.item_map) do
        local callbacks = {
            dimension = item.dimension,
            label = label,
        }
        if item.dimension == 1 then
            callbacks[1] = function() self:incIndex(label, -1) end
            callbacks[2] = function() self:incIndex(label, 1) end
        else
            callbacks[1] = function() self:incIndexMatrix(label, -1, 0) end
            callbacks[2] = function() self:incIndexMatrix(label, 1, 0) end
            callbacks[3] = function() self:incIndexMatrix(label, 0, -1) end
            callbacks[4] = function() self:incIndexMatrix(label, 0, 1) end
        end
        ret[#ret + 1] = callbacks
    end
    return ret
end

return M