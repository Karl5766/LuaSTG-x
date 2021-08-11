---------------------------------------------------------------------------------------------------
---laser_prefab.lua
---author: Karl
---date: 2021.8.8
---references: THlib/laser/laser.lua
---desc: Defines simple laser prefab
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")
require("BHElib.units.bullet.bullet_types")  -- for bullet colors

---@class Prefab.Laser
local M = Prefab.NewX(Prefab.Object)

local Coordinates = require("BHElib.unclassified.coordinates_and_screen")
local Items = require("BHElib.units.item.items")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Render = Render  -- render arbitrary images
local TaskNew = task.New
local TaskDo = task.Do
local TaskWait = task.Wait

---------------------------------------------------------------------------------------------------

---@param stage Stage the stage this laser is spawned in
---@param laser_type LaserTypeClass the type of laser to create
---@param index number specifies which variation of laser within the type to use
---@param length_mul number multiplier of the length of actual hitbox to the total length of the laser
---@param width_mul number multiplier of the width of actual hitbox to the current width of the laser
---@param graze_cooldown number the number of frames need to wait before the laser can be grazed again
---@param destroyable boolean whether the laser is destroyable
function M:init(stage, laser_type, index, length_mul, width_mul, graze_cooldown, destroyable)
    assert(laser_type:checkValidIndex(index), "Error: Invalid laser index!")
    --默认使用laser1

    self:changeImage(laser_type, index)
    self.group = GROUP_ENEMY_BULLET
    self.layer = LAYER_ENEMY_BULLET
    self.bound = true
    self.stage = stage
    self.destroyable = destroyable

    self.l1 = 0  -- length from head tip to body start
    self.l2 = 0  -- length from body start to body end
    self.l3 = 0  -- length from body end to tail tip
    self.half_total_length = 0  -- cache the value of (l1 + l2 + l3) * 0.5

    self.full_width = 0  -- render width when fully appeared, completely solid
    self.cur_width = 0  -- render width of the image
    self.phase_coeff = 0  -- 0 for can not be seen; 1 for completely visible

    -- collision
    self.length_mul = length_mul
    self.width_mul = width_mul
    self.a = 0
    self.b = 0
    self.rect = "obb"  -- rectangular hitbox

    -- transition
    self.inc_phase_coeff = 0
    self.countdown = 0  -- when countdown is non-zero, the laser is changing

    -- for player graze
    self.graze_cooldown = graze_cooldown
    self.graze_countdown = 0
end

---------------------------------------------------------------------------------------------------
---setters and getters

---instantly set the laser phase coefficient to given number
---@param phase_coeff number
function M:setPhaseCoeff(phase_coeff)
    self.phase_coeff = phase_coeff
    self.cur_width = phase_coeff * self.full_width
end

---@param l1 number length from head tip to body start
---@param l2 number length from body start to body end
---@param l3 number length from body end to tail tip
function M:setLength(l1, l2, l3)
    self.l1 = l1
    self.l2 = l2
    self.l3 = l3
    self:updateLength()
end

---@param full_width number render width when fully appeared, completely solid
function M:setFullWidth(full_width)
    self.full_width = full_width
    self.cur_width = self.phase_coeff * full_width
    self.b = full_width * self.width_mul * 0.5
end

---@param length_mul number multiplier of the length of actual hitbox to the total length of the laser
function M:setLengthMul(length_mul)
    self.length_mul = length_mul
    self.a = self.half_total_length * length_mul
end

---@param width_mul number multiplier of the width of actual hitbox to the current width of the laser
function M:setWidthMul(width_mul)
    self.width_mul = width_mul
    self.b = self.full_width * width_mul * 0.5
end

---update the length and the hitbox of the laser from l1, l2 and l3
function M:updateLength()
    local half_total_length = (self.l1 + self.l2 + self.l3) * 0.5
    self.half_total_length = half_total_length
    self.a = half_total_length * self.length_mul
end

function M:getHeadPos()
    local l = self.half_total_length
    local rot = self.rot
    return self.x - l * cos(rot), self.y - l * sin(rot)
end

function M:getTailPos()
    local l = self.half_total_length
    local rot = self.rot
    return self.x + l * cos(rot), self.y + l * sin(rot)
end

function M:orientFromHead(x, y, rot)
    local l = self.half_total_length
    self.x = x + l * cos(rot)
    self.y = y + l * sin(rot)
    self.rot = rot
end

