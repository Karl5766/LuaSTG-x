---------------------------------------------------------------------------------------------------
---reimu_support.lua
---date: 2021.7.16
---desc: This file defines the sub shots of reimu
---------------------------------------------------------------------------------------------------

---@class player_support.Reimu
local M = LuaClass("player.reimu.ReimuSupport")

local Prefab = require("core.prefab")

---------------------------------------------------------------------------------------------------
---cache functions and variables

local ceil = math.ceil
local floor = math.floor

---------------------------------------------------------------------------------------------------
---init

---@param stage Stage
---@param player PlayerBase
---@param img string
function M.__create(stage, player, img)
    local self = {}
    self.min_power = 0
    self.max_power = 400
    self.power = self.min_power

    self.scale = 1
    self.focused_coeff = 0  -- 0 = non-focused; 1 = focused
    self.img = img
    self.stage = stage
    self.player = player
    self.power_level_transition_speed = 0.05
    self.support_rot = 0
    self.needle_range = 68

    -- in all following lists, each row is for a separate power level starting from level 1
    self.support_num_list = {
        0, 1, 2, 3, 4,
    }

    -- stores relative positions (to the player object), note the column order matters in transitions
    self.support_pos_list = {
        {},
        {{0, -30}},
        {{-30, 0}, {30, 0}},
        {{-30, -13}, {0, -30}, {30, -13}},
        {{-30, -13}, {-11, -30}, {11, -30}, {30, -13}},
    }
    local range = self.needle_range
    self.focused_support_pos_list = {
        {},
        {{0, 30}},
        {{-range / 5, 30}, {range / 5, 30}},
        {{-20, 24}, {0, 32}, {20, 24}},
        {{-20, 24}, {-20 / 3, 30}, {20 / 3, 30}, {20, 24}},
    }

    -- stores angles to shoot bullets at
    self.support_shoot_angle_list = {
        {},
        {90},
        {90, 90},
        {95, 90, 85},
        {100, 95, 85, 80},
    }

    self.existing_support_num_cache = nil
    self.sub_position_cache = {}  -- cache x, y of every sub object

    function self.power_easer(from, to, t)
        return from * (1 - t) + to * t
    end
    self.focused_easer = self.power_easer

    return self
end

function M:ctor()
    self:setPosition(self.player.x, self.player.y)
    self.transition_state = self:getTargetPowerLevel()  -- for smooth transition of power
    self:updateCache()
end

---------------------------------------------------------------------------------------------------
---setters and getters

function M:getPower()
    return self.power
end

---@param power number the power to set to; this value will be clamped between 0 and max_power
function M:setPower(power)
    self.power = max(0, min(power, self.max_power))
end

function M:setPosition(x, y)
    self.x, self.y = x, y
end

function M:setScale(scale)
    self.scale = scale
end

---@return number positive integer indicating the power level to go to
function M:getTargetPowerLevel()
    return floor(self.power / 100) + 1
end

---@return number positive integer indicating the current effective power level
function M:getCurrentPowerLevel()
    return floor(self.transition_state)
end

---@return number integer indicating the active number of sub objects
function M:getActiveSubNum()
    return self.support_num_list[self:getCurrentPowerLevel()]
end

---when transiting from a power level with less sub objects to one with more
---there will be some sub objects exist before they are ready to shoot
---@return number integer indicating the current number of sub objects existing
function M:getExistingSubNum()
    return self.existing_support_num_cache
end

---@param index number positive integer indicating the index of sub object to get position from
---@return number, number relative positions (to the player object) of the sub object
function M:getSubRelativePosition(index)
    assert(index <= self.existing_support_num_cache, "Error: Attempting to get position of a out of index support object!")

    local base_index = index * 2
    local cache = self.sub_position_cache
    return cache[base_index - 1], cache[base_index]
end

---------------------------------------------------------------------------------------------------
---support shots

local PlayerBullet = require("BHElib.units.bullet.player_bullet_prefab")
local _shoot = require("BHElib.scripts.shoot")

