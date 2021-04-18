---------------------------------------------------------------------------------------------------
---player_class.lua
---date: 2021.4.12
---desc: This file defines the player class, from which all player sub-classes derive from
---------------------------------------------------------------------------------------------------

local Prefab = require("prefab")

local PlayerClass = Prefab.NewX(Prefab.Object)

local ClockedAnimation = require("BHElib.units.clocked_animation")

---------------------------------------------------------------------------------------------------
---cache variables and functions

---------------------------------------------------------------------------------------------------
---engine callbacks

---@param player_input InputManager an object that manages recorded player input
function PlayerClass:init(player_input)
    self.layer = LAYER_PLAYER
    self.group = GROUP_PLAYER

    -- player object properties
    self.sprite_animation_interval = 8  -- in frames
    self.sprite_movement_state = 0  -- -2, -1 for left, 0 for idle, 1, 2 for right
    self.sprite_animation = ClockedAnimation()

    self.player_input = player_input
end

function PlayerClass:frame()
    self:processUserInput(self.player_input)
end

---------------------------------------------------------------------------------------------------
---input

---@param PlayerInput InputManager
function PlayerClass:processPlayerInput(PlayerInput)
    self:processMovementInput(PlayerInput)
end

---@param PlayerInput InputManager
function PlayerClass:processMovementInput(PlayerInput)
    -- 2D-movement limited to 8 directions

    local dx = 0
    local dy = 0
    -- take one direction if both keys are pressed
    if PlayerInput:isAnyRecordedKeyDown("down") then
        dy = -1
    elseif PlayerInput:isAnyRecordedKeyDown("up") then
        dy = 1
    end
    if PlayerInput:isAnyRecordedKeyDown("left") then
        dx = -1
    elseif PlayerInput:isAnyRecordedKeyDown("right") then
        dx = 1
    end
    local speed_coeff = self.unfocused_speed
    if PlayerInput:isAnyRecordedKeyDown("slow") then
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
function PlayerClass:updateSpriteByMovement(is_moving_rightward, is_moving_leftward)
    local cur_move_dir = 0
    if is_moving_leftward then
        cur_move_dir = -1
    elseif is_moving_rightward then
        cur_move_dir = 1
    end

    local interval = self.sprite_animation_interval
    local prev_state = self.sprite_movement_state
    local product = cur_move_dir * prev_state

    if (cur_move_dir == 0 and prev_state == 0) or product == 2 then  -- idle/continuous moving
        -- do nothing but update the animation
        self.sprite_animation:update(1)
    elseif cur_move_dir ~= 0 and prev_state == 0 then  -- from idle to moving
        local row_id
        if cur_move_dir > 0 then
            row_id = "move_right"
        else
            row_id = "move_left"
        end
        self.sprite_animation:playAnimation(
                row_id,
                interval,
                0,
                true,
                false
        )
        self.sprite_movement_state = cur_move_dir
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
                interval,
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
            self.sprite_animation:setAnimationDirection(false)
            local t = self.sprite_animation:update(1)
            if t then  -- transition animation has ended
                if cur_move_dir == 0 then
                    self.sprite_animation:playAnimation(
                            "idle",
                            interval,
                            self.timer,
                            true,
                            true
                    )
                    self.sprite_movement_state = 0
                else
                    local row_id
                    if cur_move_dir == 1 then
                        row_id = "move_right"
                    else
                        row_id = "move_left"
                    end
                    self.sprite_animation:playAnimation(
                            row_id,
                            interval,
                            t,
                            false,
                            false
                    )
                    self.sprite_movement_state = cur_move_dir
                end
            end
        end
    end

    self.img = self.sprite_animation:getImage()
end

function player_class:render()
    DefaultRenderFunc(self)
end

Prefab.Register(PlayerClass)

return PlayerClass