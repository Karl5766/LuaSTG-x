---------------------------------------------------------------------------------------------------
---parameter_column.lua
---author: Karl
---date created: before 2021
---desc: Defines a parameter column
---------------------------------------------------------------------------------------------------

---@class ParameterColumn
local M = LuaClass("ParameterColumn")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local ipairs = ipairs
local pairs = pairs
local type = type
local StringByte = string.byte
local setmetatable = setmetatable
local getmetatable = getmetatable
local TaskNew = task.New
local MantissaTimer = require("BHElib.scripts.linear_tuning.mantissa_timer")

---------------------------------------------------------------------------------------------------
---init

---@param master Prefab.Object
---@param name string
---@param s_next ParameterColumn
function M.__create(master, name, s_next)
    -- Construct a standard DPC instance

    local self = {}

    self.s_master = master
    self.s_next = {s_next}
    self.s_name = name  -- for debug use
    self.s_control = "s_n"
    self.s_script = nil  -- functions run before sparking to the next object
    self.s_n = 1

    return self
end

---------------------------------------------------------------------------------------------------
---modifiers

---add a script to be executed each spark
function M:addScript(script)
    self.s_script = self.s_script or {}
    local scripts = self.s_script
    scripts[#scripts + 1] = script
end

---@param s_next table an array of next columns
function M:setNextList(s_next)
    -- set a list of chain object as successors
    self.s_next = s_next
end

---append a DPC object to the end of spark list
function M:add(s_next)
    -- add a chain object as successor
    local next_list = self.s_next
    next_list[#next_list + 1] = s_next
end

---------------------------------------------------------------------------------------------------
---copying

function M:copy()
    -- return a copy of current object with attributes' values copied
    local cp = setmetatable({}, getmetatable(self))
    for k, v in pairs(self) do
        cp[k] = v
    end
    return cp
end

function M:get_volatile_instance()
    if not self.s_backup then
        return self:spark_backup()
    else
        return self
    end
end

---------------------------------------------------------------------------------------------------

function M:spark_to(s_next)
    -- spark interval = 0

    local controlVarName = self.s_control
    local n = self[controlVarName]

    -- spark s_next n times
    for j = 0, n - 1 do
        -- to avoid synchronous modification caused by calling a function while
        -- it is still running, copy the next object
        local cp = s_next:copy()

        for k, v in pairs(self) do
            -- Find attributes that are not functions and not start with "#_"
            if type(v) ~= "function" and StringByte(k, 2) ~= 95 then
                if type(v) == "number" then
                    local inc = self["d_"..k]
                    if inc then
                        v = v + inc * j
                    end
                    local output = self["o_"..k] or k
                    cp[output] = v
                else
                    local output = self["o_"..k] or k
                    cp[output] = v
                end
            end
        end
        local scripts = self.s_script
        for i = 1, #scripts do
            local script = scripts[i]
            script(self, cp, j)
        end
        cp:spark()
    end
end

local function AsyncSpark(self, timer, j, pj, ij, s_next, dt_positive)
    --timer:wait(0)
    -- spark s_next n times
    while j ~= pj do
        local cp = s_next:copy()

        for i, v in pairs(self) do
            -- Find attributes that are not functions and not start with "#_"
            if type(v) ~= "function" and StringByte(i, 2) ~= 95 then
                local base, inc = v, self["d_"..i]
                if inc then
                    base = base + inc * j
                end

                local output = self["o_"..i] or i
                cp[output] = base
            end
        end

        cp.s_t = (cp.s_t or 0) - timer:mantissa()
        local scripts = self.s_script
        if scripts then
            for i = 1, #scripts do
                local script = scripts[i]
                script(self, cp, j)
            end
        end
        cp:spark()

        local dt = self.s_dt
        if dt_positive then
            timer:wait(dt)
        else
            timer:wait(-dt)
        end
        j = j + ij
    end
end

function M:async_spark_to(s_next)
    -- spark interval ~= 0

    local controlVarName = self.s_control
    local n = self[controlVarName]

    -- dt is the interval time between two sparks
    local dt = self.s_dt or 0
    local dt_positive = dt >= 0
    ---@type MantissaTimer
    local timer = MantissaTimer(self.s_t or 0)

    local j, ij, pj = 0, 1, n
    if dt < 0 then
        -- special case, loop in the reversed order
        j, ij, pj = n - 1, -1, -1
    end

    TaskNew(self.s_master, function()
        AsyncSpark(self, timer, j, pj, ij, s_next, dt_positive)
    end)
end

function M:spark()

    -- spark the chain
    local backup = self:get_volatile_instance()  -- protect against user modification

    if backup.s_t or backup.s_dt then
        for _, next_column in ipairs(backup.s_next) do
            backup:async_spark_to(next_column)
        end
    else
        for _, next_column in ipairs(backup.s_next) do
            backup:spark_to(next_column)
        end
    end
end

---create a copy of the whole chain start from this object
---@param backupList table a table of backup objects, if this is the head of the chain, then this should be an empty
---@return ParameterColumn reference to a copy of this object
function M:spark_backup(backupList)
    backupList = backupList or {}

    local cp = self:copy()
    local s_next = {}
    for i, obj in ipairs(self.s_next) do
        if backupList[obj] == nil then
            -- if the next object is not in list, create backup of the object
            local next_col = obj:spark_backup(backupList)
            next_col.s_backup = true  -- is backup
            s_next[i] = next_col
        else
            s_next[i] = backupList[obj]
        end
    end
    cp.s_next = s_next
    backupList[self] = cp

    return cp
end

---------------------------------------------------------------------------------------------------
---debugging

-- send an error message listing all attributes of the table
function M:error_debug_info()
    local message = "object states:"
    for k, v in pairs(self) do
        message = message.."\n"..tostring(k)..":"..tostring(v)
    end
    error(message)
end

return M