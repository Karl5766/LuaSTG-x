---------------------------------------------------------------------------------------------------
---move_animated_enemy_type.lua
---author: Karl
---date created: 2021.8.19
---desc: Defines an enemy animation type that can display idle animation and movement animation
---------------------------------------------------------------------------------------------------

local EnemyTypeClass = require("BHElib.units.enemy.enemy_type.enemy_type_class")

---@class MoveAnimatedEnemyType:EnemyTypeClass
local M = LuaClass("MoveAnimatedEnemyType", EnemyTypeClass)

local MoveAnimation = require("BHElib.units.animation.move_animation")
local EndCallbacks = require("BHElib.units.animation.animation_end_callbacks")

---------------------------------------------------------------------------------------------------

local DefaultRenderFunc = DefaultRenderFunc

---------------------------------------------------------------------------------------------------
---init

---@param base_hscale number the base factor for hscale
---@param idle_ani table<string,number,number> the image array to play in idle
---@param move_left_ani table<string,number,number> the image array to play moving left; if nil, will use move_right_ani
---@param move_right_ani table<string,number,number> the image array to play moving right; if nil, will use move_left_ani
---@param idle_interval number time between adjacent images of idle animation
---@param move_transition_interval number
---@param move_interval number
function M.__create(
        color_theme,
        use_aura,
        use_kill_effect,
        use_spin_image,
        default_radius,
        base_hscale,
        idle_ani,
        move_left_ani,
        move_right_ani,
        move_transition_end_index,
        idle_interval,
        move_transition_interval,
        move_interval)
    local self = EnemyTypeClass.__create(color_theme, use_aura, use_kill_effect, use_spin_image, default_radius)

    self.base_hscale = base_hscale
    self.idle_ani = idle_ani
    if move_left_ani then
        self.move_left_transition_ani = {move_left_ani[1], move_left_ani[2], move_transition_end_index}
        self.move_left_ani = {move_left_ani[1],  move_transition_end_index + 1, move_left_ani[3]}
        self.move_left_transition_end_callback = EndCallbacks.playAnotherAnimation(
                self.move_left_ani, move_interval, true, 0, EndCallbacks.repeatAgain)
    end
    if move_right_ani then
        self.move_right_transition_ani = {move_right_ani[1], move_right_ani[2], move_transition_end_index}
        self.move_right_ani = {move_right_ani[1],  move_transition_end_index + 1, move_right_ani[3]}
        self.move_right_transition_end_callback = EndCallbacks.playAnotherAnimation(
                self.move_right_ani, move_interval, true, 0, EndCallbacks.repeatAgain)
    end

    self.idle_interval = idle_interval
    self.move_transition_interval = move_transition_interval
    self.move_interval = move_interval

    return self
end

---------------------------------------------------------------------------------------------------
---on object init

---@param object Prefab.Object
function M:onInit(object)
    EnemyTypeClass.onInit(self, object)
    local animation = MoveAnimation(
            self.base_hscale,
            self.idle_ani,
            self.move_left_transition_ani,
            self.move_right_transition_ani)
    animation:playIdleAnimation(self.idle_interval)
    object.animation = animation
end

---@param object Prefab.Object
function M:onFrame(object)
    EnemyTypeClass.onFrame(self, object)
    local animation = object.animation
    animation:update(1)
end

function M:onRender(object)
    EnemyTypeClass.onRender(self, object)
    ---@type MoveAnimation
    local animation = object.animation
    object.hscale = animation:getHscale()
    object.img = animation:getSprite()
    DefaultRenderFunc(object)
end

---@param object Prefab.Object
---@param time number the time from the start of movement to a full stop (may not be the same as move animation time)
---@param is_left boolean if true, play move-left animation; otherwise play move-right animation
function M:onMove(object, time, is_left)
    local animation = object.animation
    local end_callback
    if is_left then
        if self.move_left_transition_ani then
            end_callback = self.move_left_transition_end_callback
        else
            end_callback = self.move_right_transition_end_callback
        end
    else
        if self.move_right_transition_ani then
            end_callback = self.move_right_transition_end_callback
        else
            end_callback = self.move_left_transition_end_callback
        end
    end
    animation:playMirroredMovementAnimation(
            self.move_interval,
            self.idle_interval,
            time,
            is_left,
            end_callback)
end

return M