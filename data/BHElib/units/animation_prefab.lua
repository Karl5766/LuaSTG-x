---------------------------------------------------------------------------------------------------
---image_array_animation_prefab.lua
---author: Karl
---date created: 2021.6.1
---desc: Defines an object prefab that handles animations consists of arrays of images
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")

---@class Prefab.Animation:Prefab.Object
local AnimationPrefab = Prefab.NewX(Prefab.Object)

---------------------------------------------------------------------------------------------------

---to be overridden in sub-classes
---this function should check if the resources have been loaded;
---if not, load the resources into resource pool
function AnimationPrefab:loadResources()
end

---------------------------------------------------------------------------------------------------

---@param layer number the layer that the animation displays in
function AnimationPrefab:init(layer)
    self.group = GROUP_GHOST  -- the animation itself does not collide with anything
    self.layer = LAYER_ENEMY
    self.bound = false

    self:loadResources()
end

function AnimationPrefab:setPosition(x, y)
    self.x = x
    self.y = y
end

function AnimationPrefab:getPosition()
    return self.x, self.y
end

Prefab.Register(AnimationPrefab)

return AnimationPrefab