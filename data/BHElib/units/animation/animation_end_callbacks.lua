---------------------------------------------------------------------------------------------------
---animation_end_callbacks.lua
---author: Karl
---date: 2021.8.18
---desc: Defines some end callbacks for ImageArrayAnimation:play() call
---------------------------------------------------------------------------------------------------

---@class AnimationEndCallbacks
local M = {}

---------------------------------------------------------------------------------------------------

---freeze at the final image
function M.freezeAnimation(self)
    -- no code needed since this is the default behavior of an ImageArrayAnimation object
    self.end_callback = nil
end

---------------------------------------------------------------------------------------------------

---loop infinitely
---@param self ImageArrayAnimation the object that triggers this callback
function M.repeatAgain(self)
    if self.inc_timer > 0 then
        self.timer = 0
        self.index = 0
    else
        self.timer = self.animation_interval - 1
        self.index = self.num_image - 1
    end
    self:updateSpriteByIndex()
end

---------------------------------------------------------------------------------------------------

---@param self ImageArrayAnimation the object that triggers this callback
---@param index number the index of the image to loop from
local function JumpToImageIndex(self, index)
    if self.inc_timer > 0 then
        self.timer = 0
    else
        self.timer = self.animation_interval - 1
    end
    self.index = index
    self:updateSpriteByIndex()
    assert(self.sprite, "Error: "..self[".classname"].." attempt to jump to invalid image in animation!")
end

---loop infinitely, but from second loop on only the part from specified image to the end will be played
---@param index number the index of the image to loop from
---@return function<self> the callback that loop from the specified index
function M.repeatFromImageIndex(index)
    return function(self)
        JumpToImageIndex(self, index)
    end
end

---------------------------------------------------------------------------------------------------

---play another animation when the current animation reaches an end
---@param animation_name string name of the animation, specifies a ResAnimation object
---@param animation_interval number interval between two consecutive images
---@param is_forward boolean true if the animation is to be played forward
---@param skip_time number skip timer value; if this is 0, animation will be played from the start
---@param end_callback function<self> function to be called at the end of the callback
---@return function<self> the callback that loop from the specified index
function M.playAnotherAnimation(animation_name, animation_interval, is_forward, skip_time, end_callback)
    return function(self)
        self:play(animation_name, animation_interval, is_forward, skip_time, end_callback)
    end
end

return M