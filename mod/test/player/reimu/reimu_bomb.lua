---------------------------------------------------------------------------------------------------
---reimu_bomb.lua
---date: 2021.7.18
---desc: This file defines function that spawns the bombs of reimu
---------------------------------------------------------------------------------------------------

---@class player_bomb.Reimu
local M = LuaClass("player.reimu.ReimuSupport")

local Prefab = require("BHElib.prefab")

---------------------------------------------------------------------------------------------------
---cache functions and variables

local ceil = math.ceil
local floor = math.floor


return M