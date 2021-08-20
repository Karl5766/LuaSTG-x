---------------------------------------------------------------------------------------------------
---img_enemy_type.lua
---author: Karl
---date created: 2021.8.19
---desc: Defines an enemy animation type that uses the engine built-in .img attribute for display
---------------------------------------------------------------------------------------------------

local EnemyTypeClass = require("BHElib.units.enemy.enemy_type.enemy_type_class")

---@class ImgEnemyType:EnemyTypeClass
local M = LuaClass("ImgEnemyType", EnemyTypeClass)

---------------------------------------------------------------------------------------------------
---init

---@param color_theme number specifies a color E.g. COLOR_RED
---@param use_aura boolean if true, the enemy displays aura each frame
---@param use_kill_effect boolean if true, the enemy spawns a kill effect on kill
---@param img any any resource type that can be assigned to .img attribute
---@param rot number initial rotation of the image
---@param inc_rot number increment of rotation of the image
function M.__create(color_theme, use_aura, use_kill_effect, use_spin_image, default_radius, img, rot, inc_rot)
    local self = EnemyTypeClass.__create(color_theme, use_aura, use_kill_effect, use_spin_image, default_radius)

    self.img = img
    self.rot = rot or 0
    self.inc_rot = inc_rot or 0

    return self
end

---------------------------------------------------------------------------------------------------
---on object init

---@param object Prefab.Object
function M:onInit(object)
    EnemyTypeClass.onInit(self, object)
    object.img = self.img
    object.rot = self.rot
    object.omiga = self.inc_rot
end

return M