---@class Reimu.FollowShot:Prefab.PlayerBullet
local FollowShot = Prefab.NewX(PlayerBullet)

---@param trail_coeff number coefficient linear to the turning speed
function FollowShot:init(img, cancel_img, stage, init_x, init_y, attack, speed, angle, trail_coeff)
    PlayerBullet.init(self, attack, true)
    self.x = init_x
    self.y = init_y
    self.vx, self.vy = speed * cos(angle), speed * sin(angle)
    self.rot = angle
    self.v = speed
    self.img = img
    self.cancel_img = cancel_img
    self.trail = trail_coeff
    self.stage = stage
end

function FollowShot:frame()
    local target = self.stage:getEnemyTargetFrom(self)

    if IsValid(target) then
        local angle = Angle(self, target)
        local deviate_angle = math.mod(angle - self.rot + 720, 360)
        if deviate_angle > 180 then
            deviate_angle = deviate_angle - 360
        end
        local turn_speed = self.trail / (Dist(self, target) + 1)
        if turn_speed >= abs(deviate_angle) then
            self.rot = angle
        else
            self.rot = self.rot + sign(deviate_angle) * turn_speed
        end
    end

    self.vx = self.v * cos(self.rot)
    self.vy = self.v * sin(self.rot)
end

function FollowShot:createCancelEffect()
    _shoot.createBulletCancelEffect(
            self.cancel_img,
            LAYER_PLAYER_BULLET_CANCEL,
            12,
            self.x,
            self.y,
            self.vx * 0.4,
            self.vy * 0.4,
            self.rot)
end

Prefab.Register(FollowShot)

function M:fireAllSub()
    local base_x, base_y = self.x, self.y
    local power_level = self:getCurrentPowerLevel()
    local n = self:getActiveSubNum()
    if self.focused_coeff > 0.7 then
        local m = n * 2
        local attack = 0.48
        for i = 1, m do
            _shoot.createPlayerBullet(
                    "image:reimu_needle",
                    "image:reimu_needle_cancel_effect",
                    attack,
                    (-0.5 + i / (m + 1)) * self.needle_range + self.x,
                    self.y + 30,
                    0,
                    18,
                    90,
                    12,
                    0.4)
        end
    else
        local attack = 0.8
        for i = 1, n do
            local offset_x, offset_y = self:getSubRelativePosition(i)
            FollowShot(
                    "image:reimu_follow_bullet",
                    "image:reimu_follow_bullet_cancel_effect",
                    self.stage,
                    base_x + offset_x,
                    base_y + offset_y,
                    attack,
                    12,
                    self.support_shoot_angle_list[power_level][i],
                    240)
        end
    end
end

---------------------------------------------------------------------------------------------------
---update

function M:easeToPlayerPosition()
    local ease_coeff = 0.33
    local player = self.player
    local x, y = self.x, self.y
    self.x = x + (player.x - x) * ease_coeff
    self.y = y + (player.y - y) * ease_coeff
end

