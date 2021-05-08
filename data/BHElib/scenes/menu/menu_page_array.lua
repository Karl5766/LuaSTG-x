---------------------------------------------------------------------------------------------------
---menu_page_array.lua
---author: Karl
---date: 2021.4.26
---desc: Defines an object consists of menu pages; each item of the array is an array of three
---     elements, namely {menu_class_id, menu_page, choices}, where the third element is the
---     choices made in that menu; this is a strange class as every insert requires two separate
---     deletes (for two entries in array and in pool) to clean everything
---------------------------------------------------------------------------------------------------

---@class MenuPageArray
local MenuPageArray = LuaClass("menu.MenuPageArray")

---------------------------------------------------------------------------------------------------
---interface

---MenuPageArray() -> MenuPageArray object
---append(class_id, menu_id, menu) -> (number) position index of the new item
---pop() -> {class_id, menu_id, choices}
---setChoice(i, key, value)
---getChoice(i, key) -> value
---queryChoice(key, i) -> i, value
---setMenuId(i, menu_id)
---getMenuId(i) -> (string) id of the menu at the ith position
---getMenuClassId(i) -> LuaClass
---getSize()

---summary of what it does
---menu_pos -array[menu_pos]-> {class_id, menu_id, choices}

---------------------------------------------------------------------------------------------------

function MenuPageArray.__create()
    local self = {}
    self.size = 0
    return self
end

---@return number size of the array
function MenuPageArray:getSize()
    return self.size
end

---add a new menu page to the end of the array
---@param class_id string id of the menu page class
---@param menu_id string unique id of the menu
---@return number position index of the new menu page
function MenuPageArray:appendMenu(class_id, menu_id)
    local size = self.size + 1
    self.size = size
    self[size] = {class_id, menu_id, {}}
    return size
end

---increase the counter and retrieve a menu by the lists of next menus; can not be used when no menu is present
---@param menu_list_key string the key of choices that corresponds to the list of menus
---@param counter_key string the key of choices that corresponds to the counter of the list of menus
---@return string, string, number class_id, menu_page_id and index of the retrieved menu page if successful; return nil, nil otherwise
function MenuPageArray:retrieveNextMenu(menu_list_key, counter_key)
    local i = self.size
    local class_id, menu_page_id, menu_page_pos  -- find the next menu
    while i > 0 do
        local choices = self[i][3]
        local count = choices[counter_key]
        if count ~= nil then
            local menus = choices[menu_list_key]
            if count < #menus then
                class_id, menu_page_id = unpack(menus[count + 1])
                menu_page_pos = self.size + 1
                choices[counter_key] = count + 1  --update counter of the menu that spawned this menu
                break
            end
        end
        i = i - 1
    end
    return class_id, menu_page_id, menu_page_pos
end

---decrease the counter and retrieve a menu by the lists of next menus; can not be used when no menu is present
---@param menu_list_key string the key of choices that corresponds to the list of menus
---@param counter_key string the key of choices that corresponds to the counter of the list of menus
---@return string, string, number class_id, menu_page_id and index of the spawner of the menu page;
function MenuPageArray:retrievePrevMenu(menu_list_key, counter_key)
    local size = self.size

    local current_menu_id = self[size][2]
    local class_id, menu_page_id, menu_page_pos  -- find out which menu spawned the menu
    local i = size - 1
    while i > 0 do
        local choices = self[i][3]
        local menus = choices[menu_list_key]
        if menus then
            local count = choices[counter_key]
            if count > 0 and current_menu_id == menus[count][2] then
                class_id, menu_page_id = unpack(self[i])
                choices[counter_key] = count - 1
                break
            end
        end
        i = i - 1
    end
    return class_id, menu_page_id, menu_page_pos
end

---remember a choice that is made
---@param i number index of the menu page in the array
---@param key string key for retrieval
---@param choice any data to be stored
function MenuPageArray:setChoice(i, key, choice)
    local choices = self[i][3]
    choices[key] = choice
end

---retrieve a choice that is remembered
---@param i number index of the menu page in the array
---@param key string key for retrieval
---@return any data stored with the given key
function MenuPageArray:getChoice(i, key)
    local choices = self[i][3]
    return choices[key]
end

---retrieve the closest-to-the-end choice that is non-nil with the given key
---@param key string key for retrieval
---@return any data stored with the given key
function MenuPageArray:queryChoice(key)
    for i = self.size, 1, -1 do
        local choices = self[i][3]
        local choice = choices[key]
        if choice ~= nil then
            return choice, i
        end
    end
    return nil
end

---get the ith menu page id
---@param i number index of the menu page
---@return string id of the menu page with the given index
function MenuPageArray:getMenuId(i)
    return self[i][2]
end

---get the class of the menu page
---@param i number index of the menu page
---@return string id of the class of the menu page with the given index
function MenuPageArray:getMenuClassId(i)
    return self[i][1]
end

return MenuPageArray