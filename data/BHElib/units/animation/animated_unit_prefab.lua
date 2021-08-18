---------------------------------------------------------------------------------------------------
---animated_unit_prefab.lua
---author: Karl
---date: 2021.8.17
---desc: This file defines interfaces for managing animation of a unit
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---@class Prefab.AnimatedUnit:Prefab.Object
local M = Prefab.NewX(Prefab.Object, "Prefab.AnimatedUnit")

---------------------------------------------------------------------------------------------------
---virtual functions

---this function should check if the resources have been loaded;
---if not, load the resources into resource pool
M.loadResources = nil

---------------------------------------------------------------------------------------------------

function M:init()
    self.group = GROUP_GHOST
    self.layer = LAYER_ENEMY
    self.bound = false
end

return M