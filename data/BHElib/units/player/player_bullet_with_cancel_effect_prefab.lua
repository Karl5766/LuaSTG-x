---------------------------------------------------------------------------------------------------
---player_bullet_prefab.lua
---author: Karl
---date: 2021.5.30
---desc: Defines player bullet that leaves a cancel effect when destroyed
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")
local PlayerBullet = require("BHElib.units.player.player_bullet_prefab")
local PlayerBulletCancelEffect = require("BHElib.units.player.player_bullet_cancel_effect_prefab")

---@class Prefab.PlayerBulletWithCancelEffect:Prefab.PlayerBullet
local M = Prefab.NewX(PlayerBullet)

---@param img string
---@param cancel_img string
---@param attack number attack of the player bullet
---@param cancel_speed_coeff number
---@param cancel_exist_time number time that the cancel effect last until disappear
---@param cancel_scale number image scale of the cancel effect; use self.hscale, self.vscale if nil
function M:init(img, cancel_img, attack, cancel_speed_coeff, cancel_exist_time, cancel_scale)
    PlayerBullet.init(self, attack)
    self.cancel_img = cancel_img
    self.img = img
    self.cancel_speed_coeff = cancel_speed_coeff
    self.cancel_exist_time = cancel_exist_time
    self.cancel_scale = cancel_scale
end

function M:createCancelEffect()
    local object = PlayerBulletCancelEffect(self.cancel_exist_time)  -- exists for 12 frames
    object.img = self.cancel_img
    object.x = self.x
    object.y = self.y
    local cancel_speed_coeff = self.cancel_speed_coeff
    object.vx = self.vx * cancel_speed_coeff
    object.vy = self.vy * cancel_speed_coeff
    object.rot = self.rot
    local scale = self.cancel_scale
    object.hscale = scale or self.hscale
    object.vscale = scale or self.vscale
end

Prefab.Register(M)

return M