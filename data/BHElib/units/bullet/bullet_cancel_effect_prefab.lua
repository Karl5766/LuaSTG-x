---------------------------------------------------------------------------------------------------
---player_bullet_cancel_effect_prefab.lua
---author: Karl
---date: 2021.5.30
---desc:
---modifier:
---     Karl, 2021.7.16, split from player_shot_prefabs.lua
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---@class Prefab.PlayerBulletCancelEffect:Prefab.Object
---@desc an object of this class plays an image of player bullet cancel effect and fades out with time
local M = Prefab.NewX(Prefab.Object)

---------------------------------------------------------------------------------------------------
---cache variables and functions

local Color = Color

---------------------------------------------------------------------------------------------------
---player bullet cancel effect prefab

---@param exist_time number time that this cancel effect lasts in total, in frames
function M:init(exist_time)
    self.exist_time = exist_time
    self.group = GROUP_GHOST
    self.color = Color(255, 255, 255, 255)
end

function M:frame()
    local exist_time = self.exist_time
    if exist_time == 0 then
        Del(self)
    else
        local r = self.timer / exist_time
        if r >= 1 then
            Del(self)
        else
            self.color = Color(255 * (1 - r), 255, 255, 255)
        end
    end
end

Prefab.Register(M)

return M