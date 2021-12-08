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
local sqrt = sqrt
local log = math.log
local Angle = Angle

---------------------------------------------------------------------------------------------------
---accessing and modifying variables

local function GetSetter(var)
    assert(type(var) == "string", "Error: Invalid variable type!")

    local prefix = string.sub(var, 1, 2)

    local var_name
    if prefix == "c_" then  -- "current"
        var_name = string.sub(var, 3, -1)
        return function(cur, next, value)
            cur[var_name] = value
        end
    elseif prefix == "p_" then
        var_name = string.sub(var, 3, -1)
        return function(cur, next, value)
            player[var_name] = value
        end
    else
        var_name = var
        return function(cur, next, value)
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
                return function(cur, next, i)
                    return cur
                end
            end
            var_name = string.sub(var, 3, -1)
            return function(cur, next, i)
                return cur[var_name] or 0
            end
        elseif prefix == "n_" then  -- "next"
            if var == "n_" then
                return function(cur, next, i)
                    return next
                end
            end
            var_name = string.sub(var, 3, -1)
            return function(cur, next, i)
                return next[var_name] or 0
            end
        elseif prefix == "p_" then  -- "player"
            var_name = string.sub(var, 3, -1)
            return function(cur, next, i)
                return player[var_name]
            end
        elseif prefix == "m_" then  -- "master"
            var_name = string.sub(var, 3, -1)
            return function(cur, next, i)
                return cur.s_master[var_name]
            end
        elseif prefix == "i_" then
            return function(cur, next, i)
                return i
            end
        else
            -- same as n_
            var_name = var
            return function(cur, next, i)
                return next[var_name] or 0
            end
        end
    else
        error("Error: Invalid variable type!")
    end
end

---takes a column script constructor with first parameter as input parameter and return a matrix script
---@param construct_column_script function a constructor that can construct a column script
function M.MakeMatrixScript(construct_column_script)
    local function MatrixEntryScript(...)
        local params = {...}
        local function Constructor(var_name)
            return construct_column_script(var_name, unpack(params))
        end
        return Constructor
    end
    return MatrixEntryScript
end
---takes a column script constructor with first parameter as input parameter and return a matrix script
---@param construct_column_script function a constructor that can construct a column script
M.MakeNextScript = M.MakeMatrixScript
---takes a column script constructor with first parameter as input parameter and return a matrix script
---@param construct_column_script function a constructor that can construct a column script
function M.MakeCurScript(construct_column_script)
    local function MatrixEntryScript(...)
        local params = {...}
        local function Constructor(var_name)
            return construct_column_script("c_"..var_name, unpack(params))
        end
        return Constructor
    end
    return MatrixEntryScript
end

---------------------------------------------------------------------------------------------------

---center at master
function M.ConstructFollow(x_name, y_name)
    local function Follow(cur, next, i)
        local master = cur.s_master
        next[x_name], next[y_name] = next[x_name] + master.x, next[y_name] + master.y
    end
    return Follow
end

function M.ConstructOffset(x_name, y_name, off_x_name, off_y_name)
    local function Offset(cur, next, i)
        next[x_name], next[y_name] = next[x_name] + next[off_x_name], next[y_name] + next[off_y_name]
    end
    return Offset
end

function M.ConstructPolarVec(x_name, y_name, r_name, a_name)
    local function PolarToStd(cur, next, i)
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
    local function PolarToStd(cur, next, i)
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
    local function PolarToStd(cur, next, i)
        -- coordinate conversion
        local a, r = next[a_name], next[r_name]
        local da, v = next[da_name], next[v_name]

        local x, y = next[x_name] or 0, next[y_name] or 0
        local vx, vy = next[vx_name] or 0, next[vy_name] or 0

        -- assign the results
        local master = cur.s_master
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

    local function Rand(cur, next, i)
        local v = var_getter(cur, next, i)
        local v1, v2 = val1_getter(cur, next, i), val2_getter(cur, next, i)
        v = v + ran:Float(v1, v2)
        var_setter(cur, next, v)
    end
    return Rand
end

---Box-Muller algorithm for generating pairs of observations from normal variables
function M.ConstructRandomNormal(var, sigma)
    local var_setter = GetSetter(var)
    local var_getter = GetGetter(var)
    local sigma_getter = GetGetter(sigma)

    local function RandNormal(cur, next, i)
        local u, v = ran:Float(-1, 1), ran:Float(-1, 1)
        local s = u * u + v * v
        while s == 0 or s >= 1 do
            u, v = ran:Float(-1, 1), ran:Float(-1, 1)
            s = u * u + v * v
        end
        s = sqrt(-2 * log(s) / s)
        var_setter(cur, next, var_getter(cur, next, i) + u * s * sigma_getter(cur, next, i))
    end
    return RandNormal
