---------------------------------------------------------------------------------------------------
---image_array_animation_prefab.lua
---author: Karl
---date created: 2021.6.1
---desc: Defines an object prefab that handles animations consists of arrays of images
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")
local AnimationPrefab = require("BHElib.units.animation_prefab")

---@class Prefab.ImageArrayAnimation:Prefab.Animation
local ArrayAnimationPrefab = Prefab.NewX(AnimationPrefab)

local ClockedAnimation = require("BHElib.units.clocked_animation")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskDo = task.Do
local TaskNew = task.New
local TaskWait = task.Wait

---------------------------------------------------------------------------------------------------

---to be overridden in sub-classes
---this function should check if the resources have been loaded;
---if not, load the resources into resource pool
function ArrayAnimationPrefab:loadResources()
end

---to be overridden in sub-classes
---this function should use the resources loaded in the resource pool to initialize the animation object
function ArrayAnimationPrefab:loadAnimation()
end

---------------------------------------------------------------------------------------------------

function ArrayAnimationPrefab:init(animation_interval, sprite_name_prefix)
    -- load resources, and set layer to LAYER_ENEMY
    AnimationPrefab.init(self, LAYER_ENEMY)

    self.animation_interval = animation_interval
    self.sprite_name_prefix = sprite_name_prefix

    self.clocked_animation = ClockedAnimation()
    self:loadAnimation()
    self:playIdleAnimation()  -- idle at the start
end

function ArrayAnimationPrefab:loadRowImages(row_id, texture_name, x, y, is_horizontal, sprite_width, sprite_height, num_images)
    local dx, dy = 0, 0
    if is_horizontal then
        dx = sprite_width
    else
        dy = sprite_height
    end
    self.clocked_animation:loadRowImagesFromTexture(
            row_id,
            texture_name,
            self.sprite_name_prefix.."_"..row_id,
            x,
            y,
            dx,
            dy,
            sprite_width,
            sprite_height,
            num_images,
            0,
            0,
            false
    )
end

function ArrayAnimationPrefab:frame()
    TaskDo(self)

    local clocked_animation = self.clocked_animation
    local t = clocked_animation:update(1)
    if t ~= nil then
        if self.has_final_animation then
            clocked_animation:playAnimation(clocked_animation:getCurrentRowId().."_final", clocked_animation:getAnimationInterval(), 0, true, true)
        else
            self:playIdleAnimation()
        end
    end
    self.img = self.clocked_animation:getImage()
end

function ArrayAnimationPrefab:setAnimationInterval(interval)
    self.animation_interval = interval
end

function ArrayAnimationPrefab:playAnimation(row_id, is_forward, is_loop, has_final_animation)
    self.has_final_animation = has_final_animation
    self.clocked_animation:playAnimation(row_id, self.animation_interval, 0, is_forward, is_loop)
end

---play the specified animation first in forward direction, then in backward direction
---this function guarantees the forward animation starts at t = 0, and backward animation ends at t = time
---@param row_id string specifies the row of images to use
---@param time number whole duration of the animation
function ArrayAnimationPrefab:playReversibleAnimation(row_id, time, task_host)
    local clocked_animation = self.clocked_animation
    local animation_interval = self.animation_interval

    self.has_final_animation = true
    clocked_animation:playAnimation(row_id, animation_interval, 0, true, false)

    local animation_duration = animation_interval * clocked_animation:getRowSizeById(row_id)
    local half_point = math.ceil(time / 2)
    local reverse_time = time - animation_duration
    local reverse_start_time = 0
    if reverse_time < half_point then
        reverse_start_time = half_point - reverse_time
        reverse_time = half_point
    end
    TaskNew(task_host, function()
        TaskWait(reverse_time)
        -- play animation in reverse
        self.has_final_animation = false
        self.clocked_animation:playAnimation(row_id, animation_interval, reverse_start_time, false, false)
        TaskWait(time - reverse_time)
        self:playIdleAnimation()
    end)
end

---------------------------------------------------------------------------------------------------

function ArrayAnimationPrefab:playMovementAnimation(time, is_left, task_host)
    local row_id = "move_right"
    if is_left then
        row_id = "move_left"
    end
    self:playReversibleAnimation(row_id, time, task_host)
end

---@param is_left boolean true to play move left animation; false to play move right animation; nil to not play anything
function ArrayAnimationPrefab:move(time, dx, dy, is_left, task_host)
    if is_left ~= nil then
        self:playMovementAnimation(time, is_left, task_host)
    end
    TaskNew(task_host, function()
        local base_x, base_y = self.x, self.y
        for i = 1, time do
            local c = 1 - ((time - i) / time) ^ 2
            self.x = base_x + dx * c
            self.y = base_y + dy * c

            TaskWait(1)
        end
    end)
end

---play idle animation
function ArrayAnimationPrefab:playIdleAnimation()
    self.has_final_animation = false
    self.clocked_animation:playAnimation("idle", self.animation_interval, 0, true, true)
end

Prefab.Register(ArrayAnimationPrefab)

return ArrayAnimationPrefab