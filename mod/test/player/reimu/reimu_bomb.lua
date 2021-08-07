---------------------------------------------------------------------------------------------------
---reimu_bomb.lua
---date: 2021.7.18
---desc: This file defines function that spawns the bombs of reimu
---------------------------------------------------------------------------------------------------

---@class player_bomb.Reimu
local M = {}

local Prefab = require("core.prefab")
local PlayerBullet = require("BHElib.units.bullet.player_bullet_prefab")

---------------------------------------------------------------------------------------------------

local DamageCircle = Prefab.NewX(PlayerBullet)

---@param stage Stage if not nil; the circle will follow the enemy target returned by stage api
function DamageCircle:init(stage, x, y, init_radius, attack, is_follow)
    PlayerBullet.init(self, attack, false)
    self.group = GROUP_PLAYER
    self.hide = true
    self.bound = false
    self.x, self.y = x, y
    self.radius = init_radius
    self.stage = stage

    task.New(self, function()
        while true do
            self.a = self.radius + 32
            if is_follow then
                local target = stage:getEnemyTargetFrom(self)
                if IsValid(target) then
                    local c = 860 / (self.radius + 20) ^ 2
                    local dx, dy = target.x - self.x, target.y - self.y
                    self.x, self.y = self.x + dx * c, self.y + dy * c
                end
            end
            coroutine.yield()
        end
    end)
end

function DamageCircle:colli(other)
    PlayerBullet.colli(self, other)
    local on_bullet_clear = other.onBulletCancel
    if on_bullet_clear then
        on_bullet_clear(other, self.stage)
    end
end

function DamageCircle:onEnemyBulletCollision()

end

DamageCircle.frame = task.Do

Prefab.Register(DamageCircle)

---------------------------------------------------------------------------------------------------

local BombSquare = Prefab.NewX(Prefab.Object)

function BombSquare:init(circle_object, init_angle, inc_angle, init_rot, inc_rot, max_size)
    self.group = GROUP_GHOST
    self.layer = LAYER_PLAYER_BULLET
    self.bound = false

    self.ease_coeff = 0
    self.size_coeff = 0
    self.rot = init_rot
    self.omiga = inc_rot
    self.angle = init_angle
    -- main
    task.New(self, function()
        local dx, dy
        for i = 1, INFINITE do
            if not IsValid(circle_object) then
                break
            end
            local radius = circle_object.radius
            self.angle = self.angle + inc_angle * 220 / max(220, radius)
            local angle = self.angle
            self.x, self.y = circle_object.x + radius * cos(angle), circle_object.y + radius * sin(angle)
            dx, dy = self.dx, self.dy
            coroutine.yield()
        end
        self.vx, self.vy = dx, dy
        local ease_time = 30
        for i = ease_time, 0, -1 do
            self.ease_coeff = i / ease_time
            coroutine.yield()
        end
        Del(self)
    end)
    -- ease in
    task.New(self, function()
        local ease_time = 45
        for i = 1, ease_time do
            local coeff = i / ease_time
            self.ease_coeff = coeff
            self.hscale = coeff * max_size
            self.vscale = coeff * max_size
            coroutine.yield()
        end
    end)

    self.img = "image:reimu_bomb_square"
    self.img_object = FindResSprite(self.img)
end

BombSquare.frame = task.Do

function BombSquare:render()
    SetImageState(self.img, "mul+add", Color(self.ease_coeff * 255, 255, 255, 255))
    --self.img_object:setColor(Color(self.ease_coeff * 255, 255, 255, 255))
    DefaultRenderFunc(self)
end

Prefab.Register(BombSquare)

---------------------------------------------------------------------------------------------------

---@return DamageCircle the damage circle of the wave just created
local function CreateWave(stage, init_radius, init_x, init_y, attack, num_square, square_size, is_follow)
    local circle_object = DamageCircle(stage, init_x, init_y, init_radius, attack, is_follow)
    for i = 1, num_square do
        local inc_angle = 360 / num_square
        BombSquare(circle_object, inc_angle * i, 2, ran:Float(0, 360), 3, square_size)
        BombSquare(circle_object, inc_angle * i, -2, ran:Float(0, 360), -3, square_size)
    end
    return circle_object
end

function M:bomb(player, stage)
    -- task will terminate supposedly if player becomes invalid; this does not happen if they are invincible
    task.New(player, function()
        local unfocused_speed = player.unfocused_speed
        local focused_speed = player.focused_speed
        local reduced_speed = 1.5
        player.unfocused_speed = reduced_speed
        player.focused_speed = reduced_speed

        local cancel_sound = "enep00"
        for i = 1, 5 do
            PlaySound("power1", 0.8, 0, true)
            local attack = 0.26
            local square_size = 0.6
            if i == 1 then
                attack = 1
                square_size = 1
            end
            local circle1 = CreateWave(
                    stage,
                    0,
                    player.x,
                    player.y,
                    attack,
                    15,
                    square_size,
                    false)
            task.New(circle1, function()
                local acc_time = 60
                local max_speed = 3
                for i = 1, acc_time do
                    circle1.radius = circle1.radius + max_speed / acc_time * i
                    coroutine.yield()
                end
                for i = 1, 180 do
                    circle1.radius = circle1.radius + max_speed
                    coroutine.yield()
                end
                Del(circle1)
            end)
            task.Wait(30)
        end

        player.unfocused_speed = unfocused_speed
        player.focused_speed = focused_speed

        task.New(player, function()
            task.Wait(30)
            --PlaySound("border", 0.8, 0, true)
            for i = 1, 5 do
                --PlaySound("boon00", 0.8, 0, true)
                task.Wait(30)
            end
        end)

        for i = 1, 5 do
            local attack = 0.38
            local square_size = 0.6
            if i == 5 then
                attack = 1.5
                square_size = 1
            end
            local circle = CreateWave(
                    stage,
                    840,
                    player.x + ran:Float(-220, 220),
                    player.y + ran:Float(-220, 220),
                    attack,
                    10,
                    square_size,
                    true)
            task.New(circle, function()
                local max_speed = -10
                for i = 1, 75 do
                    circle.radius = circle.radius + max_speed
                    coroutine.yield()
                end
                Del(circle)
                PlaySound(cancel_sound, 0.6, 0, true)
            end)
            task.Wait(30)
        end
    end)
end

return M