end

function M.ConstructRestrictedRandomNormal(var, sigma, minv, maxv)
    local var_setter = GetSetter(var)
    local var_getter = GetGetter(var)
    local sigma_getter = GetGetter(sigma)
    local minv_getter = GetGetter(minv)
    local maxv_getter = GetGetter(maxv)

    local function RandNormal(cur, next, i)
        local u, v = ran:Float(-1, 1), ran:Float(-1, 1)
        local s = u * u + v * v
        while s == 0 or s >= 1 do
            u, v = ran:Float(-1, 1), ran:Float(-1, 1)
            s = u * u + v * v
        end
        s = sqrt(-2 * log(s) / s)
        local f = var_getter(cur, next, i) + u * s * sigma_getter(cur, next, i)
        local min_v = minv_getter(cur, next, i)
        local max_v = maxv_getter(cur, next, i)
        if f < min_v then
            f = min_v * 2 - f
        elseif f > max_v then
            f = max_v * 2 - f
        end
        var_setter(cur, next, f)
    end
    return RandNormal
end

function M.ConstructOffsetRandomOnCircle(x_name, y_name, x_radius, y_radius)
    local radius_getter = GetGetter(x_radius)
    local y_radius_getter
    if y_radius then
        y_radius_getter = GetGetter(y_radius)
    else
        y_radius_getter = radius_getter
    end
    local x_setter = GetSetter(x_name)
    local y_setter = GetSetter(y_name)
    local x_getter = GetGetter(x_name)
    local y_getter = GetGetter(y_name)

    local function Rand(cur, next, i)
        local x, y = x_getter(cur, next, i), y_getter(cur, next, i)
        local a = ran:Float(0, 360)
        local r = radius_getter(cur, next, i)
        local y_r = y_radius_getter(cur, next, i)
        x_setter(cur, next, x + cos(a) * r)
        y_setter(cur, next, y + sin(a) * y_r)
    end
    return Rand
end

function M.ConstructAimFromPos(a_name, x_name, y_name)
    local a_setter = GetSetter(a_name)
    local a_getter = GetGetter(a_name)
    local x_getter = GetGetter(x_name)
    local y_getter = GetGetter(y_name)

    local function Aim(cur, next, i)
        local x, y = x_getter(cur, next, i), y_getter(cur, next, i)

        local a = a_getter(cur, next, i) + Angle(x, y, player.x, player.y)
        a_setter(cur, next, a)
    end
    return Aim
end

---assign a value to an attribute
---"a = b [+ c [* d]] "
function M.ConstructSet(replaced_name, value_name, add_name, mul_name)
    local r_setter = GetSetter(replaced_name)
    local v_getter = GetGetter(value_name)

    local Replace

    if add_name and mul_name then
        local a_getter = GetGetter(add_name)
        local m_getter = GetGetter(mul_name)
        function Replace(cur, next, i)
            r_setter(cur, next, v_getter(cur, next, i) + a_getter(cur, next, i) * m_getter(cur, next, i))
        end
    elseif add_name then
        local a_getter = GetGetter(add_name)
        function Replace(cur, next, i)
            r_setter(cur, next, v_getter(cur, next, i) + a_getter(cur, next, i))
        end
    else
        function Replace(cur, next, i)
            r_setter(cur, next, v_getter(cur, next, i))
        end
    end

    return Replace
end

function M.ConstructRange(target_var, begin_var, end_var)
    end_var = end_var or 0
    local t_setter = GetSetter(target_var)
    local t_getter = GetGetter(target_var)
    local b_getter = GetGetter(begin_var)
    local e_getter = GetGetter(end_var)
    local function Range(cur, next, i)
        local v = b_getter(cur, next, i)
        local d_v = e_getter(cur, next, i) - v
        local t = t_getter(cur, next, i)
        local n = cur.s_n
        if n <= 1 then
            t_setter(cur, next, t + v + d_v * 0.5)
        else
            t_setter(cur, next, t + v + d_v * i / (n - 1))
        end
    end
    return Range
end

