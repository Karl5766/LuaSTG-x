---------------------------------------------------------------------------------------------------
---iter_types.lua
---author: Karl
---date created: 2021.11.4
---desc: Provides interfaces for live iterations of types and colors
---------------------------------------------------------------------------------------------------

---@class IterTypes
local M = {}

local HotIter = require("BHElib.scripts.iter.hot_iter")
local MIN_BOUND = 5
local BOUND_EXPAND_FACTOR = 1.6
local Color = require("BHElib.unclassified.color")
local BulletTypes = require("BHElib.units.bullet.bullet_types")

---------------------------------------------------------------------------------------------------

local function OnInit(registerer, bullet)
    registerer:set(bullet)
    local bullet_list = registerer.bullet_list

    local n = #bullet_list + 1
    bullet_list[n] = bullet

    bullet_list.bound = bullet_list.bound or MIN_BOUND
    if n > bullet_list.bound then
        local num_exist = 0  -- actual number of existing bullets
        -- remove invalid bullets in-place
        for i = 1, n do
            if IsValid(bullet_list[i]) then
                num_exist = num_exist + 1
                bullet_list[num_exist] = bullet_list[i]
            end
        end
        for i = n, num_exist + 1, -1 do
            bullet_list[i] = nil
        end
        bullet_list.bound = max(MIN_BOUND, math.ceil(num_exist * BOUND_EXPAND_FACTOR))
    end
end

local function AddLiveRegisterer(hot_iter, label, registerer)
    local bullets = registerer.bullet_list

    local listener = function(iter, broadcast_label, value)
        if hot_iter == iter and label == broadcast_label then

            registerer.value = value
            for i = 1, #bullets do
                local bullet = bullets[i]
                if IsValid(bullet) then
                    registerer:set(bullet)
                end
            end
        end
    end

    hot_iter:addRegisterer(label, registerer)
    hot_iter:addListener(listener)
end

local function AutoAddLiveRegisterer(hot_iter, label, set)
    local registerer = {
        is_registerer = true,
        value = hot_iter:getValue(label),
        set = set,
        on_init = OnInit,
        bullet_list = {},
    }
    AddLiveRegisterer(hot_iter, label, registerer)
end

local function Add1dTypeIter(hot_iter, label, array, is_live, set, init_index)
    hot_iter:registerWithListener(label, array, nil, init_index)
    if is_live then
        AutoAddLiveRegisterer(hot_iter, label, set)
    else
        hot_iter:addListener(HotIter.ReloadOnChange(label))
    end
end

local function Add2dTypeIter(hot_iter, label, matrix, is_live, set, init_col, init_row)
    hot_iter:registerMatrixWithListener(label, matrix, nil, init_col, init_row)
    if is_live then
        AutoAddLiveRegisterer(hot_iter, label, set)
    else
        hot_iter:addListener(HotIter.ReloadOnChange(label))
    end
end

---------------------------------------------------------------------------------------------------

---@param hot_iter HotIter
function M:addBulletColorIter(hot_iter, label, colors, is_live, init_index)
    local function set(registerer, bullet)
        bullet:changeColorIndexTo(registerer.value)
    end
    Add1dTypeIter(hot_iter, label, colors or Color.all_color_indices,
                is_live == nil or is_live, set, init_index)
end

---@param hot_iter HotIter
function M:addBulletTypeIter(hot_iter, label, types, is_live, init_index)
    local function set(registerer, bullet)
        bullet:changeBulletTypeTo(registerer.value)
    end
    Add1dTypeIter(hot_iter, label, colors or BulletTypes.all_bullet_types,
            is_live == nil or is_live, set, init_index)
end

---@param hot_iter HotIter
function M:addBulletTypeColorIter(hot_iter, label, color_types, is_live, init_col, init_row)
    local function set(registerer, bullet)
        local v = registerer.value
        bullet:changeSpriteTo(v[1], v[2])
    end
    Add2dTypeIter(hot_iter, label, color_types or BulletTypes.all_bullet_type_color,
            is_live == nil or is_live, set, init_col, init_row)
end

return M