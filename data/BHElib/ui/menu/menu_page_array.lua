---------------------------------------------------------------------------------------------------
---menu_page_array.lua
---author: Karl
---date: 2021.4.26
---desc: Defines an object consists of menu pages; each item of the array is an array of three
---     elements, namely {menu_page_init_callback, menu_page, choices}, where the third element is the
---     choices made in that menu; this is a strange class as every insert requires two separate
---     deletes (for two entries in array and in pool) to clean everything
---------------------------------------------------------------------------------------------------

---@class MenuPageArray
local MenuPageArray = LuaClass("menu.MenuPageArray")

---------------------------------------------------------------------------------------------------
---interface

---MenuPageArray() -> MenuPageArray object
---append(init_callback, menu_id, menu) -> (number) position index of the new item
---pop() -> {init_callback, menu_id, choices}
---setChoice(i, key, value)
---getChoice(i, key) -> value
---queryChoice(key, i) -> i, value
---setMenuId(i, menu_id)
---getMenuId(i) -> (string) id of the menu at the ith position
---getMenuClassId(i) -> LuaClass
---getSize()

---summary of what it does
---menu_pos -array[menu_pos]-> {init_callback, menu_id, choices}

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

---set a menu at the position
---@param i number position index of the menu page
---@param init_callback string initialization callback of the menu page
---@param menu_id string unique id of the menu
---@return number position index of the new menu page
function MenuPageArray:setMenu(i, init_callback, menu_id)

    local sizePlusOne = self.size + 1

    assert(i <=  sizePlusOne, "Error: Attempt to set menu page at an index out of range!")
    if i == sizePlusOne then
        self.size = sizePlusOne
        self[sizePlusOne] = {init_callback, menu_id, {}}
    else
        self[i] = {init_callback, menu_id, {}}
    end
end

---pop the last menu
function MenuPageArray:popMenu()
    local size = self.size
    local item = self[size]
    self[size] = nil
    self.size = size - 1
    return item
end

---increase the counter and retrieve a menu by the lists of next menus; can not be used when no menu is present
---@param menu_list_key string the key of choices that corresponds to the list of menus
---@param counter_key string the key of choices that corresponds to the counter of the list of menus
---@return string, string, number init_callback, menu_page_id and index of the retrieved menu page if successful; return nil, nil otherwise
function MenuPageArray:retrieveNextMenu(menu_list_key, counter_key)
    local i = self.size
    local init_callback, menu_page_id, menu_page_pos  -- find the next menu
    while i > 0 do
        local choices = self[i][3]
        local count = choices[counter_key]
        if count ~= nil then
            local menus = choices[menu_list_key]
            if count < #menus then
                init_callback, menu_page_id = unpack(menus[count + 1])
                menu_page_pos = self.size + 1
                choices[counter_key] = count + 1  --update counter of the menu that spawned this menu
                break
            end
        end
        i = i - 1
    end
    return init_callback, menu_page_id, menu_page_pos
end

---decrease the counter and retrieve a menu by the lists of next menus; should not be used when no menu is present
---@param menu_list_key string the key of choices that corresponds to the list of menus
---@param counter_key string the key of choices that corresponds to the counter of the list of menus
---@return string, string, number init_callback, menu_page_id and index of the spawner of the menu page;
function MenuPageArray:retrievePrevMenu(menu_list_key, counter_key)
    local size = self.size

    local current_menu_id = self[size][2]
    local init_callback, menu_page_id, menu_page_pos  -- find out which menu spawned the menu
    local i = size - 1
    while i > 0 do
        local choices = self[i][3]
        local menus = choices[menu_list_key]
        if menus then
            local count = choices[counter_key]
            if count > 0 and current_menu_id == menus[count][2] then
                init_callback, menu_page_id = unpack(self[i])
                menu_page_pos = i
                choices[counter_key] = count - 1
                break
            end
        end
        i = i - 1
    end
    return init_callback, menu_page_id, menu_page_pos
end

---find a menu by the lists of next menus;
---@param cur_pos number
---@param menu_list_key string the key of choices that corresponds to the list of menus
---@param counter_key string the key of choices that corresponds to the counter of the list of menus
---@return string, string, number init_callback, menu_page_id and index of the spawner of the menu page; nil if no result is found
function MenuPageArray:findPrevMenuOf(cur_pos, menu_list_key, counter_key)
    local size = self.size

    local current_menu_id = self[size][2]
    local init_callback, menu_page_id, menu_page_pos  -- find out which menu spawned the menu
    local i = cur_pos - 1
    while i > 0 do
        local choices = self[i][3]
        local menus = choices[menu_list_key]
        if menus then
            local count = choices[counter_key]
            if count > 0 and current_menu_id == menus[count][2] then
                init_callback, menu_page_id = unpack(self[i])
                menu_page_pos = i
                break
            end
        end
        i = i - 1
    end
    return init_callback, menu_page_id, menu_page_pos
end

---clear choices of a menu at the given position
function MenuPageArray:clearChoices(i)
    self[i][3] = {}
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

---get the initialization callback of the menu page at the given index
---@param i number index of the menu page
---@return string id of the class of the menu page with the given index
function MenuPageArray:getMenuInitCallback(i)
    return self[i][1]
end

return MenuPageArray