function M:orientFromTail(x, y, rot)
    local l = self.half_total_length
    self.x = x + l * cos(rot)
    self.y = y + l * sin(rot)
    self.rot = rot + 180
end

function M:orientFromCenter(x, y, rot)
    self.x = x
    self.y = y
    self.rot = rot
end

function M:changeImage(laser_type, index)
    self.index = index
    self.laser_type = laser_type
    self.head_image, self.body_image, self.tail_image = laser_type:getImagesForIndex(index)
end

---------------------------------------------------------------------------------------------------
---update

function M:frame()
    TaskDo(self)

    if self.countdown > 0 then
        self.countdown = self.countdown - 1
        self:setPhaseCoeff(self.phase_coeff + self.inc_phase_coeff)
    end

    self.graze_countdown = max(0, self.graze_countdown - 1)
end

function M:render()

    local render_mode = "mul+add"
    if self.cur_width > 0 then
        local c = Color(255 * self.phase_coeff, 255, 255, 255)
        local rot = self.rot
        local cos_rot, sin_rot = cos(rot), sin(rot)
        local half_total_length = self.half_total_length
        local l1, l2, l3 = self.l1, self.l2, self.l3
        local laser_type = self.laser_type
        local img_l1, img_l2, img_l3 = laser_type:getImageLengthByParts()
        local img_width = laser_type:getImageWidth()
        local x, y = self.x - half_total_length * cos_rot, self.y - half_total_length * sin_rot
        local vscale = self.cur_width / img_width

        SetImageState(self.head_image, render_mode, c)
        Render(self.head_image, x, y, rot, l1 / img_l1, vscale)

        x, y = x + l1 * cos_rot, y + self.l1 * sin_rot
        SetImageState(self.body_image, render_mode, c)
        Render(self.body_image, x, y, rot, l2 / img_l2, vscale)

        x, y = x + l2 * cos_rot, y + self.l2 * sin_rot
        SetImageState(self.tail_image, render_mode, c)
        Render(self.tail_image, x, y, rot, l3 / img_l3, vscale)
    end
end

---------------------------------------------------------------------------------------------------
---collision

---@param player Prefab.Player
function M:onPlayerCollision(player)
    if self.phase_coeff > 0.999 then
        player:onEnemyBulletCollision(self)
    end
end

---@param other Prefab.PlayerGrazeObject
function M:onPlayerGrazeObjectCollision(other)
    if self.phase_coeff > 0.999 and self.graze_countdown == 0 then
        other:graze(self)
        self.graze_countdown = self.graze_cooldown
    end
end

---------------------------------------------------------------------------------------------------
---deletion

---create a cancel effect for the laser
local function CreateCancelEffect(self, t)
    local cancel_effect = M(
            self.stage,
            self.laser_type,
            self.index,
            self.length_mul,
            self.width_mul,
            self.graze_cooldown,
            false)
    cancel_effect:setPhaseCoeff(self.phase_coeff)
    cancel_effect:setLength(self.l1, self.l2, self.l3)
    cancel_effect:setFullWidth(self.full_width)
    cancel_effect.group = GROUP_GHOST
    cancel_effect.bound = false
    cancel_effect.colli = false
    cancel_effect.x = self.x
    cancel_effect.y = self.y
    cancel_effect.rot = self.rot
    cancel_effect:turnOff(t)
    cancel_effect.is_del = true
    TaskNew(cancel_effect, function()
        TaskWait(t)
        Del(cancel_effect)
    end)

    return cancel_effect
end

function M:del()
    if self.phase_coeff > 0 and not self.is_del then
        self.is_del = true
        CreateCancelEffect(self, 30)
        -- just a workaround since the newly created object can not be displayed instantly at the same frame
    end
end

local function IsInBound(x, y, l, r, b, t)
    return l < x and x < r and b < y and y < t
end

---find out the intersection between a line segment and y = 0
---@return number the x coordinate of the intersection; return nil if non-exist
local function HorizontalIntersect(x1, y1, x2, y2)
    local dy = y2 - y1
    if dy == 0 then
        return nil
    end
    return x1 + (x2 - x1) * (-y1 / dy)
end

