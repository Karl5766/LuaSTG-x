---------------------------------------------------------------------------------------------------
---player_prefab.lua
---date: 2021.4.12
---desc: This file defines the player class, from which all player sub-classes derive from
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")
local AnimatedUnit = require("BHElib.units.animation.animated_unit_prefab")

---@class Prefab.Player:Prefab.Object
local M = Prefab.NewX(Prefab.Object)

local EndCallbacks = require("BHElib.units.animation.animation_end_callbacks")
local Coordinates = require("BHElib.unclassified.coordinates_and_screen")
local PlayerGrazeObject = require("BHElib.units.player.player_graze_object_prefab")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local max = max

---------------------------------------------------------------------------------------------------
---constants

M.global = {
    spawn_x = 0,
    spawn_y = -180,
    spawn_time = 80,
    spawn_speed = 1,
    spawn_protect_time = 240
}

---------------------------------------------------------------------------------------------------
---virtual methods

---a unique string that identifies the player shot type
---@type string
M.SHOT_TYPE_ID = nil

---shot type name displayed in ui or menu
---@type string
M.SHOT_TYPE_DISPLAY_NAME = nil

---loading player sprite etc.
---@type function
M.loadResources = nil

---------------------------------------------------------------------------------------------------
---init

---the player will copy the number of life and bombs from the previous player object (if exists)
---@param player_input InputManager an object that manages recorded player input
---@param animation MovableAnimation controls the update of player sprite
---@param unfocused_speed number speed when unfocused; per frame
---@param focused_speed number speed when focused; per frame
---@param player_resource gameplay_resources.Player specifies the initial resources this player holds
---@param stage Stage the current stage this player is at
function M:init(
        player_input,
        animation,
        unfocused_speed,
        focused_speed,
        player_resource,
        stage)
    self.group = GROUP_PLAYER
    self.layer = LAYER_PLAYER
    self.bound = false

    self.animation = animation

    self.sprite_movement_state = 0  -- -2, -1 for left, 0 for idle, 1, 2 for right

    self.player_input = player_input
    self.stage = stage
    self.graze_object = PlayerGrazeObject(40, self)

    self.unfocused_speed = unfocused_speed
    self.focused_speed = focused_speed
    self.invincibility_timer = 0
    self.spawn_counter = 0
    self.bomb_cooldown_timer = 0
    self.item_collect_border_y = 112

    self:setPlayerResource(player_resource)
end

---------------------------------------------------------------------------------------------------
---setters and getters

---@return InputManager
function M:getPlayerInput()
    return self.player_input
end

function M:getStage()
    return self.stage
end

---@return player_support
function M:getSupport()
    error("Error: Attempt to call getSupport() in base player class!")
end

---@param time number the time to increase to if less (in number of frames)
function M:increaseInvincibilityTimerTo(time)
    if time > self.invincibility_timer then
        self.invincibility_timer = time
    end
end

---@param inc_power number the power to add; can be negative
function M:addPower(inc_power)
    error("Error: addPower() called in base class!")
end

---@return gameplay_resources.Player resources that player initially holds
function M:getPlayerResource()
    return self.player_resource
end

---@param player_resource gameplay_resources.Player
function M:setPlayerResource(player_resource)
    assert(player_resource, "Error: PlayerResource does not exist")
    self.player_resource = player_resource:copy()
end

---------------------------------------------------------------------------------------------------
---update

function M:frame()
    self.animation:update(1)

    if self.spawn_counter == 0 then
        -- receive input not in spawning
        self:processPlayerInput(self.player_input)
        self:limitMovementInBound()
    else
        self:updateSpriteByMovement(false, false)
        self.x = M.global.spawn_x
        self.y = M.global.spawn_y - M.global.spawn_speed * self.spawn_counter
        self.spawn_counter = max(0, self.spawn_counter - 1)
    end

    local graze_object = self.graze_object
    graze_object.x = self.x
    graze_object.y = self.y

    if self.y > self.item_collect_border_y then
        self.stage:borderCollectAllItems(self)
    end

    self.invincibility_timer = max(0, self.invincibility_timer - 1)
    self.bomb_cooldown_timer = max(0, self.bomb_cooldown_timer - 1)

    self:updateDeathStatus()
end

function M:updateDeathStatus()
    if self.miss_counter ~= nil then
        self.miss_counter = max(0, self.miss_counter - 1)
        if self.miss_counter == 0 then
            self:onMiss()
            self:respawn()
        end
    end