---this function assumes support_num > other_support_num as pre-condition;
---this function applies focused easing first and power easing then
---@param self player_support.Reimu
---@param power_easer function callback of form f(from, to, t) that controls easing of power change
---@param focused_easer function callback of form f(from, to, t) that controls easing of focused change
local function UpdatePositionCache(
        self,
        power_level,
        support_num,
        other_power_level,
        other_support_num,
        power_easer,
        focused_easer)
    -- carry out a linear interpolation between two power levels
    local ratio = abs(self.transition_state - power_level)

    local n = self.existing_support_num_cache
    local focused_coeff = self.focused_coeff
    local support_pos_list = self.support_pos_list
    local focused_support_pos_list = self.focused_support_pos_list
    local sub_position_cache = self.sub_position_cache

    if other_support_num == 0 then
        ---interpolate with the position of the player
        for i = 1, n do
            local x, y = unpack(support_pos_list[power_level][i])
            local focused_x, focused_y = unpack(focused_support_pos_list[power_level][i])

            local base_index = i * 2
            sub_position_cache[base_index - 1] = power_easer(focused_easer(x, focused_x, focused_coeff), 0, ratio)
            sub_position_cache[base_index] = power_easer(focused_easer(y, focused_y, focused_coeff), 0, ratio)
        end
    else
        local support_num_div = floor(support_num / other_support_num)
        local support_num_mod = math.mod(support_num, other_support_num)
        local support_first_part_total = (other_support_num - support_num_mod) * support_num_div

        for i = 1, n do
            local other_i
            if i > support_first_part_total then
                other_i = (other_support_num - support_num_mod)
                        + ceil((i - support_first_part_total) / (support_num_div + 1))
            else
                other_i = ceil(i / support_num_div)
            end

            local x, y = unpack(support_pos_list[power_level][i])
            local focused_x, focused_y = unpack(focused_support_pos_list[power_level][i])
            local other_x, other_y = unpack(support_pos_list[other_power_level][other_i])
            local other_focused_x, other_focused_y = unpack(focused_support_pos_list[other_power_level][other_i])

            local base_index = i * 2
            sub_position_cache[base_index - 1] = power_easer(
                    focused_easer(x, focused_x, focused_coeff),
                    focused_easer(other_x, other_focused_x, focused_coeff),
                    ratio)
            sub_position_cache[base_index] = power_easer(
                    focused_easer(y, focused_y, focused_coeff),
                    focused_easer(other_y, other_focused_y, focused_coeff),
                    ratio)
        end
    end
end

---update the cache attributes
function M:updateCache()
    local lower_power_level = floor(self.transition_state)
    local higher_power_level = ceil(self.transition_state)
    local support_num_list = self.support_num_list

    assert(lower_power_level <= #support_num_list,
            "Error: Lower power level = "..tostring(lower_power_level).." out of range!")
    assert(higher_power_level <= #support_num_list,
            "Error: Higher power level = "..tostring(higher_power_level).." out of range!")

    local lower_support_num = support_num_list[lower_power_level]
    local higher_support_num = support_num_list[higher_power_level]
    local existing_support_num = max(lower_support_num, higher_support_num)
    self.existing_support_num_cache = existing_support_num

    local power_easer = self.power_easer
    local focused_easer = self.focused_easer
    if lower_support_num > higher_support_num then
        UpdatePositionCache(
                self,
                lower_power_level,
                lower_support_num, higher_power_level,
                higher_support_num,
                power_easer,
                focused_easer)
    else
        UpdatePositionCache(
                self,
                higher_power_level,
                higher_support_num, lower_power_level,
                lower_support_num,
                power_easer,
                focused_easer)
    end
end

function M:update(dt)
    self:easeToPlayerPosition()

    -- handles transition between power levels
    local target_power_level = self:getTargetPowerLevel()
    local diff_level = target_power_level - self.transition_state
    local transition_speed = self.power_level_transition_speed
    if abs(diff_level) < transition_speed then
        self.transition_state = target_power_level
    else
        self.transition_state = self.transition_state + sign(diff_level) * transition_speed
    end

    local player_input = self.player:getPlayerInput()
    local focused_coeff = self.focused_coeff
    if player_input:isAnyRecordedKeyDown("slow") then
        self.focused_coeff = min(1, focused_coeff + 0.15)
    else
        self.focused_coeff = max(0, focused_coeff - 0.15)
    end

    self:updateCache()  -- make sure cache is updated when transition_state is changed

    -- rotate the sub objects
    self.support_rot = self.support_rot + 6
end

function M:render()
    local base_x, base_y = self.x, self.y
    for i = 1, self.existing_support_num_cache do
        local offset_x, offset_y = self:getSubRelativePosition(i)
        Render(
                self.img,
                base_x + offset_x,
                base_y + offset_y,
                self.support_rot,
                self.scale,
                self.scale,
                0.5)
    end
end

return M