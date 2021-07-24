---------------------------------------------------------------------------------------------------
---cocos_node_prefab.lua
---desc: Defines objects that holds a cocos node and is responsible for updating, rendering, and
---     manages its cleanup
---modifier:
---     Karl, 2021.7.22, split from prefab.lua and named "renderer.lua"
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---@class Prefab.CocosNodeObject:Prefab.Object
local M = Prefab.NewX(Prefab.Object, "prefab.CocosNodeObject")

---@param canvas cc.Node the node to attach to
---@param node cc.Node the node to be attached
function M:init(canvas, node)
    canvas:add(node, 0)
    self.canvas = canvas
    self.node = node
end

function M:setNode(node)
    self.node:removeFromParent()
    self.canvas:add(node, 0)
    self.node = node
end

function M:del()
    self.node:removeFromParent()
end

function M:kill()
    self.node:removeFromParent()
end

Prefab.Register(M)

return M