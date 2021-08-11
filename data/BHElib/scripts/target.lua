---------------------------------------------------------------------------------------------------
---target.lua
---date: 2021.7.15
---reference: -x/data/THlib/player/player.lua
---desc: This file defines functions that find target(s) for movement/attack
---------------------------------------------------------------------------------------------------

---@class scripts.target
local M = {}

---------------------------------------------------------------------------------------------------
---cache functions and variables

local Abs = math.abs

---------------------------------------------------------------------------------------------------

function M.findTargetByAngleWithVerticalLine(source, dest_objects)
    assert(dest_objects, "Error: parameter dest_objects is nil!")
    local target
    local source_x, source_y = source.x, source.y

    local maxpri = -1
    for i = 1, #dest_objects do
        local object = dest_objects[i]

        local dx = source_x - object.x
        local dy = source_y - object.y
        local pri = Abs(dy) / (Abs(dx) + 0.01)
        if pri > maxpri then
            maxpri = pri
            target = object
        end
    end
    return target
end

return M