---------------------------------------------------------------------------------------------------
---player_class.lua
---date: 2021.4.12
---desc: This file defines the player class, from which all player sub-classes derive from
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")
local PlayerBase = Prefab.NewX(Prefab.Object)

local ClockedAnimation = require("BHElib.units.clocked_animation")
local Coordinates = require("BHElib.coordinates_and_screen")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local max = max

---------------------------------------------------------------------------------------------------

---@param player_input InputManager an object that manages recorded player input
---@param stage Stage the current stage this player is at
function PlayerBase:init(
        record_array, unfocused_speed, stage
)
    self.layer = LAYER_PLAYER
    self.group = GROUP_PLAYER
    self.bound = false

    self:loadResources()

    -- player object properties
    self.sprite_animation_interval = 8  -- in frames
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

    self.record_array = record_array
    self.ref_index = #record_array - 2
    self.turn_time = 1

    self.stage = stage

    self.unfocused_speed = unfocused_speed
    self.focused_speed = 2
    self.protect_counter = 0
    self.spawn_counter = 0
end

function PlayerBase:loadResources()
    if CheckRes("tex", "tex:reimu_sprite") then
        return
    end
    LoadTexture("tex:reimu_sprite", "THlib\\player\\reimu\\reimu.png")

    LoadTexture('reimu_kekkai', 'THlib\\player\\reimu\\reimu_kekkai.png')
    LoadTexture('reimu_orange_ef2', 'THlib\\player\\reimu\\reimu_orange_eff.png')
    LoadImageFromFile('reimu_bomb_ef', 'THlib\\player\\reimu\\reimu_bomb_ef.png')
    LoadAnimation('reimu_bullet_orange_ef2', 'reimu_orange_ef2', 0, 0, 64, 16, 1, 9, 1)
    SetAnimationCenter('reimu_bullet_orange_ef2', 0, 8)
    LoadImage('reimu_bullet_red', "tex:reimu_sprite", 192, 160, 64, 16, 16, 16)
    SetImageState('reimu_bullet_red', '', Color(0xA0FFFFFF))
    SetImageCenter('reimu_bullet_red', 56, 8)
    LoadAnimation('reimu_bullet_red_ef', "tex:reimu_sprite", 0, 144, 16, 16, 4, 1, 4)
    SetAnimationState('reimu_bullet_red_ef', 'mul+add', Color(0xA0FFFFFF))

    LoadImage('reimu_bullet_blue', "tex:reimu_sprite", 0, 160, 16, 16, 16, 16)
    SetImageState('reimu_bullet_blue', '', Color(0x80FFFFFF))
    LoadAnimation('reimu_bullet_blue_ef', "tex:reimu_sprite", 0, 160, 16, 16, 4, 1, 4)
    SetAnimationState('reimu_bullet_blue_ef', 'mul+add', Color(0xA0FFFFFF))

    LoadImage('reimu_support', "tex:reimu_sprite", 64, 144, 16, 16)
    LoadImage('reimu_bullet_ef_img', "tex:reimu_sprite", 48, 144, 16, 16)
    LoadImage('reimu_kekkai', 'reimu_kekkai', 0, 0, 256, 256, 0, 0)
    SetImageState('reimu_kekkai', 'mul+add', Color(0x804040FF))
    LoadPS('reimu_bullet_ef', 'THlib\\player\\reimu\\reimu_bullet_ef.psi', 'reimu_bullet_ef_img')
    -----------------------------------------
    LoadImage('reimu_bullet_orange', "tex:reimu_sprite", 64, 176, 64, 16, 64, 16)
    SetImageState('reimu_bullet_orange', '', Color(0x80FFFFFF))
    SetImageCenter('reimu_bullet_orange', 32, 8)

    LoadImage('reimu_bullet_orange_ef', "tex:reimu_sprite", 64, 176, 64, 16, 64, 16)
    SetImageState('reimu_bullet_orange_ef', '', Color(0x80FFFFFF))
    SetImageCenter('reimu_bullet_orange_ef', 32, 8)
end

---------------------------------------------------------------------------------------------------

