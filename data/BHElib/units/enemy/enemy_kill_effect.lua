---------------------------------------------------------------------------------------------------
---enemy_kill_effect.lua
---date created: 2021.8.19
---reference: THlib/enemy/enemy.lua
---desc: Defines a object class that plays deletion effect for enemies
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---击破效果 | death effect for small enemies
---@class Prefab.EnemyKillEffect:Prefab.Object
local M = Prefab.NewX(Prefab.Object)

---------------------------------------------------------------------------------------------------
---cache variables and functions

local DefaultRenderFunc = DefaultRenderFunc
local Render = Render

---------------------------------------------------------------------------------------------------

---@param image string the image of the explosion effect
---@param persist_time number the number of frames this effect persists
function M:init(image, persist_time)
    self.img = image
    self.persist_time = persist_time
    self.layer = LAYER_ENEMY_DEATH_EFFECT
    self.group = GROUP_GHOST
    self.color = color.White
end

function M:render()
    local progress = self.timer / self.persist_time
    local alpha = 255 * (1 - progress) ^ 2
    local hscale, vscale = 0.4 - progress * 0.3, progress * 3 + 0.7
    local x, y = self.x, self.y
    local img = self.img

    SetImageState(img, "mul+alpha", Color(alpha, 255, 255, 255))

    --绘制三个椭圆，逐渐拉长
    for i = 1, 3 do
        local rot = -45 + 60 * i
        Render(img, x, y, rot, hscale, vscale)
    end
end

function M:frame()
    if self.timer >= self.persist_time then
        Del(self)
    end
end

return M