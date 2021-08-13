---------------------------------------------------------------------------------------------------
---background_prefab.lua
---date created: 2021.8.13
---reference: THlib/background/backgournd.lua
---desc: Defines basic background base, the prefab for background objects
---modifiers:
---     Karl, 2021.8.13, moved the code from THlib and split the file background.lua to two parts,
---     this is the part with the definition of the background object class
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---@class Prefab.Background:Prefab.Object 背景类基类
local M = Prefab.NewX(Prefab.Object)

local Coordinates = require("BHElib.unclassified.coordinates_and_screen")

---------------------------------------------------------------------------------------------------
---init

---@param layer number
function M:init(layer)
    self.group = GROUP_GHOST
    self.layer = layer
end

---------------------------------------------------------------------------------------------------

---clear the canvas, and set render mode to
function M:renderClear()
    Coordinates.setRenderView("3d")
    RenderClear(Color(0x00000000))
end

---------------------------------------------------------------------------------------------------
---update

---render the background
function M:render()
end

Prefab.Register(M)

return M