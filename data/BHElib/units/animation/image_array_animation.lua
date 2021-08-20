---------------------------------------------------------------------------------------------------
---image_array_animation.lua
---author: Karl
---date: 2021.8.17
---desc: This file defines animation that changes over the time. The the images to display is
---     set by interfaces on the object at run time; the animation advances as update() is called
---     and its current image is accessed by getImage() interface; the object does not handle
---     additional parameters like rotation or render mode
---     The object supports a callback (event) executed at the end of the animation for flexibility
---------------------------------------------------------------------------------------------------

---@class ImageArrayAnimation
local M = LuaClass("ImageArrayAnimation")

---------------------------------------------------------------------------------------------------
---cache functions and variables

local FindResSprite = FindResSprite

---------------------------------------------------------------------------------------------------
---init

---create an ImageArrayAnimation object
function M.__create()
    local self = {}

    ---range [0, animation_interval)
    ---@type number
    self.timer = nil  -- time after start playing the current image (reset each time an image switches)
    ---range [0, num_image - 1]
    ---@type number
    self.index = nil  -- index of the image in the animation
    ---@type number
    self.min_index = nil
    ---@type number
    self.max_index = nil
    ---@type string
    self.image_array_name = nil

    ---@type ResSprite
    self.sprite = nil
    ---@type number
    self.inc_timer = nil  -- 1 if animation is playing forwards; -1 if backwards
    ---@type number
    self.animation_interval = nil  -- number of frames between image changes to the next one

    return self
end

---------------------------------------------------------------------------------------------------
---setters and getters

---set the timer increment in update; can be used to implement animation pause or playing backwards
---@param inc_timer number an integer specifying the times of speed to play the current animation in
function M:setIncTimer(inc_timer)
    self.inc_timer = inc_timer
end

---@return number an integer specifying the times of speed to play the current animation in
function M:getIncTimer()
    return self.inc_timer
end

---@return table<string,number,number> the image array of the animation that is playing
function M:getImageArray()
    return {self.image_array_name, self.min_index, self.max_index}
end

---@return number number of frames between consecutive images being played
function M:getAnimationInterval()
    return self.animation_interval
end

---@return number number of frames between consecutive images being played
function M:getAnimationDuration()
    return self.animation_duration
end

---@return ResSprite the current sprite
function M:getSprite()
    return self.sprite
end

---@return number,number min_index, max_index the index range specifying the animation to play
function M:getIndexRange()
    return self.min_index, self.max_index
end

---@return number the time required to skip from the first sprite of the animation to the current frame
function M:getElapsedTime()
    local image_passed = self.index - 1
    if self.inc_timer > 0 then
        return image_passed * self.animation_interval + self.timer
    else
        return self.animation_duration - 1 - (image_passed * self.animation_interval + self.timer)
    end
end

---------------------------------------------------------------------------------------------------

---@param image_array table<string,number,number> specifies an image array, along with an index range on it
---@param animation_interval number interval between two consecutive images
---@param is_forward boolean true if the animation is to be played forward
---@param skip_time number skip timer value; if this is 0, animation will be played from the start
---@param end_callback function<self> function to be called at the end of the callback
function M:play(image_array, animation_interval, is_forward, skip_time, end_callback)
    local image_array_name = image_array[1]
    assert(image_array_name, "Error: Attempting to play a nil image array!")

    local min_index = image_array[2] or 1
    local max_index = image_array[3] or GetImageArraySize(image_array_name)

    local num_image = max_index - min_index + 1

    local animation_duration = animation_interval * num_image

    self.min_index = min_index
    self.max_index = max_index
    self.image_array_name = image_array_name
    self.animation_interval = animation_interval
    self.animation_duration = animation_duration
    self.end_callback = end_callback

    if is_forward then
        self.inc_timer = 1
        self.timer = 0
        self.index = min_index
    else
        self.inc_timer = -1
        self.timer = animation_interval - 1
        self.index = max_index
    end
    self:updateSpriteByIndex()  -- update may not set this, so do it once here

    self:advanceTime(skip_time)
end

---update sprite
function M:updateSpriteByIndex()
    self.sprite = FindResSprite(self.image_array_name..self.index)
end

---advance animation timer
---@param dt number time elapsed; should be a non-negative integer
function M:advanceTime(dt)
    local inc_time = self.inc_timer * dt
    local timer = self.timer + inc_time  -- updated value
    local animation_interval = self.animation_interval
    local index = self.index

    local inc_index = math.floor(timer / animation_interval)

    -- no update needed (except for self.timer) if index does not change
    if inc_index ~= 0 then
        index = index + inc_index
        timer = timer - inc_index * animation_interval

        self.index = index
        if index < self.min_index or index > self.max_index then
            -- the animation has reached an end
            local end_callback = self.end_callback
            if end_callback then
                end_callback(self)
            end
        else
            self:updateSpriteByIndex()
        end
    end

    self.timer = timer  -- note timer and index will continue to be updated even after the end of the image
end

---update the image according to the animation type and time elapsed
---@param dt number time elapsed; should be a non-negative integer
M.update = M.advanceTime

return M