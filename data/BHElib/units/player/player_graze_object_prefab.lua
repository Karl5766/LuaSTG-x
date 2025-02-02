---------------------------------------------------------------------------------------------------
---player_graze_object_prefab.lua
---date: 2021.8.2
---desc: Defines the object that manages the grazing of the player
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---@class Prefab.PlayerGrazeObject
local M = Prefab.NewX(Prefab.Object)

---@param radius number
---@param player Prefab.Player
function M:init(radius, player)
    self.group = GROUP_PLAYER
    self.bound = false
    self.hide = true
    self.player = player

    self.a = radius
    self.b = radius
end

---@param bullet Prefab.Object the bullet that is grazed
function M:graze(bullet)
    PlaySound("se:graze", 0.15, 0, true)
    local player = self.player
    local player_resource = player.player_resource
    player_resource.num_graze = player_resource.num_graze + 1
    player:getStage():addScore(10000)
end

function M:colli(other)
    local on_player_graze_object_collision = other.onPlayerGrazeObjectCollision
    if on_player_graze_object_collision then
        on_player_graze_object_collision(other, self)
    end
end

Prefab.Register(M)

return M