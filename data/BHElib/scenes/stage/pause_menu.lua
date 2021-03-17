---------------------------------------------------------------------------------------------------
---pause_menu.lua
---author: Karl
---date: 2021.3.16
---references: THlib/ext/pause_menu.lua THlib/ext.lua
---desc: implements pause menu for stages; pause menu kind of works like the menu scene
---------------------------------------------------------------------------------------------------

---@class PauseMenu
local PauseMenu = LuaClass()

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local TaskPropagateDo = task.PropagateDo
local SetChild = task.SetChild

---------------------------------------------------------------------------------------------------

function PauseMenu.__create()
    local self = {}

    -- TODO: create menu

    return self
end