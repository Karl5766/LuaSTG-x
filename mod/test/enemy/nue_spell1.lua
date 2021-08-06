---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Karl2.
--- DateTime: 2021/6/1 23:39
---

local Prefab = require("core.prefab")
local SpellSession = assert(require("BHElib.sessions.boss.spell_session"))

local M = LuaClass("Nue.spell1", SpellSession)

local EnemyHitbox = require("BHElib.units.enemy.enemy_hitbox")

---------------------------------------------------------------------------------------------------
---bullet

local Orb = Prefab.NewX(Prefab.Object, "bullet.yinyang_orb")

---load orb sprite
do
    if not CheckRes("tex", "tex:reimu_sprite") then
        LoadTexture("tex:reimu_sprite", "THlib\\player\\reimu\\reimu.png")
    end
    local colli_radius = 6.15
    LoadImage(
            "image:yinyang_orb",
            "tex:reimu_sprite",
            65,
            145,
            14,
            14,
            colli_radius,
            colli_radius,
            false
    )
end

function Orb:init(ix, iy, scale, circle_radius, circle_time, init_angle, slide_angle, acc, acc_time, img_angular_velocity, final_velocity)
    self.img = "image:yinyang_orb"
    self.x, self.y = ix, iy
    self.layer = LAYER_ENEMY_BULLET - scale * 0.01
    self.group = GROUP_ENEMY_BULLET
    self.bound = true
    self.hscale = scale
    self.vscale = scale
    self.a = scale * 6.15
    self.omiga = img_angular_velocity
    self.opaque = 0
    self.color = Color(0, 255, 255, 255)

    local base_x, base_y = self.x + circle_radius * cos(init_angle), self.y + circle_radius * sin(init_angle)
    task.New(self, function()
        task.New(self, function()
            while self.transparency ~= 1 do
                local t = min(1, self.opaque + 0.1)
                self.opaque = t
                self.color = Color(t * 255, 255, 255, 255)
                task.Wait(1)
            end
        end)
        for i = 1, circle_time do
            task.Wait(1)
            local angle = init_angle - 180 + i / circle_time * slide_angle
            self.x, self.y = base_x + circle_radius * cos(angle), base_y + circle_radius * sin(angle)
        end
        local v = final_velocity
        local v_angle = init_angle + slide_angle
        if slide_angle > 0 then
            v_angle = v_angle - 90
        else
            v_angle = v_angle + 90
        end
        self.vx, self.vy = v * cos(v_angle), v * sin(v_angle)

        task.New(self, function()
            while true do
                if self.x > 192 then
                    self.x = 384 - self.x
                    self.vx = -self.vx
                elseif self.x < -192 then
                    self.x = -384 - self.x
                    self.vx = -self.vx
                elseif self.y > 224 then
                    self.y = 448 - self.y
                    self.vy = -self.vy
                end
                task.Wait(1)
            end
        end)

        for i = 1, acc_time do
            self.vy = self.vy - acc
            task.Wait(1)
        end
    end)
end

Orb.frame = task.Do

Prefab.Register(Orb)

---------------------------------------------------------------------------------------------------

function M.__create(boss)
    local hp = 720
    local hitbox = EnemyHitbox(16, hp)
    local self = SpellSession.__create(boss, hitbox, 1500)

    return self
end

function M:ctor()
    ---@type RumiaAnimation
    local boss = self.boss

    local boss_y = boss.y

    task.New(self, function()
        local a = 0
        while true do
            local Bullet = require("BHElib.units.bullet.bullet_prefab")
            local bullet = Bullet("ball", COLOR_BLUE, GROUP_ENEMY_BULLET, 12, 1, true)
            bullet.x = boss.x
            bullet.y = boss.y
            bullet.bound = true
            local r = 3
            bullet.vx = r * cos(a)
            bullet.vy = r * sin(a)
            a = a + 3
            task.Wait(1)
        end
    end)
    task.New(self, function()
        boss:move(60, -boss.x, 120 - boss.y, boss.x > 0, self)
        task.Wait(120)
        while true do
            task.Wait(24)
            --boss:playAnimation("cast", true, false, true)
            task.Wait(36)
            for i = 1, 1 do
                if i % 2 == 1 then
                    self:fire(boss.x, boss.y, 1)
                else
                    self:fire(boss.x, boss.y, -1)
                end
                task.Wait(120)
            end
            self:autoMove(-54, 54, boss_y - 10, boss_y + 10)
            task.Wait(120)
        end
    end)
end

function M:fire(x, y, side)

    PlaySound("explode", 0.1, 0, true)
    local density = 1.2
    local speed = 2

    local scale_array = {2, 2, 4}
    local slide_angle_array = {180, -180, -180}
    local num_bullet_array = {20, 20, 12}
    local base_velocity = speed
    local final_velocity_array = {base_velocity * 1, base_velocity * 1.6, base_velocity * 1.3}
    local radius = 35
    do
        for j = 1, 3 do
            local a = ran:Float(0, 360)
            local n = math.floor(num_bullet_array[j] * density)
            for i = 1, n do
                Orb(
                        x,
                        y,
                        scale_array[j],
                        radius,
                        60,
                        (a + i / n * 360) * side,
                        slide_angle_array[j],
                        0.006 * speed,
                        120,
                        3,
                        final_velocity_array[j]
                )
            end
        end
    end
end

function M:mouseFire(x, y, side)

    PlaySound("explode", 0.1, 0, true)
    local density = 1.5
    local speed = 1.8

    local scale_array = {2, 2, 4}
    local slide_angle_array = {180, -180, -180}
    local num_bullet_array = {20, 20, 12}
    local base_velocity = speed
    local final_velocity_array = {base_velocity * 1, base_velocity * 1.6, base_velocity * 1.3}
    local radius = 35
    do
        for j = 2, 2 do
            local a = ran:Float(0, 360)
            local n = math.floor(num_bullet_array[j] * density)
            for i = 1, n do
                Orb(
                        x,
                        y,
                        scale_array[j],
                        radius,
                        60,
                        (a + i / n * 360) * side,
                        slide_angle_array[j],
                        0.006 * speed,
                        120,
                        3,
                        final_velocity_array[j]
                )
            end
        end
    end
end

function M:frame()
    task.Do(self)

    local Input = require("BHElib.input.input_and_recording")
    local Coordinates = require("BHElib.coordinates_and_screen")
    if Input:isMouseButtonJustChanged(true, true) then
        local x, y = Input:getRecordedMousePositionInUI()
        x, y = Coordinates.uiToGame(x, y)

        self:mouseFire(x, y,ran:Sign())
    end
end

function M:autoMove(l, r, b, t)
    ---@type RumiaAnimation
    local boss = self.boss
    local x_dir = ran:Sign()
    local y_dir = ran:Sign()
    if boss.x < l then
        x_dir = 1
    elseif boss.x > r then
        x_dir = -1
    end
    if boss.y < b then
        y_dir = 1
    elseif boss.y > t then
        y_dir = -1
    end
    local dx = x_dir * ran:Float(32, 48)
    local dy = y_dir * ran:Float(0, 16)
    boss:move(60, dx, dy, x_dir == -1, self)
end

return M