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

    local prefix = string.sub(var, 1, 2)

    local var_name
    if prefix == "p_" then
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
        local prefix = string.sub(var, 1, 2)

        local var_name
        if prefix == "c_" then  -- "current"
            if var == "c_" then
                return function(self, next, i)
                    return self
                end
            end
            var_name = string.sub(var, 3, -1)
            return function(self, next, i)
                return self[var_name] or 0
            end
        elseif prefix == "n_" then  -- "next"
            if var == "n_" then
                return function(self, next, i)
                    return next
                end
            end
            var_name = string.sub(var, 3, -1)
            return function(self, next, i)
                return next[var_name] or 0
            end
        elseif prefix == "p_" then  -- "player"
            var_name = string.sub(var, 3, -1)
            return function(self, next, i)
                return player[var_name]
            end
        elseif prefix == "m_" then  -- "master"
            return function(self, next, i)
                return self.s_master[var_name]
            end
        elseif prefix == "i_" then
            return function(self, next, i)
                return i
            end
        else
            -- same as n_
            var_name = var
            return function(self, next, i)
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


function M.ConstructRandom(var, val1, val2)
    val2 = val2 or 0
    local var_setter = GetSetter(var)
    local var_getter = GetGetter(var)
    local val1_getter = GetGetter(val1)
    local val2_getter = GetGetter(val2)

    local function Rand(self, next, i)
        local v = var_getter(self, next, i)
        local v1, v2 = val1_getter(self, next, i), val2_getter(self, next, i)
        v = v + ran:Float(v1, v2)
        var_setter(self, next, v)
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
        local x, y = x_getter(self, next, i), y_getter(self, next, i)

        local a = a_getter(self, next, i) + Angle(x, y, player.x, player.y)
        a_setter(self, next, a)
    end
    return Aim
end

---assign a value to an attribute, remove the attribute where the value comes from
---"a = b [+ c [* d]] "
function M.ConstructSet(replaced_name, value_name, add_name, mul_name)
    local r_setter = GetSetter(replaced_name)
    local v_getter = GetGetter(value_name)

    local Replace

    if add_name and mul_name then
        local a_getter = GetGetter(add_name)
        local m_getter = GetGetter(mul_name)
        function Replace(self, next, i)
            r_setter(self, next, v_getter(self, next, i) + a_getter(self, next, i) * m_getter(self, next, i))
        end
    elseif add_name then
        local a_getter = GetGetter(add_name)
        function Replace(self, next, i)
            r_setter(self, next, v_getter(self, next, i) + a_getter(self, next, i))
        end
    else
        function Replace(self, next, i)
            r_setter(self, next, v_getter(self, next, i))
        end
    end

    return Replace
end

---@param var string
---@param mirror_var number the variable will be mirrored against this value when i is even
---@param i_var string specifies the variable to use as i; will use the current iterator if nil
function M.ConstructMirror(var, mirror_var, i_var)
    mirror_var = mirror_var or 0
    local var_setter = GetSetter(var)
    local var_getter = GetGetter(var)
    local mirror_getter = GetGetter(mirror_var)

    local Mirror
    if i_var then
        local i_getter = GetGetter(i_var)
        function Mirror(self, next, i)
            if i_getter(self, next, i) % 2 == 1 then
                local v = var_getter(self, next, i)
                local mir = mirror_getter(self, next, i)
                var_setter(self, next, mir * 2 - v)
            end
        end
    else
        function Mirror(self, next, i)
            if i % 2 == 1 then
                local v = var_getter(self, next, i)
                local mir = mirror_getter(self, next, i)
                var_setter(self, next, mir * 2 - v)
            end
        end
    end
    return Mirror
end

---a += b [+ c]
function M.ConstructAdd(target_var, add_var, mul_var)
    local t_setter = GetSetter(target_var)
    local t_getter = GetGetter(target_var)
    local a_getter = GetGetter(add_var)

    if mul_var then
        local m_getter = GetGetter(mul_var)
        local function Add(self, next, i)
            local v = a_getter(self, next, i) * m_getter(self, next, i)
            local original_value = t_getter(self, next, i)
            t_setter(self, next,original_value + v)
        end
        return Add
    else
        local function Add(self, next, i)
            local v = a_getter(self, next, i)
            local original_value = t_getter(self, next, i)
            t_setter(self, next,original_value + v)
        end
        return Add
    end
end

function M.ConstructMultiply(target_var, mul_var)
    local t_setter = GetSetter(target_var)
    local t_getter = GetGetter(target_var)
    local m_getter = GetGetter(mul_var)

    local function Mul(self, next, i)
        local v = m_getter(self, next, i)
        local original_value = t_getter(self, next, i)
        t_setter(self, next,original_value * v)
    end
    return Mul
end

---rotate around O
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