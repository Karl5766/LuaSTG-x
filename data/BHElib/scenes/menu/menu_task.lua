---------------------------------------------------------------------------------------------------
--- menu_eff.lua
---
--- Copyright (C) 2018-2020 Xrysnow. All rights reserved.
---
--- modifier:
---     Karl, 2021.3.6, add some tasks
---------------------------------------------------------------------------------------------------

---@class MenuTask
local MenuTask = {}

---------------------------------------------------------------------------------------------------
---cache functions

local task = task

---菜单淡入
function MenuTask.fadeIn(menu, time)
    task.Clear(menu)
    task.New(menu, function()
        menu.hide = false
        for i = 0, (time - 1) do
            menu.alpha = i / (time - 1)
            task.Wait()
        end
        menu:setAcceptInput(true)
    end)
end

---菜单淡出
function MenuTask.fadeOut(menu, time)
    task.Clear(menu)
    task.New(menu, function()
        menu:setAcceptInput(false)
        for i = (time - 1), 0, -1 do
            menu.alpha = i / (time - 1)
            task.Wait()
        end
        menu.hide = true
    end)
end

---implements simple menu transition;
---create tasks under both the menu transition from and to to control their fade in/out
---@param menu_from any menu to transition from; if nil, menu_to is the first menu
---@param menu_to any menu to transition to; if nil, no menu will come in
---@param time number total transition time
---@return any menu_to, the menu transitioned to
function MenuTask.transitionTo(menu_from, menu_to, time)
    if menu_from then
        MenuTask.fadeOut(menu_from, time)
    end
    if menu_to then
        MenuTask.fadeIn(menu_to, time)
    end
    return menu_to
end

return MenuTask