---test intersection of a line segment with the wall y = wall_y
local function InsertIfIntersectHorizontal(intersections, wall_xmin, wall_xmax, wall_y, x1, y1, x2, y2)
    local x = HorizontalIntersect(x1, y1 - wall_y, x2, y2 - wall_y)
    if x and x <= wall_xmax and x >= wall_xmin then
        intersections[#intersections + 1] = {x, wall_y}
    end
end

---test intersection of a line segment with the wall x = wall_x
local function InsertIfIntersectVertical(intersections, wall_ymin, wall_ymax, wall_x, x1, y1, x2, y2)
    local y = HorizontalIntersect(y1, x1 - wall_x, y2, x2 - wall_x)
    if y and y <= wall_ymax and y >= wall_ymin then
        intersections[#intersections + 1] = {wall_x, y}
    end
end

local function Distance(x0, y0, x1, y1)
    local dx, dy = x0 - x1, y0 - y1
    return sqrt(dx * dx + dy * dy)
end

function M:onBulletCancel(stage)
    -- 出屏部分不产生掉落和消弹效果
    -- only generate faith items inside the screen
    local cos_rot, sin_rot = cos(self.rot), sin(self.rot)
    local half_total_length = self.half_total_length

    local x, y = self.x, self.y
    local hx, hy = half_total_length * cos_rot, half_total_length * sin_rot
    local x0, y0 = x - hx, y - hy
    local x1, y1 = x + hx, y + hy

    local start, finish = 0, half_total_length * 2

    local l, r, b, t = Coordinates.getOutOfBoundDeletionBoundaryInGame()
    local chk0, chk1 = IsInBound(x0, y0, l, r, b, t), IsInBound(x1, y1, l, r, b, t)
    if not chk0 or not chk1 then
        local intersections = {}

        while true do
            InsertIfIntersectHorizontal(intersections, l, r, b, x0, y0, x1, y1)
            InsertIfIntersectHorizontal(intersections, l, r, t, x0, y0, x1, y1)
            if #intersections >= 2 then
                break
            end
            InsertIfIntersectVertical(intersections, b, t, l, x0, y0, x1, y1)
            if #intersections >= 2 then
                break
            end
            InsertIfIntersectVertical(intersections, b, t, r, x0, y0, x1, y1)
            break
        end

        if #intersections == 0 then
            finish = 0
        elseif #intersections == 1 then
            finish = Distance(x0, y0, intersections[1][1], intersections[1][2])
            if chk1 then
                start, finish = finish, half_total_length * 2
            end
        elseif #intersections >= 2 then
            -- only take first two intersections, since there are not supposed to be more
            local p1, p2 = intersections[1], intersections[2]
            start = Distance(x0, y0, p1[1], p1[2])
            finish = Distance(x0, y0, p2[1], p2[2])
            if start > finish then
                start, finish = finish, start
            end
        end
    end
    for length = start, finish, 12 do
        local item = Items.SmallFaith(stage)
        item.x, item.y = x0 + length * cos_rot, y0 + length * sin_rot
    end

    Del(self, false)
end

---grow the length of laser from 0 over time
function M:grow(time, l1, l2, l3)
    if time == 0 then
        return
    end
    local total = l1 + l2 + l3

    local inc = total / time
    local cur_length = inc
    self.l1, self.l2, self.l3 = 0, 0, 0

    TaskNew(self, function()
        while cur_length < l3 do
            self:setLength(0, 0, cur_length)
            TaskWait(1)
            cur_length = cur_length + inc
        end
        cur_length = cur_length - l3
        while cur_length < l2 do
            self:setLength(0, cur_length, l3)
            TaskWait(1)
            cur_length = cur_length + inc
        end
        cur_length = cur_length - l2
        while cur_length < l1 do
            self:setLength(cur_length, l2, l3)
            TaskWait(1)
            cur_length = cur_length + inc
        end
        self:setLength(l1, l2, l3)
    end)
end

---------------------------------------------------------------------------------------------------

---@~chinese 设置渐显；
---
---@~english gradually set phase transition to 1;
function M:turnOn(t)
    t = max(1, int(t))
    self.countdown = t
    self.inc_phase_coeff = (1 - self.phase_coeff) / t
end

---@~chinese 设置渐显（一半）；
---
---@~english gradually set phase transition to 0.5;
function M:turnHalfOn(t)
    t = max(1, int(t))
    self.countdown = t
    self.inc_phase_coeff = (0.5 - self.phase_coeff) / t
end

---@~chinese 设置渐隐；
---
---@~english gradually set phase transition to 0;
function M:turnOff(t)
    t = max(1, int(t))
    self.countdown = t
    self.inc_phase_coeff = -self.phase_coeff / t
end

Prefab.Register(M)

return M