---setup sprite animation
function PlayerBase:initAnimation()
    -- row_id, (top left)x, y, (single image)width, height, image_num, image_name
    local image_rows = {
        {"idle", 0, 0, 32, 48, 8, "image_array:reimu_idle"},
        {"move_left", 0, 48, 32, 48, 4, "image_array:reimu_move_left"},
        {"move_right", 0, 96, 32, 48, 4, "image_array:reimu_move_right"},
        {"move_left_loop", 128, 48, 32, 48, 4, "image_array:reimu_move_left_loop"},
        {"move_right_loop", 128, 96, 32, 48, 4, "image_array:reimu_move_right_loop"},
    }
    local tex_name = "tex:reimu_sprite"
    local colli_a, colli_b = 0, 0

    for i, row in ipairs(image_rows) do
        local row_id, x, dx, y, dy, image_name = row[1], row[2], row[4], row[3], 0, row[7]
        local width, height, image_num = row[4], row[5], row[6]
        self.sprite_animation:loadRowImagesFromTexture(
                row_id,
                tex_name,
                image_name,
                x,
                y,
                dx,
                dy,
                width,
                height,
                image_num,
                colli_a,
                colli_b,
                false
        )
    end
end

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
---engine callbacks


function PlayerBase:frame()
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

    self.protect_counter = max(0, self.protect_counter - 1)

    self:updateMissStatus()
end

function PlayerBase:updateMissStatus()
    if self.miss_counter ~= nil then
        self.miss_counter = max(0, self.miss_counter - 1)
        if self.miss_counter == 0 then
            self:miss()
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

---------------------------------------------------------------------------------------------------
---input

---@param PlayerInput InputManager
function PlayerBase:processPlayerInput(PlayerInput)
    self:processMovementInput(PlayerInput)
end

---@param PlayerInput InputManager
function PlayerBase:processMovementInput(PlayerInput)
    -- 2D-movement limited to 8 directions

    local record = self.record_array
    if self.timer == self.turn_time then
        local i = self.ref_index
        local speed = 0
        if record[i + 2] == 1 then
            speed = self.unfocused_speed
        end
        local dir = record[i + 1] * 45
        self.vx, self.vy = speed * cos(dir), speed * sin(dir)

        if i - 3 > 0 then
            self.ref_index = i - 3
            self.turn_time = self.turn_time + record[i - 3]
        else
            self.turn_time = 99999999
        end
    end

    -- update sprite
    self:updateSpriteByMovement(self.vx > 0.01, self.vx < -0.01)
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

---respawn a new player
function PlayerBase:respawn()
    local Player = self.class
    local new_player = Player(self.stage)
    local spawn_time = PlayerBase.const.spawn_time
    local spawn_speed = PlayerBase.const.spawn_speed
    new_player.x = PlayerBase.const.spawn_x
    new_player.y = PlayerBase.const.spawn_y - spawn_speed * spawn_time
    new_player.spawn_counter = PlayerBase.const.spawn_time
    new_player.protect_counter = PlayerBase.const.spawn_protect_time
    self.stage:setPlayer(new_player)

    Del(self)
end

function PlayerBase:miss()
    self:endCurrentSession()
end

function PlayerBase:endCurrentSession()
    self.stage:stageTransition(Stage.RESTART_AND_KEEP_RECORDING)
end

function PlayerBase:colli(other)
    local other_group = other.group
    if other_group == GROUP_ENEMY or other_group == GROUP_ENEMY_BULLET or other_group == GROUP_INDES then
        if other_group == GROUP_ENEMY_BULLET then
            Del(other)
        end

        -- player miss
        if self.protect_counter == 0 and self.miss_counter == nil then
            PlaySound("pldead00", 0.5, 0, true)
            self.miss_counter = 12
        end
    end
end

function PlayerBase:render()
    if self.protect_counter % 3 == 2 then  -- 避开初始值 counter = 0
        self.color = Color(0xFF0000FF)
    else
        self.color = Color(0xFFFFFFFF)
    end
    DefaultRenderFunc(self)
end

Prefab.Register(PlayerBase)

return PlayerBase