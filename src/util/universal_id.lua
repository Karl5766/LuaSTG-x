---------------------------------------------------------------------------------------------------
---universal_id.lua
---author: Karl
---date: 2021.4.13
---desc: Defines a table that can be used to store object and specify a unique string id as
---     retrieval key
---------------------------------------------------------------------------------------------------

local Uid = {}

---a table for referencing objects with unique string ids
local _all_stored_items = {}

---store an object to the table; the id provided should not conflict with any previously specified id
---@param item any the object to be stored
---@param item_id string id of the item to be found
function Uid:store(item, item_id)
    if _all_stored_items[item_id] then
        error("item id "..item_id.." already exists!")
    end
    _all_stored_items[item_id] = item
end

---return the item with the given unique id
---@param item_id string id of the item to be found
---@return any the stored object
function Uid:getById(item_id)
    assert(item_id, "item id parameter is nil")
    local item = _all_stored_items[item_id]
    assert(item, "item id "..item_id.." does not exist.")
    return _all_stored_items[item_id]
end

return Uid