---------------------------------------------------------------------------------------------------
---menu_page_array.lua
---author: Karl
---date: 2021.4.26
---desc: Defines an object consists of menu pages; each item of the array is an array of three
---     elements, namely {menu_class_id, menu_page, choices}, where the third element is the
---     choices made in that menu
---------------------------------------------------------------------------------------------------

---@class MenuPageArray
local MenuPageArray = LuaClass("menu.MenuPageArray")

local Ustorage = require("util.universal_id")

---------------------------------------------------------------------------------------------------
---interface

---MenuPageArray() -> MenuPageArray object
---append(class_id, menu) -> number, index of the new item
---pop() -> {class_id, menu, choices}
---set_choice(i, key, value)
---get_choice(i, key) -> value
---query_choice(key) -> i, value
---set_menu(i, menu)
---get_menu(i) -> Menu object
---get_menu_class(i) -> LuaClass
---get_size()

---------------------------------------------------------------------------------------------------

function MenuPageArray.__create()
    local self = {}
    self.size = 0
end

---@return number size of the array
function MenuPageArray:get_size()
    return self.size
end

---add a new menu page record to the end of the array
---@param class_id string id of the menu page class
---@param menu MenuPage the menu page to add
function MenuPageArray:append(class_id, menu)
    local size = self.size + 1
    self[size] = {class_id, menu, {}}
end

---pop the back of the array
---@return table an entry of the array
function MenuPageArray:append(class_id, menu)
    local size = self.size
    local item = self[size]
    self[size] = nil
    self.size = size - 1

    return item
end

---remember a choice that is made
---@param i number index of the menu page in the array
---@param key string key for retrieval
---@param choice any data to be stored
function MenuPageArray:set_choice(i, key, choice)
    local choices = self[i][3]
    choices[key] = choice
end

---retrieve a choice that is remembered
---@param i number index of the menu page in the array
---@param key string key for retrieval
---@return any data stored with the given key
function MenuPageArray:get_choice(i, key)
    local choices = self[i][3]
    return choices[key]
end

---retrieve the closest-to-the-end choice that is non-nil with the given key
---@param key string key for retrieval
---@return any data stored with the given key
function MenuPageArray:query_choice(key)
    for i = self.size, 1, -1 do
        local choices = self[i][3]
        local choice = choices[key]
        if choice ~= nil then
            return choice
        end
    end
    return nil
end

---update the ith menu page
---@param i number index of the menu page
---@param menu_page MenuPage the menu page to set to; can be nil
function MenuPageArray:set_menu(i, menu_page)
    self[i][2] = menu_page
end

---get the ith menu page
---@param i number index of the menu page
---@return MenuPage the menu page with the given index
function MenuPageArray:get_menu(i)
    return self[i][2]
end

---get the class of the menu page
---@param i number index of the menu page
---@return table the class of the menu page with the given index
function MenuPageArray:get_menu_class(i)
    local class_id = self[i][1]
    return Ustorage:getById(class_id)
end

return MenuPageArray