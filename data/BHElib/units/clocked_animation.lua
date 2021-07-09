---------------------------------------------------------------------------------------------------
---clocked_animation.lua
---date: 2021.4.15
---desc: This file defines animation that changes over the time. An object of the class is
---     initialized with a few sequences of images as animations, and the sequence to display is
---     set by interfaces on the object at run time; the object maintains a clock updated by the
---     update() method, that manages playing the animation
---------------------------------------------------------------------------------------------------

---@class ClockedAnimation
local M = LuaClass("units.ClockedAnimation")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local floor = math.floor
local ceil = math.ceil
local mod = math.mod
local Insert = table.insert

---------------------------------------------------------------------------------------------------

function M.__create()
    local self = {
        timer = 0,
        rows = {},  -- all image rows
        row_sizes = {},  -- records sizes of the rows
    }
    M.clearAttributes(self)
    return self
end

---------------------------------------------------------------------------------------------------

function M:clearAttributes()
    self.cur_row = nil  -- current row
    self.cur_row_id = nil
    self.cur_img = nil  -- current image
    self.direction_coeff = nil  -- 1 if the animation is playing forward; -1 if backward
    self.is_loop = nil  -- a looping animation repeatedly displays the current row of images
    self.animation_interval = nil
    self.animation_duration = nil
end

---@param is_forward boolean true if the animation is to be played forward; false if backward
function M:setAnimationDirection(is_forward)
    if is_forward then
        self.direction_coeff = 1
    else
        self.direction_coeff = -1
    end
end

---@return number 1 if the animation is playing forward; -1 if backward
function M:getAnimationDirection()
    return self.direction_coeff
end

---@param row_id string id of the sequence of images
---@param images table an array of name of the images in the sequence
function M:loadRowImages(row_id, images)
    self.rows[row_id] = images
    self.row_sizes[row_id] = #images
end

---@param row_id string id of the sequence of images
---@param images table an array of name of the images in the sequence
function M:loadRowImagesFromTexture(row_id, tex_name, image_name, x, y, dx, dy, width, height, image_num, a, b, is_rect)
    local image_array = {}
    local flag = CheckRes("img", image_name..1)
    for i = 1, image_num do
        local cur_image_name = image_name..i
        if not flag then
            local cur_x, cur_y = x + dx * (i - 1), y + dy * (i - 1)
            LoadImage(
                    cur_image_name,
                    tex_name,
                    cur_x,
                    cur_y,
                    width,
                    height,
                    a or 0,
                    b or 0,
                    is_rect == true
            )
        end
        Insert(image_array, cur_image_name)
    end
    self:loadRowImages(row_id, image_array)
end

---@param row_id string id of the sequence of images in the animation to be played
---@param animation_interval number time in frames each image lasts
---@param start_time number starting timer value
---@param is_forward boolean if the animation is to be played forward
---@param is_loop boolean if the animation loops
function M:playAnimation(row_id, animation_interval, start_time, is_forward, is_loop)
    self.cur_row = self.rows[row_id]
    self.cur_row_id = row_id
    assert(self.cur_row, "row '"..row_id.."' does not exist")
    self.animation_interval = animation_interval
    self:setAnimationDirection(is_forward)
    self.is_loop = is_loop
    self.animation_duration = animation_interval * (#self.cur_row)
    -- set timer
    if is_forward then
        self.timer = start_time
    else
        self.timer = self.animation_duration - start_time
    end

    self:update(0)
end

---update the image according to the animation type and time elapsed
---@param dt number time elapsed
---@return nil|number if the animation finishes, return the positive time passed after completion of the animation
function M:update(dt)
    local dir_coeff = self.direction_coeff
    local t = self.timer + dt * dir_coeff  -- update timer
    self.timer = t

    local duration = self.animation_duration
    local animation_interval = self.animation_interval
    local is_loop = self.is_loop

    -- test if the animation has ended
    if not is_loop then
        if dir_coeff == 1 and t >= duration then
            return self.timer - duration
        elseif dir_coeff == -1 and t <= 0 then
            return -self.timer
        end
    end

    -- if not, update the animation
    local i
    if dir_coeff == 1 then
        i = floor(t / animation_interval) + 1
    else
        i = ceil(t / animation_interval)  -- deal with rounding problems in playing animation backward
    end
    local cur_row = self.cur_row
    if is_loop then
        i = i % (#cur_row) + 1
    end
    self.cur_img = cur_row[i]  -- assign the image
    return nil
end

---@return string name of the current sprite image to display; return nil if no animation is playing
function M:getImage()
    return self.cur_img
end

function M:getCurrentRowId()
    return self.cur_row_id
end

function M:getAnimationInterval()
    return self.animation_interval
end

function M:getRowSizeById(row_id)
    return self.row_sizes[row_id]
end

---@return number the duration of the current animation playing
function M:getAnimationDuration()
    return self.animation_duration
end

return M