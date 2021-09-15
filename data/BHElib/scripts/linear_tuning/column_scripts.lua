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
---accessing and modifying variables

local function GetSetter(var)
    assert(type(var) == "string", "Error: Invalid variable type!")

    local var_name
    if string.sub(var, 1, 2) == "p_" then
        var_name = string.sub(var, 3, -1)
        return function(self, next, value)
            self[var_name] = value
        end
    else
        var_name = var
        return function(self, next, value)
            next[var_name] = value
        end
    end
end

local function GetGetter(var)
    if type(var) == "number" then
        return function()
            return var
        end
    elseif type(var) == "string" then
        local var_name
        if string.sub(var, 1, 2) == "p_" then
            var_name = string.sub(var, 3, -1)
            return function(self, next)
                return self[var_name] or 0
            end
        else
            var_name = var
            return function(self, next)
                return next[var_name] or 0
            end
        end
    else
        error("Error: Invalid variable type!")
    end
end

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

function M.ConstructAimFromPos(a_name, x_name, y_name)
    local a_setter = GetSetter(a_name)
    local a_getter = GetGetter(a_name)
    local x_getter = GetGetter(x_name)
    local y_getter = GetGetter(y_name)

    local function Aim(self, next, i)
        local x, y = x_getter(self, next), y_getter(self, next)

        local a = a_getter(self, next) + Angle(x, y, player.x, player.y)
        a_setter(self, next, a)
    end
    return Aim
end

---assign a value to an attribute, remove the attribute where the value comes from
function M.ConstructReplace(replaced_name, value_name)
    local r_setter = GetSetter(replaced_name)
    local v_getter = GetGetter(value_name)

    local function Replace(self, next, i)
        r_setter(self, next, v_getter(self, next))
    end
    return Replace
end
M.ConstructSet = M.ConstructReplace

---@param var string
---@param mirror_var number the variable will be mirrored against this value when i is even
---@param i_var string specifies the variable to use as i; will use the current iterator if nil
function M.ConstructMirror(var, mirror_var, i_var)
    local var_setter = GetSetter(var)
    local var_getter = GetGetter(var)
    local mirror_getter = GetGetter(mirror_var)

    local Mirror
    if i_var then
        local i_getter = GetGetter(i_var)
        function Mirror(self, next, i)
            if i_getter(self, next) % 2 == 1 then
                local v = var_getter(self, next)
                local mir = mirror_getter(self, next)
                var_setter(self, next, mir * 2 - v)
            end
        end
    else
        function Mirror(self, next, i)
            if i % 2 == 1 then
                local v = var_getter(self, next)
                local mir = mirror_getter(self, next)
                var_setter(self, next, mir * 2 - v)
            end
        end
    end
    return Mirror
end

function M.ConstructAdd(target_var, add_var)
    local target_setter = GetSetter(target_var)
    local add_getter = GetGetter(add_var)
    local target_getter = GetGetter(target_var)

    local function Add(self, next, i)
        local v = add_getter(self, next)
        target_setter(self, next,target_getter(self, next) + v)
    end
    return Add
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
---non-construct methods

function M.SetI(self, next, i)
    next.i = i
end
function M.SetJ(self, next, i)
    next.j = i
end
function M.SetK(self, next, i)
    next.k = i
end

return M