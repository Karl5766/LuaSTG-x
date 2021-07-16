---------------------------------------------------------------------------------------------------
---shoot.lua
---date: 2021.7.15
---desc: This file provides short interfaces to create simple pre-defined objects
---------------------------------------------------------------------------------------------------

---@class SimpleBullets
local M = {}

local PlayerBulletCancelEffect = require("BHElib.units.player.player_bullet_cancel_effect_prefab")

---@param img string
---@param exist_time number
---@param x number
---@param y number
---@param vx number
---@param vy number
---@param rot number
function M.CreatePlayerBulletCancelEffectS(img, exist_time, x, y, vx, vy, rot)
    local object = PlayerBulletCancelEffect(exist_time)  -- exists for 12 frames
    object.img = img
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
function M.CreatePlayerBulletCancelEffectP(img, exist_time, x, y, speed, angle, rot)
    local object = PlayerBulletCancelEffect(exist_time)  -- exists for 12 frames
    object.img = img
    object.x = x
    object.y = y
    object.vx = speed * cos(angle)
    object.vy = speed * sin(angle)
    object.rot = rot or angle
    return object
end

return M