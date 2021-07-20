---------------------------------------------------------------------------------------------------
---player_class.lua
---date: 2021.4.12
---desc: This file defines the player class, from which all player sub-classes derive from
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")

---@class PlayerBase
local PlayerBase = Prefab.NewX(Prefab.Object)

local ClockedAnimation = require("BHElib.units.clocked_animation")
local Coordinates = require("BHElib.coordinates_and_screen")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local max = max

---------------------------------------------------------------------------------------------------
---constants

PlayerBase.const = {
    spawn_x = 0,
    spawn_y = -180,
    spawn_time = 80,
    spawn_speed = 1,
    spawn_protect_time = 180
}

---------------------------------------------------------------------------------------------------
---virtual methods

---virtual PlayerBase:loadResources()  -- for loading player sprite etc.
---virtual PlayerBase:initAnimation()  -- initialize sprite animation

---------------------------------------------------------------------------------------------------
---init

---@param player_input InputManager an object that manages recorded player input
---@param stage Stage the current stage this player is at
function PlayerBase:init(
        player_input,
        animation_interval,
        unfocused_speed,
        focused_speed,
        stage
)
    self.layer = LAYER_PLAYER
    self.group = GROUP_PLAYER
    self.bound = false

    self:loadResources()

    -- player object properties
    self.sprite_animation_interval = animation_interval  -- in frames
    self.sprite_animation_transition_interval = 4
    self.sprite_animation = ClockedAnimation()
    self:initAnimation()
    self.sprite_movement_state = 0  -- -2, -1 for left, 0 for idle, 1, 2 for right
    self.sprite_animation:playAnimation(
            "idle",
            self.sprite_animation_interval,
            0,
            true,
            true
    )

    self.player_input = player_input
    self.stage = stage

    self.unfocused_speed = unfocused_speed
    self.focused_speed = focused_speed
    self.invincibility_timer = 0
    self.spawn_counter = 0
    self.bomb_cooldown_timer = 0
end

---------------------------------------------------------------------------------------------------
---setters and getters

---@return InputManager
function PlayerBase:getPlayerInput()
    return self.player_input
end

---@param time number the time to increase to if less (in number of frames)
function PlayerBase:increaseInvincibilityTimerTo(time)
    if time > self.invincibility_timer then
        self.invincibility_timer = time
    end
end

---------------------------------------------------------------------------------------------------
---update

function PlayerBase:frame()
    task.Do(self)

    if self.spawn_counter == 0 then
        if self.miss_counter == nil then
            self:processPlayerInput(self.player_input)
            self:limitMovementInBound()
        end
    else
        self:updateSpriteByMovement(false, false)
        self.x = PlayerBase.const.spawn_x
        self.y = PlayerBase.const.spawn_y - PlayerBase.const.spawn_speed * self.spawn_counter
        self.spawn_counter = max(0, self.spawn_counter - 1)
    end

    self.invincibility_timer = max(0, self.invincibility_timer - 1)
    self.bomb_cooldown_timer = max(0, self.bomb_cooldown_timer - 1)

    self:updateMissStatus()
end

function PlayerBase:updateMissStatus()
    if self.miss_counter ~= nil then
        self.miss_counter = max(0, self.miss_counter - 1)
        if self.miss_counter == 0 then
            self:onMiss()
            self:respawn()
        end
    end
end

function PlayerBase:limitMovementInBound()
    local l, r, b, t = Coordinates.getPlayfieldBoundaryInGame()

    local min_dist = 10
    local top_min_dist = 20
    local bottom_min_dist = 24
    if self.x < l + min_dist then
        self.x = l + min_dist
    elseif self.x > r - min_dist then
        self.x = r - min_dist
    end
    if self.y < b + bottom_min_dist then
        self.y = b + bottom_min_dist
    elseif self.y > t - top_min_dist then
        self.y = t - top_min_dist
    end
end


function PlayerBase:render()
    if self.invincibility_timer % 3 == 2 then  -- 避开初始值 counter = 0
        self.color = Color(0xFF0000FF)
    else
        self.color = Color(0xFFFFFFFF)
    end
    DefaultRenderFunc(self)
end

---------------------------------------------------------------------------------------------------
---input

---@param player_input InputManager
function PlayerBase:processPlayerInput(player_input)
    self:processMovementInput(player_input)
    self:processAttackInput(player_input)
    self:processBombInput(player_input)
end

function PlayerBase:processAttackInput(player_input)
end

function PlayerBase:processBombInput(player_input)
end

---@param player_input InputManager
function PlayerBase:processMovementInput(player_input)
    -- 2D-movement limited to 8 directions

    local dx = 0
    local dy = 0
    -- take one direction if both keys are pressed
    if player_input:isAnyRecordedKeyDown("down") then
        dy = -1
    elseif player_input:isAnyRecordedKeyDown("up") then
        dy = 1
    end
    if player_input:isAnyRecordedKeyDown("left") then
        dx = -1
    elseif player_input:isAnyRecordedKeyDown("right") then
        dx = 1
    end
    local speed_coeff = self.unfocused_speed
    if player_input:isAnyRecordedKeyDown("slow") then
        speed_coeff = self.focused_speed
    end
    if dx * dy ~= 0 then  -- diagonal movement
        speed_coeff = speed_coeff * SQRT2_2
    end
    self.x, self.y = self.x + dx * speed_coeff, self.y + dy * speed_coeff

    -- update sprite
    self:updateSpriteByMovement(dx > 0, dx < 0)
