---------------------------------------------------------------------------------------------------
---bullet_prefab.lua
---author: Karl
---date: 2021.4.22
---references: THlib/bullet/bullet.lua
---desc: Defines simple bullet prefab; bullets here refer to the ones shot by the enemies (instead
---     of by the players)
---modifiers:
---     Karl, 2021.7.19, replaced bullet cancel effect with generic cancel effect for both player
---     and enemy bullets
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")
local BulletTypes = require("BHElib.units.bullet.bullet_types")
local BulletCancelEffect = require("BHElib.units.bullet.bullet_cancel_effect_prefab")

---@class Prefab.Bullet
local M = Prefab.NewX(Prefab.Object)

---------------------------------------------------------------------------------------------------
---cache variables and functions

local bullet_type_to_info = BulletTypes.bullet_type_to_info
local color_index_to_blink_effects = BulletTypes.color_index_to_blink_effects
local color_index_to_cancel_effects = BulletTypes.color_index_to_cancel_effects
local ran = ran
local DefaultRenderFunc = DefaultRenderFunc  -- engine default render for object to render self.img
local Render = Render  -- render arbitrary images
local TaskDo = task.Do

---------------------------------------------------------------------------------------------------
---bullet prefab
---an object created by this prefab will:
---1) have bullet sprite with one specific color from a finite number of colors
---2) interact with the other objects, E.g. kill player on hit
---3) always create a bullet cancel effect on deletion
---4) have optional spawn effect (blink effect)

---initial x, y position are not included in the parameter list since sometimes it is more
---convenient to use tools like tasks to initialize the position
---@param bullet_type_name string E.g. "ball"
---@param color_index number indicate color of the bullet
---@param group number
---@param blink_time number persist time of blinking effect
---@param effect_size number size of the effects
---@param destroyable boolean whether this bullet is destroyable in collision with a player
function M:init(bullet_type_name, color_index, group, blink_time, effect_size, destroyable)
    self.bound = true
    self.group = group
    self.bullet_type_name = bullet_type_name
    self.color_index = color_index
    self.effect_size = effect_size
    self.grazed = false
    self.destroyable = destroyable
    self.frame_task = false

    if blink_time then
        self.img = color_index_to_blink_effects[color_index]
        self.layer = LAYER_BULLET_BLINK
        self.blink_time = blink_time
    else
        self:fire(0)
    end
end

function M:frame()
    local blink_time = self.blink_time
    if blink_time then
        local cur_time = self.timer
        self.hscale = self.effect_size * (1 + 3 * (blink_time - cur_time) / blink_time)  -- decreasing size
        self.vscale = self.hscale
        if cur_time >= blink_time then
            self:fire(cur_time - blink_time)
        end
    end
    if self.frame_task then
        TaskDo(self)
    end
end

---@param dt number time elapsed since the end of blink time
function M:fire(dt)
    self.layer = LAYER_ENEMY_BULLET
    self.hscale = 1
    self.vscale = 1
    self.blink_time = nil
    self:changeSpriteTo(self.bullet_type_name, self.color_index)
end

---@param bullet_type_name string name of the bullet type to change to
---@param color_index number number specifying the color of the bullet
function M:changeSpriteTo(bullet_type_name, color_index)
    self.bullet_type_name = bullet_type_name
    self.color_index = color_index
    if self.blink_time == nil then
        local bullet_type_info = bullet_type_to_info[bullet_type_name]
        assert(bullet_type_info, "Error: Unrecognized bullet type "..tostring(bullet_type_name).."!")
        local image = bullet_type_info.color_to_sprite_name[color_index]
        assert(image, "Error: Unrecognized color "..tostring(color_index).." for the given bullet type!")
        self.img = image
    else
        self.img = color_index_to_blink_effects[color_index]
    end
end

---@param bullet_type_name string name of the bullet type to change to
function M:changeBulletTypeTo(bullet_type_name)
    self:changeSpriteTo(bullet_type_name, self.color_index)
end

---@param color_index number number specifying the color of the bullet
function M:changeColorIndexTo(color_index)
    self:changeSpriteTo(self.bullet_type_name, color_index)
end

function M:createCancelEffect()
    local exist_time = 23
    local cancel = BulletCancelEffect(exist_time)
    cancel.x = self.x
    cancel.y = self.y
    cancel.layer = LAYER_BULLET_CANCEL
    cancel.img = color_index_to_cancel_effects[self.color_index]

    -- randomizing size and rotation of the cancel effect
    cancel.rot = ran:Float(0, 360)
    local size = self.effect_size * ran:Float(0.5, 0.75)
    cancel.hscale = size
    cancel.vscale = size
end

function M:del()
    self:createCancelEffect()
end
function M:kill()
    error("Error: Attempt to kill a bullet!")
end

---------------------------------------------------------------------------------------------------
---events

function M:onPlayerCollision(player)
    player:onEnemyBulletCollision(self)
end

function M:onPlayerGrazeObjectCollision(other)
    if self.grazed == false then
        other:graze(self)
        self.grazed = true
    end
end

function M:onBulletCancel(stage)
    if self.destroyable then
        local SmallFaith = require("BHElib.units.item.items").SmallFaith
        local object = SmallFaith(stage)
        object.x = self.x
        object.y = self.y
        Del(self)
    end
end

Prefab.Register(M)

return M