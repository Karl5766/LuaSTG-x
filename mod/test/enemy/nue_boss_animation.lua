local Prefab = require("core.prefab")

local AnimatedUnit = require("BHElib.units.animation.animated_unit_prefab")

---@class Prefab.AnimatedUnit.Nue:Prefab.AnimatedUnit
local M = Prefab.NewX(AnimatedUnit)

function M:init()
    self:loadResources()
    AnimatedUnit.init(self)

    self.animation_timer = 0
end

function M:loadResources()
    LoadTexture("tex:nue_ball", "THlib\\enemy\\undefined.png")
    LoadImage("image:nue_ball", "tex:nue_ball", 0, 0, 128, 128, 16, 16)
end

function M:frame()
    self.animation_timer = self.animation_timer + 1
end

function M:render()
    for i = 1, 2 do
        local rotation_coeff = self.animation_timer * 10 * i
        for side = -1, 1, 2 do
            local angle = side * self.animation_timer * 6 + 180 * i
            local distance = 3

            local x = self.x + cos(angle) * distance
            local y = self.y + sin(angle) * distance

            if i == 2 and side == 1 then
                -- render the top at center to prevent weird shaking of center blue circle
                x, y = self.x, self.y
            end

            Render('image:nue_ball', x, y, side * rotation_coeff, 1, 1)
        end
    end
end

function M:playIdleAnimation()
    self.img = "image:nue_ball"
end

function M:playMovementAnimation()
end

---@param is_left boolean true to play move left animation; false to play move right animation; nil to not play anything
function M:move(time, dx, dy, is_left, task_host)
    task.New(task_host, function()
        local base_x, base_y = self.x, self.y
        for i = 1, time do
            local c = 1 - ((time - i) / time) ^ 2
            self.x = base_x + dx * c
            self.y = base_y + dy * c

            task.Wait(1)
        end
    end)
end

Prefab.Register(M)

return M