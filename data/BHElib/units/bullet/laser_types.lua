---------------------------------------------------------------------------------------------------
---laser_types.lua
---author: Karl
---date: 2021.8.8
---references: THlib/laser/laser.lua
---desc: Defines types of lasers
---------------------------------------------------------------------------------------------------

---@class LaserTypes
local M = {}

require("BHElib.units.bullet.bullet_types")  -- for bullet colors

local LaserType = require("BHElib.units.bullet.laser_type_class")

M.default_laser = LaserType.declareTypeFromTexture(
        "tex:laser_default", "image_array:laser_default",
        NUM_ENEMY_BULLET_COLOR, 16, 64, 128, 64)

--LoadLaserTexture('laser2', 5, 236, 15)-->laser21~laser23
--LoadLaserTexture('laser3', 127, 1, 128)-->laser31~laser33
--LoadLaserTexture('laser4', 1, 254, 1)-->laser41~laser43

return M