---------------------------------------------------------------------------------------------------
---image_array_animated_unit_prefab.lua
---author: Karl
---date: 2021.8.17
---desc: This file defines a unit that updates and renders using an ImageArrayAnimation object. An
---     object derived from this type can be independently used as a
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")
local AnimatedUnit = require("BHElib.units.animation.animated_unit_prefab")

---@class Prefab.ImageArrayAnimatedUnit:Prefab.AnimatedUnit
local M = Prefab.NewX(AnimatedUnit, "Prefab.ImageArrayAnimatedUnit")

local ImageArrayAnimation = require("BHElib.units.animation.image_array_animation")
local EndCallbacks = require("BHElib.units.animation.animation_end_callbacks")

---------------------------------------------------------------------------------------------------
---virtual functions

---this function should check if the resources have been loaded;
---if not, load the resources into resource pool
M.loadResources = nil

---------------------------------------------------------------------------------------------------
---init

---@param default_animation_interval number the default interval between images in an animation played
---@param idle_ani string|ResAnimation the animation to play in idle
---@param move_left_ani string|ResAnimation the animation to play moving left; if nil, will use move_right_ani
---@param move_right_ani string|ResAnimation the animation to play moving right; if nil, will use move_left_ani
function M:init(default_animation_interval, base_hscale, idle_ani, move_left_ani, move_right_ani)
    self.idle_ani = idle_ani
    self.move_left_ani = move_left_ani
    self.move_right_ani = move_right_ani
    self.default_animation_interval = default_animation_interval
    self.animation = ImageArrayAnimation()
    self.base_hscale = base_hscale or 1

    AnimatedUnit.init(self)
end

---------------------------------------------------------------------------------------------------
---getter and setter

---@return ImageArrayAnimation the object that manages the update of the animation of the object
function M:getAnimation()
    return self.animation
end

---@param interval number the default interval between images in an animation played
function M:setDefaultAnimationInterval(interval)
    self.default_animation_interval = interval
end

---------------------------------------------------------------------------------------------------
---update

---update the animation
function M:frame()
    task.Do(self)
    local animation = self.animation
    animation:update(1)
    self.img = animation:getSprite()
end

---------------------------------------------------------------------------------------------------
---animation

function M:playIdleAnimation()
    self.hscale = self.base_hscale
    self.animation:play(
            self.idle_ani,
            self.default_animation_interval,
            true,
            0,
            EndCallbacks.repeatAgain)
end

function M:playMovementAnimation(is_left, animation_interval, is_forward, skip_time, end_callback)
    local move_left_ani = self.move_left_ani
    local move_right_ani = self.move_right_ani
    if not (move_left_ani or move_right_ani) then
        return
    end

    local animation_to_play
    if is_left then
        if move_left_ani then
            animation_to_play = move_left_ani
        else
            animation_to_play = move_right_ani
            self.hscale = -self.base_hscale
        end
    else
        if move_right_ani then
            animation_to_play = move_right_ani
        else
            animation_to_play = move_left_ani
            self.hscale = -self.base_hscale
        end
    end
    local animation = self.animation
    animation:play(
            animation_to_play,
            animation_interval,
            is_forward,
            skip_time,
            end_callback)
end

---play a movement animation
---@param time number the time from the start of movement to a full stop (may not be the same as move animation time)
---@param is_left boolean if true, play move-left animation; otherwise play move-right animation
function M:playMirroredMovementAnimation(time, is_left)

    ---@type ImageArrayAnimation
    local animation = self.animation

    self:playMovementAnimation(is_left, self.default_animation_interval, true, 0, EndCallbacks.freezeAnimation)

    local total_wait = time - 1
    local animation_duration = animation:getAnimationDuration()
    local reverse_time = total_wait - animation_duration
    if total_wait >= animation_duration * 2 then
        reverse_time = math.floor(total_wait / 2)
    end

    task.New(self, function()
        task.Wait(reverse_time)

        local animation_time = min(animation_duration, animation:getElapsedTime())
        local skip_time = animation_duration - animation_time
        self:playMovementAnimation(is_left, self.default_animation_interval, false, skip_time, EndCallbacks.freezeAnimation)

        task.Wait(animation_time)  -- reverse play takes the same time to finish

        self:playIdleAnimation()
    end)
end

Prefab.Register(M)

return M