---------------------------------------------------------------------------------------------------
---player_bullet_prefab.lua
---author: Karl
---date: 2021.5.30
---desc:
---modifier:
---     Karl, 2021.7.16, split from player_shot_prefabs.lua
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---@class Prefab.PlayerBullet:Prefab.Object
---@desc an object of this class is a player bullet that does damage and gets cancelled when the enemy is hit
local M = Prefab.NewX(Prefab.Object)

---------------------------------------------------------------------------------------------------

---overridden in sub-classes
function M:createCancelEffect()
end

function M:kill()
    self:createCancelEffect()
end

---------------------------------------------------------------------------------------------------
---init

---@param attack number numeric value of the damage towards enemies
---@param del_on_colli boolean
function M:init(attack, del_on_colli)
    self.attack = attack  -- damage to the enemies on hit
    self.layer = LAYER_PLAYER_BULLET
    self.group = GROUP_PLAYER_BULLET
    self.del_on_colli = del_on_colli
    self.colli_flag = false  -- deal with multiple collisions in a single frame; set to true at the first collision
end

---------------------------------------------------------------------------------------------------
---collision events

function M:onEnemyCollision(other)
    if self.colli_flag == false then
        other:receiveDamage(self.attack)

        if self.del_on_colli then
            Kill(self)
            self.colli_flag = true
        end
    end
end

Prefab.Register(M)

return M