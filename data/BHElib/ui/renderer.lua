---------------------------------------------------------------------------------------------------
---renderer.lua
---desc: Defines the inheritance of game objects, and two base prefabs Object and Object3d for all
---     other prefabs to inherit from.
---modifier:
---     Karl, 2021.2.16, renamed the file from class.lua to game_object.lua. Removed the global
---     lists and changed to the same naming conventions as the rest of the project
---     2021.3.16, renamed Class to Prefab under zino's suggestion; moved code from
---     to this file
---     2021.4.9, re-writes the file again for require() format
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---@class prefab.Renderer:Prefab.Object
local M = Prefab.New(Prefab.Object)
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