end

function M:limitMovementInBound()
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

function M:render()
    -- render player sprite
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
function M:processPlayerInput(player_input)
    if self.miss_counter == nil then
        self:processMovementInput(player_input)
        self:processAttackInput(player_input)
    end
    self:processBombInput(player_input)
end

function M:processAttackInput(player_input)
end

function M:processBombInput(player_input)
end

---@param player_input InputManager
function M:processMovementInput(player_input)
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
function M:updateSpriteByMovement(is_moving_rightward, is_moving_leftward)
    local cur_move_dir = 0
    if is_moving_leftward then
        cur_move_dir = -1
    elseif is_moving_rightward then
        cur_move_dir = 1
    end

    ---@type MovableAnimation
    local animation = self.animation

    local interval = self.animation_interval
    local transition_interval = self.transition_interval
    local total_image_num = 8
    local moving_repeat_image_num = 4
    local prev_state = self.sprite_movement_state

    if cur_move_dir * prev_state > 0 or (cur_move_dir == 0 and prev_state == 0) then  -- no change

    elseif cur_move_dir ~= 0 and cur_move_dir ~= prev_state then  -- from idle to moving/sudden turn to opposite direction
        local _repeat_moving = EndCallbacks.repeatFromImageIndex(total_image_num - moving_repeat_image_num + 1)  -- playing 5th to 8th images repeatingly
        animation:playMovementAnimation(
                cur_move_dir < 0,
                interval,
                true,
                transition_interval * (total_image_num - moving_repeat_image_num),
                _repeat_moving)
    else  -- from moving to idle
        local _idle = EndCallbacks.playAnotherAnimation(
                animation:getIdleImageArray(),
                interval,
                true,
                0,
                EndCallbacks.repeatAgain)
        animation:playMovementAnimation(
            prev_state < 0,
            transition_interval,
            false,
            transition_interval * moving_repeat_image_num,
            _idle)
    end

    self.sprite_movement_state = cur_move_dir
    self.img = animation:getSprite()
    self.hscale = animation:getHscale()
end

---------------------------------------------------------------------------------------------------
---collision events

---trigger player miss if the player is not invincible and if the miss is not already triggered;
---the miss takes place with a time offset (in which mechanics like deathbombing can be activated)
function M:getHit()
    if self.invincibility_timer == 0 and self.miss_counter == nil then
        PlaySound("se:pldead00", 0.5, 0, true)
        self.miss_counter = 12
    end
end

function M:colli(other)
    local on_player_collision = other.onPlayerCollision
    if on_player_collision then
        on_player_collision(other, self)
    end
    self:getHit()
end

function M:onEnemyBulletCollision(other)
    if other.destroyable then
        Del(other)
    end
end

---------------------------------------------------------------------------------------------------
---other events

---teleport player to a position instantly without transition effects (transition may be different for each player)
---@param x number x coordinate of position to teleport to
---@param y number y coordinate of position to teleport to
function M:teleportTo(x, y)
    self.x, self.y = x, y
end

function M:onMiss()
    self.stage:onPlayerMissOrBomb()
    local player_resource = self.player_resource
    player_resource.num_life = player_resource.num_life - 1
    player_resource.num_bomb = 3
    self:addPower(-50)
    if player_resource.num_life < 0 then  -- if player continue game here, the game will overwrite the life and bomb numbers
        self.stage:createGameOverMenu()
    end
end

---respawn a new player, replace the old one;
---update the player reference in stage object
function M:respawn()
    local Player = self.class
    local new_player = Player(self.stage, self, self.player_resource)
    local spawn_time = M.global.spawn_time
    local spawn_speed = M.global.spawn_speed
    local x = M.global.spawn_x
    local y = M.global.spawn_y - spawn_speed * spawn_time
    new_player:teleportTo(x, y)
    new_player.spawn_counter = M.global.spawn_time
    new_player.invincibility_timer = M.global.spawn_protect_time
    self.stage:setPlayer(new_player)

    Del(self)
end

---if the player is hit but miss counter has not reached 0, cancel the miss counter
function M:saveFromMiss()
    self.miss_counter = nil
end

---------------------------------------------------------------------------------------------------
---deletion

function M:del()
    self.graze_object.colli = false
    Del(self.graze_object)
end

function M:kill()
    error("Error: Attempt to call kill() on player!")
end

Prefab.Register(M)

return M