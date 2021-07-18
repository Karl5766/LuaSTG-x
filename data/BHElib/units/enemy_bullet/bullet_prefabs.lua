---------------------------------------------------------------------------------------------------
---bullet_prefabs.lua
---author: Karl
---date: 2021.4.22
---references: THlib/bullet/bullet.lua
---desc: Defines simple bullet prefabs; bullets here refer to the ones shot by the enemies (instead
---     of by the players)
---------------------------------------------------------------------------------------------------
---define a table, and define two prefabs for bullets and their cancel effects under the table

---@class BulletPrefabs
local M = {}

local Prefab = require("BHElib.prefab")
local BulletTypes = require("BHElib.units.enemy_bullet.bullet_types")
local Coordinates = require("BHElib.coordinates_and_screen")

---@class BulletPrefabs.CancelEffect
M.CancelEffect = Prefab.NewX(Prefab.Object)
local BulletCancelEffect = M.CancelEffect

---@class BulletPrefabs.Base
M.Base = Prefab.NewX(Prefab.Object)
local Bullet = M.Base

---------------------------------------------------------------------------------------------------
---cache variables and functions

local bullet_type_to_info = BulletTypes.bullet_type_to_info
local color_index_to_blink_effects = BulletTypes.color_index_to_blink_effects
local color_index_to_cancel_effects = BulletTypes.color_index_to_cancel_effects
local ran = ran
local GetAttr = GetAttr
local Del = Del
local DefaultRenderFunc = DefaultRenderFunc  -- engine default render for object to render self.img
local Render = Render  -- render arbitrary images

---------------------------------------------------------------------------------------------------
---bullet prefab
---an object created by this prefab will:
---1) have bullet sprite with one specific color from a finite number of colors
---2) interact with the other objects, E.g. kill player on hit
---3) always create a bullet cancel effect on deletion
---4) have optional spawn effect (blink effect)

---initial x, y position are not included in the parameter list since sometimes it is more
---convenient to use tools like tasks to initialize the position
---@param color_index number indicate color of the bullet
function Bullet:init(bullet_type_name, color_index, group, blink_time, size)

    self.group = GROUP_GHOST

    self.group = group
    self.bullet_type_name = bullet_type_name
    self.color_index = color_index
    self.effect_size = size

    if blink_time then
        self.img = color_index_to_blink_effects[color_index]
        self.layer = LAYER_BULLET_BLINK
        self.blink_time = blink_time
    else
        self:fire(0)
    end
end

function Bullet:frame()
    local blink_time = self.blink_time
    if blink_time then
        local cur_time = self.timer
        if cur_time >= blink_time then
            self.blink_time = nil
            self:fire(cur_time - blink_time)
        end
    end
end

function Bullet:render()
    local blink_time = self.blink_time
    if blink_time then
        local cur_time = self.timer
        local scale = 1 + 3 * (blink_time - cur_time) / blink_time  -- decreasing size
        Render(self.img, self.x, self.y, self.rot, scale * self.effect_size)
    else
        DefaultRenderFunc(self)
    end
end

function Bullet:del()
    BulletCancelEffect(self.x, self.y, self.color_index, self.effect_size)
end

function Bullet:kill()
    BulletCancelEffect(self.x, self.y, self.color_index, self.effect_size)
end

---@param dt number time elapsed since the end of blink time
function Bullet:fire(dt)
    self.layer = LAYER_ENEMY_BULLET
    self:changeSpriteTo(self.bullet_type_name, self.color_index)
end

---@param bullet_type_name string name of the bullet type to change to
---@param color_index number number specifying the color of the bullet
function Bullet:changeSpriteTo(bullet_type_name, color_index)
    self.bullet_type_name = bullet_type_name
    self.blink_time = nil
    self.color_index = color_index
    self.img = bullet_type_to_info[bullet_type_name].color_to_sprite_name[color_index]
end

Prefab.Register(Bullet)

---------------------------------------------------------------------------------------------------
---bullet cancel effect

---@param x number spawn x coordinate in "game" view
---@param y number spawn y coordinate in "game" view
---@param color_index number indicate color of the bullet
function BulletCancelEffect:init(x, y, color_index, size)

    self.x = x
    self.y = y
    self.group = GROUP_GHOST
    self.layer = LAYER_BULLET_CANCEL

    -- randomizing size and rotation of the cancel effect
    local scale = size * ran:Float(0.5, 0.75)
    self.hscale = scale
    self.vscale = scale
    self.rot = ran:Float(0, 360)

    self.img = color_index_to_cancel_effects[color_index]
end

function BulletCancelEffect:frame()
    if GetAttr(self, "timer") == 23 then
        Del(self)
    end
end

BulletCancelEffect.render = DefaultRenderFunc

Prefab.Register(BulletCancelEffect)

return M