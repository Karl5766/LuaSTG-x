---------------------------------------------------------------------------------------------------
---move_animation.lua
---author: Karl
---date: 2021.8.18
---desc: This file defines animation with built-in idle, move-left and move-right interfaces
---------------------------------------------------------------------------------------------------

local ImageArrayAnimation = require("BHElib.units.animation.image_array_animation")

---@class MoveAnimation:ImageArrayAnimation
local M = LuaClass("MoveAnimation", ImageArrayAnimation)

local EndCallbacks = require("BHElib.units.animation.animation_end_callbacks")

---------------------------------------------------------------------------------------------------
---init

---create an ImageArrayAnimation object
---@param base_hscale number the base factor for hscale
---@param idle_ani table<string,number,number> the image array to play in idle
---@param move_left_ani table<string,number,number> the image array to play moving left; if nil, will use move_right_ani
---@param move_right_ani table<string,number,number> the image_array to play moving right; if nil, will use move_left_ani
function M.__create(base_hscale, idle_ani, move_left_ani, move_right_ani)
    local self = ImageArrayAnimation.__create()

    ---@type number
    self.hscale = nil
    ---@type number
    self.base_hscale = base_hscale
    ---@type table<string,number,number>
    self.idle_ani = idle_ani
    ---@type table<string,number,number>
    self.move_left_ani = move_left_ani
    ---@type table<string,number,number>
    self.move_right_ani = move_right_ani

    return self
end

---------------------------------------------------------------------------------------------------
---setters and getters

---for setting the display of the image to be original/a mirror of the original
---@return number
function M:getHscale()
    return self.hscale
end

---@return table<string,number,number>
function M:getIdleImageArray()
    return self.idle_ani
end

---@return table<string,number,number>
function M:getMoveImageArray()
    return self.move_left_ani
end

---@return table<string,number,number>
function M:getMoveRightImageArray()
    return self.move_right_ani
end

---------------------------------------------------------------------------------------------------
---update

---update the animation
function M:update(dt)
    task.Do(self)  -- WARNING: NOT COMPATIBLE WITH ANIMATION PLAYBACK SPEED CONTROL
    ImageArrayAnimation.update(self, dt)
end

---------------------------------------------------------------------------------------------------
---built-in animations

---@param animation_interval number the time interval between adjacent images
function M:playIdleAnimation(animation_interval)
    self.hscale = self.base_hscale
    local idle_ani = self.idle_ani
    self:play(
            idle_ani,
            animation_interval,
            true,
            0,
            EndCallbacks.repeatAgain)
end

---@param is_left boolean if true, play left-moving animation; otherwise play right_moving animation
---@param animation_interval number the time interval between adjacent images
---@param is_forward boolean if ture, play the animation in forward direction; otherwise play it reversed
---@param skip_time number time to skip from the start of the image array
---@param end_callback function<self> the callback to call at the end of the animation
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
    self:play(
            animation_to_play,
            animation_interval,
            is_forward,
            skip_time,
            end_callback)
end

---WARNING: NOT COMPATIBLE WITH ANIMATION PLAYBACK SPEED CONTROL
---play a movement animation
---@param time number the time from the start of movement to a full stop (may not be the same as move animation time)
---@param is_left boolean if true, play move-left animation; otherwise play move-right animation
---@param move_end_callback function<self> movement animation end callback
function M:playMirroredMovementAnimation(move_ani_interval, idle_ani_interval, time, is_left, move_end_callback)
    self:playMovementAnimation(is_left, move_ani_interval, true, 0, move_end_callback)

    local total_wait = time - 1
    local animation_duration = self:getAnimationDuration()
    local reverse_time = total_wait - animation_duration
    if total_wait >= animation_duration * 2 then
        reverse_time = math.floor(total_wait / 2)
    end

    task.New(self, function()
        task.Wait(reverse_time)

        local animation_time = min(animation_duration, self:getElapsedTime())
        local skip_time = animation_duration - animation_time
        self:playMovementAnimation(is_left, move_ani_interval, false, skip_time, EndCallbacks.freezeAnimation)

        task.Wait(animation_time)  -- reverse play takes the same time to

        self:playIdleAnimation(idle_ani_interval)
    end)
end

return M