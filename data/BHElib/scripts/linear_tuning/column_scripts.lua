---------------------------------------------------------------------------------------------------
---ParameterColumnScripts.lua
---author: Karl
---date created: before 2021.4
---desc: Defines some scripts for parameter column
---------------------------------------------------------------------------------------------------

---@class ParameterColumnScripts
local M = {}

---------------------------------------------------------------------------------------------------
---cache variables and functions

local sin = sin
local cos = cos
local Angle = Angle

---------------------------------------------------------------------------------------------------

---center at master
function M.ConstructFollow(x_name, y_name)
    local function Follow(self, next, i)
        local master = self.s_master
        next[x_name], next[y_name] = next[x_name] + master.x, next[y_name] + master.y
    end
    return Follow
end

function M.ConstructOffset(x_name, y_name, off_x_name, off_y_name)
    local function Offset(self, next, i)
        next[x_name], next[y_name] = next[x_name] + next[off_x_name], next[y_name] + next[off_y_name]
    end
    return Offset
end

function M.ConstructPolarVec(x_name, y_name, r_name, a_name)
    local function PolarToStd(self, next, i)
        -- coordinate conversion
        local a, r = next[a_name], next[r_name]
        local x, y = next[x_name] or 0, next[y_name] or 0

        -- assign the results
        next[x_name], next[y_name] = x + r * cos(a), y + r * sin(a)
    end
    return PolarToStd
end

---polar coordinates
function M.ConstructPolar(a_name, r_name, da_name, v_name, x_name, y_name, vx_name, vy_name)
    local function PolarToStd(self, next, i)
        -- coordinate conversion
        local a, r = next[a_name], next[r_name]
        local da, v = next[da_name], next[v_name]

        local x, y = next[x_name] or 0, next[y_name] or 0
        local vx, vy = next[vx_name] or 0, next[vy_name] or 0

        -- assign the results
        next[x_name], next[y_name] = x + r * cos(a), y + r * sin(a)
        next[vx_name], next[vy_name] = vx + v * cos(a + da), vy + v * sin(a + da)
    end
    return PolarToStd
end

---center at master, polar coordinates
function M.ConstructCenterAt(a_name, r_name, da_name, v_name, x_name, y_name, vx_name, vy_name)
    local function PolarToStd(self, next, i)
        -- coordinate conversion
        local a, r = next[a_name], next[r_name]
        local da, v = next[da_name], next[v_name]

        local x, y = next[x_name] or 0, next[y_name] or 0
        local vx, vy = next[vx_name] or 0, next[vy_name] or 0

        -- assign the results
        local master = self.s_master
        next[x_name], next[y_name] = x + r * cos(a) + master.x, y + r * sin(a) + master.y
        next[vx_name], next[vy_name] = vx + v * cos(a + da), vy + v * sin(a + da)
    end
    return PolarToStd
end

function M.ConstructRandom(var_name, val1, val2)
    local function Rand(self, next, i)
        local v = next[var_name] or 0
        next[var_name] = v + ran:Float(val1, val2 or 0)
    end
    return Rand
end

function M.ConstructSetRandomOnCircle(x_name, y_name, radius)
    local function Rand(self, next, i)
        local a = ran:Float(0, 360)
        next[x_name], next[y_name] = cos(a) * radius, sin(a) * radius
    end
    return Rand
end

function M.ConstructOffsetRandomOnCircle(x_name, y_name, radius)
    local function Rand(self, next, i)
        local x, y = next[x_name] or 0, next[y_name] or 0
        local a = ran:Float(0, 360)
        next[x_name], next[y_name] = x + cos(a) * radius, y + sin(a) * radius
    end
    return Rand
end

function M.ConstructAimFromPos(x_name, y_name, a_name)
    local function Aim(self, next, i)
        local x, y = next[x_name] or 0, next[y_name] or 0
        local a = (next[a_name] or 0) + Angle(x, y, player.x, player.y)
        next[a_name] = a
    end
    return Aim
end

---assign a value to an attribute, remove the attribute where the value comes from
function M.ConstructReplace(replaced_name, value_name)
    local function Replace(self, next, i)
        local v = next[value_name]
        next[value_name] = nil  -- remove the value attribute

        -- assign the new value
        next[replaced_name] = (next[replaced_name] or 0) + v
    end
    return Replace
end

---@param var_name string
---@param mirror_value number the variable will be mirrored against this value when i is even
---@param i_name string specifies the variable to use as i; will use the current iterator if nil
function M.ConstructMirror(var_name, mirror_value, i_name)
    mirror_value = mirror_value or 0

    local Mirror
    if i_name then
        function Mirror(self, next, i)
            if next[i_name] % 2 == 1 then
                local v = next[var_name] or mirror_value
                next[var_name] = mirror_value * 2 - v
            end
        end
    else
        function Mirror(self, next, i)
            if i % 2 == 1 then
                local v = next[var_name] or mirror_value
                next[var_name] = mirror_value * 2 - v
            end
        end
    end
    return Mirror
end

function M.ConstructAdd(target_name, add_name)
    local function Add(self, next, i)
        local v = next[add_name]
        next[target_name] = (next[target_name] or 0) + v
    end
    return Add
end

function M.ConstructSet(var_name, value)
    local function Set(self, next, i)
        next[var_name] = value
    end
    return Set
end

---rotate around p
function M.ConstructRotation(x_name, y_name, angle)
    local cos_a = cos(angle)
    local sin_a = sin(angle)
    local function Rot(self, next, i)
        local x = next[x_name] or 0
        local y = next[y_name] or 0
        next[x_name] = x * cos_a - y * sin_a
        next[y_name] = x * sin_a + y * cos_a
    end
    return Rot
end

---------------------------------------------------------------------------------------------------
---non-constructive methods

function M.SetI(self, next, i)
    next.i = i
end
function M.SetJ(self, next, i)
    next.j = i
end
function M.SetK(self, next, i)
    next.k = i
end

---------------------------------------------------------------------------------------------------
---default callbacks

M.DefaultFollow = M.ConstructFollow("x", "y")
M.DefaultPolarPos = M.ConstructPolarVec("x", "y", "r", "ra")
M.DefaultPolarVelocity = M.ConstructPolarVec("vx", "vy", "v", "a")

return M