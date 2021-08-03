---------------------------------------------------------------------------------------------------
---shoot.lua
---date: 2021.7.15
---desc: This file provides short interfaces to create simple pre-defined objects
---------------------------------------------------------------------------------------------------

---@class SimpleBullets
local M = {}

local BulletCancelEffect = require("BHElib.units.bullet.bullet_cancel_effect_prefab")
local PlayerBullet = require("BHElib.units.bullet.player_bullet_prefab")

local function CreatePlayerBulletCancelEffect(bullet)
    local cancel = BulletCancelEffect(bullet.cancel_exist_time)
    cancel.x = bullet.x
    cancel.y = bullet.y
    local cancel_speed_coeff = bullet.cancel_speed_coeff
    cancel.vx = bullet.vx * cancel_speed_coeff
    cancel.vy = bullet.vy * cancel_speed_coeff
    cancel.layer = LAYER_PLAYER_BULLET_CANCEL
    cancel.img = bullet.cancel_img
    cancel.rot = bullet.rot
    local scale = bullet.cancel_scale
    cancel.hscale = scale or bullet.hscale
    cancel.vscale = scale or bullet.vscale
end

---create a player bullet that leaves a cancel effect when destroyed
---@param img string
---@param cancel_img string
---@param cancel_exist_time number
---@param attack number
---@param x number
---@param y number
---@param vx number
---@param vy number
---@param rot number
---@param cancel_speed_coeff number
function M.createPlayerBullet(img, cancel_img, attack, x, y, vx, vy, rot, cancel_exist_time, cancel_speed_coeff)
    local bullet = PlayerBullet(attack, true)
    bullet.img = img
    bullet.cancel_img = cancel_img
    bullet.bound = true
    bullet.x, bullet.y, bullet.vx, bullet.vy = x, y, vx, vy
    bullet.cancel_exist_time = cancel_exist_time
    bullet.cancel_speed_coeff = cancel_speed_coeff
    bullet.createCancelEffect = CreatePlayerBulletCancelEffect
    bullet.rot = rot
end

---@param img string
---@param exist_time number
---@param layer number
---@param x number
---@param y number
---@param vx number
---@param vy number
---@param rot number
function M.createBulletCancelEffect(img, layer, exist_time, x, y, vx, vy, rot)
    local object = BulletCancelEffect(exist_time)  -- exists for 12 frames
    object.img = img
    object.layer = layer
    object.x = x
    object.y = y
    object.vx = vx
    object.vy = vy
    object.rot = rot or Angle(0, 0, vx, vy)
    return object
end

return M