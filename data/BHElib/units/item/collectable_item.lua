---------------------------------------------------------------------------------------------------
---scriptable_session.lua
---author: Karl
---date created: 2021.8.6
---desc: Defines items that can be collected when the player comes near them; items have a downward
---     acceleration and a max falling speed; they also can be full-screen collected when certain
---     conditions are met
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

local M = Prefab.NewX(Prefab.Object)

---@param init_vy number initial y velocity of the item
---@param acc_y number acceleration in y direction (negative number for falling)
---@param max_descend_speed number max speed of the item
---@param flying_speed number speed of object flying towards player
---@param collect_radius number radius of player collection
---@param collect_time number total time it takes for the item to be completely collected
---@param del_y number item falling below this line will get deleted
---@param stage Stage the stage this item is spawned in
function M:init(
        init_vy,
        acc_y,
        max_descend_speed,
        flying_speed,
        collect_radius,
        collect_time,
        del_y,
        stage)
    self.group = GROUP_ITEM
    self.layer = LAYER_ITEM
    self.bound = false

    self.vy = init_vy
    self.acc_y = acc_y
    self.max_descend_speed = max_descend_speed
    self.flying_speed = flying_speed
    self.stage = stage
    self.collect_radius = collect_radius
    self.collect_time = collect_time
    self.del_y = del_y

    self.fly_target = nil
    self.is_collected = false
end

function M:frame()

    if self.is_collected == false then
        self:checkCollect()
    end

    -- there are three cases: item falling, flying towards player or is being collected into the player
    if self.fly_target == nil then
        self.vy = max(self.vy + self.acc_y, self.max_descend_speed)
        if self.y < self.del_y then
            Del(self)
        end
    elseif not self.is_collected then
        local target = self.fly_target
        if IsValid(target) then
            local a = Angle(self, target)
            local speed = self.flying_speed
            self.vx, self.vy = cos(a) * speed, sin(a) * speed
        else
            self.vx = 0
            self.vy = -self.max_descend_speed
            self.fly_target = nil
        end
    else
        local t = self.collect_timer + 1
        self.collect_timer = t

        local target = self.fly_target
        local collect_time = self.collect_time
        local remain_time = collect_time - t + 0.01
        if IsValid(target) then
            self.vx, self.vy = (target.x - self.x) / remain_time, (target.y - self.y) / remain_time
        end
        local scale = remain_time / collect_time
        self.hscale, self.vscale = scale, scale

        if remain_time <= 1 then
            Del(self)
        end
    end
end

function M:checkCollect()
    -- since the rule of determining whether the item is collected by a player may not be exactly
    -- the same as collision with an object, here it is manually checked so it's more flexible than
    -- using the built-in engine collision system

    local player = self.stage:getPlayer()
    if Dist(self, player) < self.collect_radius then
        self:onCollect(player)
    end
end

---@param player Prefab.Player the player that is collecting this item
function M:setFlyTarget(player)
    self.fly_target = player
end

---@param player Prefab.Player the player that is collecting this item
function M:onCollect(player)
    self.fly_target = player
    self.is_collected = true
    self.collect_timer = 0
end

function M:del()
end

function M:kill()
    error("Error: Attempt to kill an item!")
end

Prefab.Register(M)

return M