---------------------------------------------------------------------------------------------------
---player_shot_prefabs.lua
---author: Karl
---date: 2021.5.30
---desc: PlayerShot class defines object classes for most player bullets
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")

---@class PlayerShotPrefabs
local PlayerShotPrefabs = {}

PlayerShotPrefabs.Base = Prefab.NewX(Prefab.Object)
---@class PlayerShotPrefabs.Base:Prefab.Object
---@desc an object of this class is a player bullet that does damage and gets cancelled when the enemy is hit
local Bullet = PlayerShotPrefabs.Base

PlayerShotPrefabs.CancelEffect = Prefab.NewX(Prefab.Object)
---@class PlayerShotPrefabs.CancelEffect:Prefab.Object
---@desc an object of this class plays an image of player bullet cancel effect and fades out with time
local BulletCancelEffect = PlayerShotPrefabs.CancelEffect

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Color = Color

---------------------------------------------------------------------------------------------------
---player bullet prefab

---@param attack number numeric value of the damage towards enemies
function Bullet:init(attack)
    self.attack = attack  -- damage to the enemies on hit
    self.layer = LAYER_PLAYER_BULLET
    self.group = GROUP_PLAYER_BULLET
    self.colli_flag = false  -- deal with multiple collisions in a single frame; set to true at the first collision
end

---overridden in sub-classes
function Bullet:createCancelEffect()
end

---called by enemy colli function
function Bullet:onEnemyCollision(enemy)
    if self.colli_flag == false then
        Kill(self)
        self:createCancelEffect()
        self.colli_flag = true
    end
end

function Bullet:getAttack()
    return self.attack
end

Prefab.Register(Bullet)

---------------------------------------------------------------------------------------------------
---player bullet cancel effect prefab

---@param exist_time number time that this cancel effect lasts in total, in frames
function BulletCancelEffect:init(exist_time)
    self.exist_time = exist_time
    self.layer = LAYER_PLAYER_BULLET_CANCEL
    self.group = GROUP_GHOST
    self.color = Color(255, 255, 255, 255)
end

function BulletCancelEffect:frame()
    local exist_time = self.exist_time
    if exist_time == 0 then
        Del(self)
    else
        local r = self.timer / exist_time
        if r >= 1 then
            Del(self)
        else
            self.color = Color(255 * (1 - r), 255, 255, 255)
        end
    end
end

Prefab.Register(BulletCancelEffect)

return PlayerShotPrefabs