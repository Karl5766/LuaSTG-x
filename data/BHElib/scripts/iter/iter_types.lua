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

local function GetOnInitFunction(bullet_list)
    local function OnInit(bullet)
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
    return OnInit
end

---@param hot_iter HotIter
function M:addBulletColorIter(hot_iter, label, colors, init_index, is_live)
    if is_live == nil then
        is_live = true
    end
    colors = colors or Color.all_color_indices

    local listener
    if is_live then
        local registerers = {}
        local bullets = {}

        local on_init = GetOnInitFunction(bullets)
        for i, color_index in ipairs(colors) do
            registerers[i] = {
                is_registerer = true,
                on_init = on_init,
                color_index = color_index,
            }
        end

        listener = function(iter, broadcast_label, registerer)
            if hot_iter == iter and label == broadcast_label then
                for i, bullet in ipairs(bullets) do
                    if IsValid(bullet) then
                        bullet:changeColorIndexTo(registerer.color_index)
                    end
                end
            end
        end

        hot_iter:register(label, registerers, init_index, listener)
    else
        hot_iter:register(label, colors, init_index, listener)
        listener = HotIter.ReloadOnChange(label)
    end
end

---@param hot_iter HotIter
function M:addBulletTypeIter(hot_iter, label, types, init_index, is_live)
    if is_live == nil then
        is_live = true
    end
    types = types or BulletTypes.all_bullet_types

    local listener
    if is_live then
        local registerers = {}
        local bullets = {}

        local on_init = GetOnInitFunction(bullets)
        for i, bullet_type_name in ipairs(types) do
            registerers[i] = {
                is_registerer = true,
                on_init = on_init,
                bullet_type_name = bullet_type_name,
            }
        end

        listener = function(iter, broadcast_label, registerer)
            if hot_iter == iter and label == broadcast_label then
                for i, bullet in ipairs(bullets) do
                    if IsValid(bullet) then
                        bullet:changeBulletTypeTo(registerer.bullet_type_name)
                    end
                end
            end
        end

        hot_iter:register(label, registerers, init_index, listener)
    else
        hot_iter:register(label, types, init_index, listener)
        listener = HotIter.ReloadOnChange(label)
    end
end

---@param hot_iter HotIter
function M:addBulletColorTypeIter(hot_iter, label, color_types, init_col, init_row, is_live)
    if is_live == nil then
        is_live = true
    end
    if color_types == nil then
        color_types = {}
        for i = 1, #Color.all_color_indices do
            color_types[i] = {}
            for j = 1, #BulletTypes.all_bullet_types do
                color_types[i][j] = {BulletTypes.all_bullet_types[j], Color.all_color_indices[i]}
            end
        end
    end

    local listener
    if is_live then
        local registerers = {}
        local bullets = {}

        local on_init = GetOnInitFunction(bullets)
        for i, row in ipairs(color_types) do
            registerers[i] = {}
            for j, color_type in ipairs(row) do
                registerers[i][j] = {
                    is_registerer = true,
                    on_init = on_init,
                    bullet_type_name = color_type[1],
                    color_index = color_type[2],
                }
            end
        end

        listener = function(iter, broadcast_label, registerer)
            if hot_iter == iter and label == broadcast_label then
                for i, bullet in ipairs(bullets) do
                    if IsValid(bullet) then
                        bullet:changeSpriteTo(registerer.bullet_type_name, registerer.color_index)
                    end
                end
            end
        end

        hot_iter:registerMatrix(label, registerers, init_col, init_row, listener)
    else
        hot_iter:registerMatrix(label, color_types, init_col, init_row, listener)
        listener = HotIter.ReloadOnChange(label)
    end
end

return M