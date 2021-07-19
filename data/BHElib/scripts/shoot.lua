---------------------------------------------------------------------------------------------------
---shoot.lua
---date: 2021.7.15
---desc: This file provides short interfaces to create simple pre-defined objects
---------------------------------------------------------------------------------------------------

---@class SimpleBullets
local M = {}

local BulletCancelEffect = require("BHElib.units.bullet.bullet_cancel_effect_prefab")
local PlayerBulletWithCancelEffect = require("BHElib.units.player.player_bullet_with_cancel_effect_prefab")

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
function M.createPlayerBulletS(img, cancel_img, attack, x, y, vx, vy, rot, cancel_exist_time, cancel_speed_coeff)
    local bullet = PlayerBulletWithCancelEffect(
            img, cancel_img, attack, cancel_speed_coeff, cancel_exist_time)
    bullet.x, bullet.y, bullet.vx, bullet.vy = x, y, vx, vy
    bullet.rot = rot
end

---create a player bullet that leaves a cancel effect when destroyed
---@param img string
---@param cancel_img string
---@param cancel_exist_time number
---@param attack number
---@param x number
---@param y number
---@param speed number
---@param angle number
---@param rot number
---@param cancel_speed_coeff number
function M.createPlayerBulletP(img, cancel_img, attack, x, y, speed, angle, rot, cancel_exist_time, cancel_speed_coeff)
    local bullet = PlayerBulletWithCancelEffect(
            img, cancel_img, attack, cancel_speed_coeff, cancel_exist_time)
    bullet.x, bullet.y, bullet.vx, bullet.vy = x, y, speed * cos(angle), speed * sin(angle)
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
function M.createBulletCancelEffectS(img, layer, exist_time, x, y, vx, vy, rot)
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

---@param img string
---@param exist_time number
---@param x number
---@param y number
---@param vx number
---@param vy number
---@param rot number
function M.createBulletCancelEffectP(img, layer, exist_time, x, y, speed, angle, rot)
    local object = BulletCancelEffect(exist_time)  -- exists for 12 frames
    object.img = img
    object.x = x
    object.y = y
    object.vx = speed * cos(angle)
    object.vy = speed * sin(angle)
    object.rot = rot or angle
    return object
end

return M