function M.ConstructRangeExcludeA(target_var, begin_var, end_var)
    end_var = end_var or 0
    local t_setter = GetSetter(target_var)
    local t_getter = GetGetter(target_var)
    local b_getter = GetGetter(begin_var)
    local e_getter = GetGetter(end_var)
    local function Range(cur, next, i)
        local v = b_getter(cur, next, i)
        local d_v = e_getter(cur, next, i) - v
        local t = t_getter(cur, next, i)
        local n = cur.s_n
        if n <= 1 then
            t_setter(cur, next, t + v + d_v)
        else
            t_setter(cur, next, t + v + d_v * (i + 1) / n)
        end
    end
    return Range
end

function M.ConstructRangeExcludeB(target_var, begin_var, end_var)
    end_var = end_var or 0
    local t_setter = GetSetter(target_var)
    local t_getter = GetGetter(target_var)
    local b_getter = GetGetter(begin_var)
    local e_getter = GetGetter(end_var)
    local function Range(cur, next, i)
        local v = b_getter(cur, next, i)
        local d_v = e_getter(cur, next, i) - v
        local t = t_getter(cur, next, i)
        local n = cur.s_n
        if n <= 1 then
            t_setter(cur, next, t + v)
        else
            t_setter(cur, next, t + v + d_v * i / n)
        end
    end
    return Range
end

function M.ConstructRangeExcludeAB(target_var, begin_var, end_var)
    end_var = end_var or 0
    local t_setter = GetSetter(target_var)
    local t_getter = GetGetter(target_var)
    local b_getter = GetGetter(begin_var)
    local e_getter = GetGetter(end_var)
    local function Range(cur, next, i)
        local v = b_getter(cur, next, i)
        local d_v = e_getter(cur, next, i) - v
        local t = t_getter(cur, next, i)
        local n = cur.s_n
        if n <= 1 then
            t_setter(cur, next, t + v + d_v * 0.5)
        else
            t_setter(cur, next, t + v + d_v * (i + 1) / (n + 1))
        end
    end
    return Range
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
        function Mirror(cur, next, i)
            if i_getter(cur, next, i) % 2 == 1 then
                local v = var_getter(cur, next, i)
                local mir = mirror_getter(cur, next, i)
                var_setter(cur, next, mir * 2 - v)
            end
        end
    else
        function Mirror(cur, next, i)
            if i % 2 == 1 then
                local v = var_getter(cur, next, i)
                local mir = mirror_getter(cur, next, i)
                var_setter(cur, next, mir * 2 - v)
            end
        end
    end
    return Mirror
end

---a += b [* c]
function M.ConstructAdd(target_var, add_var, mul_var)
    local t_setter = GetSetter(target_var)
    local t_getter = GetGetter(target_var)
    local a_getter = GetGetter(add_var)

    if mul_var then
        local m_getter = GetGetter(mul_var)
        local function Add(cur, next, i)
            local v = a_getter(cur, next, i) * m_getter(cur, next, i)
            local original_value = t_getter(cur, next, i)
            t_setter(cur, next,original_value + v)
        end
        return Add
    else
        local function Add(cur, next, i)
            local v = a_getter(cur, next, i)
            local original_value = t_getter(cur, next, i)
            t_setter(cur, next,original_value + v)
        end
        return Add
    end
end

function M.ConstructMultiply(target_var, mul_var)
    local t_setter = GetSetter(target_var)
    local t_getter = GetGetter(target_var)
    local m_getter = GetGetter(mul_var)

    local function Mul(cur, next, i)
        local v = m_getter(cur, next, i)
        local original_value = t_getter(cur, next, i)
        t_setter(cur, next,original_value * v)
    end
    return Mul
end

---rotate around O
function M.ConstructRotation(x_name, y_name, angle)
    local x_setter = GetSetter(x_name)
    local y_setter = GetSetter(y_name)
    local x_getter = GetGetter(x_name)
    local y_getter = GetGetter(y_name)
    local angle_getter = GetGetter(angle)
    local function Rot(cur, next, i)
        local x = x_getter(cur, next, i)
        local y = y_getter(cur, next, i)
        local a = angle_getter(cur, next, i)
        local cos_a = cos(a)
        local sin_a = sin(a)
        x_setter(cur, next, x * cos_a - y * sin_a)
        y_setter(cur, next, x * sin_a + y * cos_a)
    end
    return Rot
end

---------------------------------------------------------------------------------------------------
---non-construct methods

function M.SetI(cur, next, i)
    next.i = i
end
function M.SetJ(cur, next, i)
    next.j = i
end
function M.SetK(cur, next, i)
    next.k = i
end

return M