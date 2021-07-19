---------------------------------------------------------------------------------------------------
---player_bullet_prefab.lua
---author: Karl
---date: 2021.5.30
---desc:
---modifier:
---     Karl, 2021.7.16, split from player_shot_prefabs.lua
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")

---@class Prefab.PlayerBullet:Prefab.Object
---@desc an object of this class is a player bullet that does damage and gets cancelled when the enemy is hit
local M = Prefab.NewX(Prefab.Object)

---------------------------------------------------------------------------------------------------

---overridden in sub-classes
function M:createCancelEffect()
end

---------------------------------------------------------------------------------------------------
---player bullet prefab

---@param attack number numeric value of the damage towards enemies
function M:init(attack)
    self.attack = attack  -- damage to the enemies on hit
    self.layer = LAYER_PLAYER_BULLET
    self.group = GROUP_PLAYER_BULLET
    self.colli_flag = false  -- deal with multiple collisions in a single frame; set to true at the first collision
end

---called by enemy colli function
function M:onEnemyCollision(enemy)
    if self.colli_flag == false then
        Kill(self)
        self:createCancelEffect()
        self.colli_flag = true
    end
end

function M:getAttack()
    return self.attack
end

Prefab.Register(M)

return M