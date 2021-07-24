---------------------------------------------------------------------------------------------------
---renderer_prefab.lua
---desc: Defines a renderer object which is used to handle render layer for non game object classes
---modifier:
---     Karl, 2021.7.22, split from prefab.lua and named "renderer.lua"
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---@class Prefab.Renderer:Prefab.Object
local M = Prefab.NewX(Prefab.Object)
function M:init(layer, master, coordinates_name)
    self.group = GROUP_GHOST
    self.layer = layer
    self.master = master
    self.coordinates_name = coordinates_name
end

local SetRenderView = require("BHElib.coordinates_and_screen").setRenderView
function M:render()
    local master = self.master
    SetRenderView(self.coordinates_name)
    master:render()
    SetRenderView("game")  -- game objects are usually rendered in "game" view
end

Prefab.Register(M)

return M