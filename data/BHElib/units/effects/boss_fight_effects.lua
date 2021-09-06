---------------------------------------------------------------------------------------------------
---unit_motion.lua
---date created: before 2021
---desc: Defines effects used in boss fights
---------------------------------------------------------------------------------------------------

---@class BossFightEffects
local M = {}

local _alpha = 180
local _rm = "mul+add"

---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")
local ScreenEffect = require("BHElib.unclassified.screen_effect")

---------------------------------------------------------------------------------------------------

local CastLeafObject = Prefab.NewX(Prefab.Object)

function CastLeafObject:init(x, y, r, g, b, v, angle, lifetime, size)
    self.x = x
    self.y = y
    self.rot = ran:Float(0, 360)
    self.vx, self.vy = v * cos(angle), v * sin(angle)
    self.lifetime = lifetime
    self.omiga = 5
    self.layer = LAYER_ENEMY_CAST_EFFECT
    self.group = GROUP_GHOST
    self.bound = false
    self.img = "image:leaf"
    self.hscale = size
    self.vscale = size
    self.r, self.g, self.b = r, g, b
end

function CastLeafObject:frame()
    if self.timer >= self.lifetime then
        Del(self)
    end
end

function CastLeafObject:render()
    if self.timer > self.lifetime - 15 then
        --渐隐
        SetImageState("image:leaf", _rm,
                Color((self.lifetime - self.timer) * _alpha / 15, self.r, self.g, self.b))
    else
        --快速渐显
        SetImageState("image:leaf", _rm,
                Color((self.timer / (self.lifetime - 15)) ^ 6 * _alpha, self.r, self.g, self.b))
    end
    DefaultRenderFunc(self)
end

Prefab.Register(CastLeafObject)

---@param x number
---@param y number
---@param r number
---@param g number
---@param b number
function M.CreateBossCastEffect(x, y, r, g, b)
    PlaySound("se:ch00", 0.5, 0, true)
    for i = 1, 50 do
        local angle = ran:Float(0, 360)
        local lifetime = ran:Int(50, 80)
        local l = ran:Float(300, 500)
        CastLeafObject(
                x + l * cos(angle),
                y + l * sin(angle),
                r,
                g,
                b,
                l / lifetime,
                angle + 180,
                lifetime,
                ran:Float(2, 3))
    end
end

---------------------------------------------------------------------------------------------------

local DeathLeafEffect = Prefab.NewX(Prefab.Object)

function DeathLeafEffect:init(x, y, r, g, b, v, angle, lifetime, size)
    self.x = x
    self.y = y
    self.rot = ran:Float(0, 360)
    self.vx, self.vy = v * cos(angle), v * sin(angle)
    self.lifetime = lifetime
    self.omiga = 3
    self.layer = LAYER_ENEMY_DEATH_EFFECT
    self.group = GROUP_GHOST
    self.bound = false
    self.img = "image:leaf"
    self.hscale = size
    self.vscale = size
    self.r, self.g, self.b = r, g, b
end

function DeathLeafEffect:frame()
    if self.timer == self.lifetime then
        Del(self)
    end
end

function DeathLeafEffect:render()
    if self.timer < 15 then
        --渐显
        SetImageState("image:leaf", _rm,
                Color(self.timer * _alpha / 15, self.r, self.g, self.b))
    else
        --渐隐
        SetImageState("image:leaf", _rm,
                Color(((self.lifetime - self.timer) / (self.lifetime - 15)) * _alpha, self.r, self.g, self.b))
    end
    DefaultRenderFunc(self)
end
Prefab.Register(DeathLeafEffect)

function M.CreateBossDeathEffect(x, y, r, g, b, task_host)
    assert(task_host, "Error: Invalid task host!")
    PlaySound("se:enep01", 0.4, 0, true)
    ScreenEffect:shakePlayfield(task_host, 30, 15, 3)
    for i = 1, 70 do
        local angle = ran:Float(0, 360)
        local lifetime = ran:Int(40, 120)
        local l = ran:Float(100, 500)
        New(DeathLeafEffect, x, y, r, g, b, l / lifetime, angle, lifetime, ran:Float(2, 4))
    end
end

return M