---------------------------------------------------------------------------------------------------
---view3d.lua
---date: 2021.8.13
---references: -x/src/core/view.lua, -x/src/core/screen.lua
---desc: Defines View3d, storing parameters for the 3d camera
---------------------------------------------------------------------------------------------------

---@class View3d
local M = LuaClass("View3d")

---------------------------------------------------------------------------------------------------
---init

function M.__create()
    return {}
end

function M:ctor()
    self:reset()
end

---------------------------------------------------------------------------------------------------
---modifiers

---重置self的值 | reset the value of view3d
function M:reset()
    self.eye = { 0, 0, -1 }                  -- camera position
    self.at = { 0, 0, 0 }                    -- camera target position
    self.up = { 0, 1, 0 }                    -- camera up, used for determining the orientation of the camera
    self.fovy = PI_2                         -- controls size of spherical view field in vertical direction (in radians)
    self.z = { 1, 2 }                        -- clipping plane, {near, far}
    self.fog = { 0, 0, Color(0x00000000) }   -- fog param, {start, end, color}
    self.dirty = true                        -- a flag set to true if any of the above attribute(s) has changed via api
end

---设置self的值 | set one attribute of view3d
---@param key string specifies which attribute to set; will set the value of self[key]
---@param a number parameter
---@param b number additional parameter if needed
---@param c number|lstg.Color additional parameter if needed
function M:set3D(key, a, b, c)
    if key == "fog" then
        a = tonumber(a or 0)
        b = tonumber(b or 0)
        self.fog = { a, b, c }
        return
    end
    a = tonumber(a or 0)
    b = tonumber(b or 0)
    c = tonumber(c or 0)
    if key == "eye" then
        self.eye = { a, b, c }
    elseif key == "at" then
        self.at = { a, b, c }
    elseif key == "up" then
        self.up = { a, b, c }
    elseif key == "fovy" then
        self.fovy = a
    elseif key == "z" then
        self.z = { a, b }
    end
    self.dirty = true
end

---------------------------------------------------------------------------------------------------
---debugging

function M:getStringRepr()
    local eye_str = string.format(
            'eye: (%.1f, %.1f, %.1f)',
            self.eye[1], self.eye[2], self.eye[3])
    local at_str = string.format(
            'at: (%.1f, %.1f, %.1f)',
            self.at[1], self.at[2], self.at[3])
    local up_str = string.format(
            'up: (%.1f, %.1f, %.1f)',
            self.up[1], self.up[2], self.up[3])
    local fovy_z_str = string.format(
            'fovy: %.2f z: (%.1f, %.1f)',
            self.fovy, self.z[1], self.z[2])
    local fog = self.fog
    local fog_str = string.format(
            'fog: (%.2f, %.2f) with color (%.2f, %.2f, %.2f)',
            fog[1], fog[2], fog[3][1], fog[3][2], fog[3][3])
    local ret = string.format(
            "%s\n%s\n%s\n%s\n%s",
            eye_str, at_str, up_str, fovy_z_str, fog_str)
    return ret
end

return M