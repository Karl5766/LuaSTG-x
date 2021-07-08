---------------------------------------------------------------------------------------------------
---menu_page_pool.lua
---author: Karl
---date: 2021.5.7
---desc: Defines an object keeping track of all existing menu pages
---------------------------------------------------------------------------------------------------

---@class MenuPagePool
local MenuPagePool = LuaClass("menu.MenuPagePool")

---------------------------------------------------------------------------------------------------
---interface

---MenuPagePool() -> MenuPageArray object
---getMenuPool() -> (table) an array of all active menus
---setMenuInPool(menu_id, menu)
---delMenuInPool
---getMenuFromPool(menu_id) -> Menu object

---summary of what it does
---menu_id -pool[menu_id]-> {menu_pos, menu}

---------------------------------------------------------------------------------------------------

function MenuPagePool.__create()
    local self = {}
    self.pool = {}
    return self
end

---@param menu_id string id of the menu
---@return boolean true if the menu exists
function MenuPagePool:isMenuExists(menu_id)
    return self.pool[menu_id]
end

---@param menu_id string id of the menu
---@return MenuPage
function MenuPagePool:getMenuFromPool(menu_id)
    local info = self.pool[menu_id]
    if info ~= nil then
        return info[2]
    else
        return nil
    end
end

---@param menu_id string id of the menu
---@return number position index of the menu
function MenuPagePool:getMenuPosFromPool(menu_id)
    local info = self.pool[menu_id]
    if info ~= nil then
        return info[1]
    else
        return nil
    end
end

---@param menu_id string id of the menu
function MenuPagePool:setMenuInPool(menu_id, menu, menu_pos)
    self.pool[menu_id] = {menu_pos, menu}
end

---@param menu_id string id of the menu
function MenuPagePool:delMenuInPool(menu_id)
    self.pool[menu_id] = nil
end

---return pairs(self.pool)
function MenuPagePool:getIter()
    return pairs(self.pool)
end

return MenuPagePool