end

---update sprite of the player by the movement performed
---@param is_moving_rightward boolean
---@param is_moving_leftward boolean
function PlayerBase:updateSpriteByMovement(is_moving_rightward, is_moving_leftward)
    local cur_move_dir = 0
    if is_moving_leftward then
        cur_move_dir = -1
    elseif is_moving_rightward then
        cur_move_dir = 1
    end

    local interval = self.sprite_animation_interval
    local transition_interval = self.sprite_animation_transition_interval
    local prev_state = self.sprite_movement_state
    local product = cur_move_dir * prev_state

    if (cur_move_dir == 0 and prev_state == 0) or product == 2 then  -- idle/continuous moving
        -- do nothing but update the animation
        self.sprite_animation:update(1)
    elseif cur_move_dir ~= 0 and prev_state == 0 then  -- from idle to moving
        local row_id
        if cur_move_dir > 0 then
            row_id = "move_right_loop"
        else
            row_id = "move_left_loop"
        end
        self.sprite_animation:playAnimation(
                row_id,
                interval,
                0,
                true,
                true
        )
        self.sprite_movement_state = cur_move_dir * 2
    elseif prev_state == -2 or prev_state == 2 then  -- from continuous moving to moving
        local row_id
        if prev_state == -2 then
            row_id = "move_left"
            self.sprite_movement_state = -1
        else
            row_id = "move_right"
            self.sprite_movement_state = 1
        end
        self.sprite_animation:playAnimation(
                row_id,
                transition_interval,
                0,
                false,
                false
        )
    else  -- from moving to idle, moving (the direction may be opposite) or continuous moving
        -- prev_state should be -1 or 1;
        if prev_state == cur_move_dir then  -- going in the same direction
            self.sprite_animation:setAnimationDirection(true)
            local t = self.sprite_animation:update(1)
            if t then  -- transition animation has ended
                local row_id
                if cur_move_dir == -1 then
                    row_id = "move_left_loop"
                else
                    row_id = "move_right_loop"
                end
                self.sprite_animation:playAnimation(
                        row_id,
                        interval,
                        self.timer,
                        true,
                        true
                )
                self.sprite_movement_state = 2 * cur_move_dir
            end
        else  -- going in the opposite direction or from moving to idle
            if cur_move_dir ~= 0 then
                local row_id
                if cur_move_dir == 1 then
                    row_id = "move_right_loop"
                else
                    row_id = "move_left_loop"
                end
                self.sprite_animation:playAnimation(
                        row_id,
                        transition_interval,
                        0,
                        true,
                        true
                )
                self.sprite_movement_state = cur_move_dir * 2
            else
                self.sprite_animation:setAnimationDirection(false)
                local t = self.sprite_animation:update(1)
                if t then  -- transition animation has ended
                    if cur_move_dir == 0 then
                        self.sprite_animation:playAnimation(
                                "idle",
                                interval,
                                0,
                                true,
                                true
                        )
                        self.sprite_movement_state = 0
                    end
                end
            end
        end
    end

    self.img = self.sprite_animation:getImage()
end

---------------------------------------------------------------------------------------------------
---other events

---respawn a new player, replace the old one;
---update the player reference in stage object
function PlayerBase:respawn()
    local Player = self.class
    local new_player = Player(self.stage)
    local spawn_time = PlayerBase.const.spawn_time
    local spawn_speed = PlayerBase.const.spawn_speed
    new_player.x = PlayerBase.const.spawn_x
    new_player.y = PlayerBase.const.spawn_y - spawn_speed * spawn_time
    new_player.spawn_counter = PlayerBase.const.spawn_time
    new_player.invincibility_timer = PlayerBase.const.spawn_protect_time
    self.stage:setPlayer(new_player)

    Del(self)
end

function PlayerBase:onMiss()
    self:endCurrentSession()
end

function PlayerBase:endCurrentSession()
    local current_stage = self.stage
    local callbacks = require("BHElib.scenes.stage.stage_transition_callbacks")
    current_stage:transitionWithCallback(callbacks.restartStageAndKeepRecording)
end

function PlayerBase:colli(other)
    local other_group = other.group
    if other_group == GROUP_ENEMY or other_group == GROUP_ENEMY_BULLET or other_group == GROUP_INDES then
        if other_group == GROUP_ENEMY_BULLET then
            Del(other)
        end

        -- player miss
        if self.invincibility_timer == 0 and self.miss_counter == nil then
            PlaySound("pldead00", 0.5, 0, true)
            self.miss_counter = 12
        end
    end
end

Prefab.Register(PlayerBase)

return PlayerBase