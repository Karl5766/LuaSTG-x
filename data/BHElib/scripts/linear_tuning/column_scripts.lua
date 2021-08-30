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

function M.ConstructPolarVec(a_name, r_name, x_name, y_name)
    local function PolarToStd(self, next, i)
        -- coordinate conversion
        local a, r = next[a_name], next[r_name]
        local x, y = next[x_name] or 0, next[y_name] or 0
        next[a_name] = nil
        next[r_name] = nil

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
        next[a_name] = nil
        next[r_name] = nil
        next[da_name] = nil
        next[v_name] = nil

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
        next[a_name] = nil
        next[r_name] = nil
        next[da_name] = nil
        next[v_name] = nil

        -- assign the results
        local master = self.s_master
        next[x_name], next[y_name] = x + r * cos(a) + master.x, y + r * sin(a) + master.y
        next[vx_name], next[vy_name] = vx + v * cos(a + da), vy + v * sin(a + da)
    end
    return PolarToStd
end

function M.ConstructRandom(var_name, random_radius)
    local function Rand(self, next, i)
        local v = next[var_name] or 0
        next[var_name] = v + ran:Float(-random_radius, random_radius)
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

---------------------------------------------------------------------------------------------------
---default callbacks

M.DefaultFollow = M.ConstructFollow("x", "y")
M.DefaultPolarPos = M.ConstructPolarVec("a", "r", "x", "y")
M.DefaultPolarVelocity = M.ConstructPolarVec("da", "v", "vx", "vy")
M.DefaultPolar = M.ConstructPolar(
        "a", "r", "da", "v",
        "x", "y", "vx", "vy"
)
M.DefaultCenterAt = M.ConstructCenterAt(
        "a", "r", "da", "v",
        "x", "y", "vx", "vy"
)

return M