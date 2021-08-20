---------------------------------------------------------------------------------------------------
---enemy_type_class.lua
---author: Karl
---date created: 2021.8.20
---desc: Defines a base enemy type class
---------------------------------------------------------------------------------------------------

---@class EnemyTypeClass
local M = LuaClass("EnemyTypeClass")

local EnemyKillEffect = require("BHElib.units.enemy.enemy_kill_effect")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local DefaultRenderFunc = DefaultRenderFunc
local sin = sin
local Render = Render

---------------------------------------------------------------------------------------------------

local _color_to_aura_image = {
    [COLOR_RED] = "image:fairy_aura_red",
    [COLOR_GREEN] = "image:fairy_aura_green",
    [COLOR_BLUE] = "image:fairy_aura_blue",
    [COLOR_YELLOW] = "image:fairy_aura_purple",
}

local _color_to_kill_effect_image = {
    [COLOR_RED] = "image:enemy_kill_effect_red",
    [COLOR_GREEN] = "image:enemy_kill_effect_green",
    [COLOR_BLUE] = "image:enemy_kill_effect_blue",
    [COLOR_YELLOW] = "image:enemy_kill_effect_yellow",
}

local _color_to_spin_image = {
    [COLOR_RED] = "image:yin_yang_orb_ring_red",
    [COLOR_GREEN] = "image:yin_yang_orb_ring_green",
    [COLOR_BLUE] = "image:yin_yang_orb_ring_blue",
    [COLOR_YELLOW] = "image:yin_yang_orb_ring_purple",
}

---------------------------------------------------------------------------------------------------
---init

---@param color_theme number specifies a color E.g. COLOR_RED
---@param use_aura boolean if true, the enemy displays aura each frame
---@param use_kill_effect boolean if true, the enemy spawns a kill effect on kill
---@param use_spin_image boolean if ture, render a spinning image behind the enemy
---@param default_radius number the default collision radius of the object
function M.__create(color_theme, use_aura, use_kill_effect, use_spin_image, default_radius)
    local self = {}

    self.color_theme = color_theme
    self.default_radius = default_radius

    if use_aura then
        self.aura_image = _color_to_aura_image[color_theme]
    end
    if use_kill_effect then
        self.kill_effect_image = _color_to_kill_effect_image[color_theme]
    end
    if use_spin_image then
        self.spin_image = _color_to_spin_image[color_theme]
    end

    return self
end

---------------------------------------------------------------------------------------------------
---getter

---@return number the default collision radius
function M:getDefaultRadius()
    return self.default_radius
end

---------------------------------------------------------------------------------------------------
---on object callbacks

---@param object Prefab.Object
function M:onInit(object)
    object.aura_image = self.aura_image
    object.kill_effect_image = self.kill_effect_image
    object.spin_image = self.spin_image
end

---@param object Prefab.Object
function M:onFrame(object)
end

---@param object Prefab.Object
function M:onRender(object)
    local x, y = object.x, object.y
    local timer = object.timer

    local aura_image = object.aura_image
    if aura_image then
        local rot = timer * 3
        local scale = 1.25 + 0.15 * sin(timer * 6)
        Render(aura_image, x, y, rot, scale)
    end

    DefaultRenderFunc(object)

    local spin_image = object.spin_image
    if spin_image then
        Render(spin_image, x, y, -timer * 6)
        Render(spin_image, x, y, timer * 4, 1.4)
    end
end

---@param object Prefab.Object
function M:onKill(object)

    if object.kill_effect_image then
        local x, y = object.x, object.y
        PlaySound("se:enep00", 0.25, object.x / 200, true)
        local effect = EnemyKillEffect(object.kill_effect_image, 30)
        effect.x, effect.y = x, y
    end
end

---@param object Prefab.Object
---@param time number the time from the start of movement to a full stop (may not be the same as move animation time)
---@param is_left boolean if true, play move-left animation; otherwise play move-right animation
function M:onMove(object, time, is_left)
end

return M