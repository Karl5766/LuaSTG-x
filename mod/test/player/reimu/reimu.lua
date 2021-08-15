---------------------------------------------------------------------------------------------------
---reimu.lua
---date: 2021.4.18
---desc: Defines the Reimu player
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")
local PlayerBase = require("BHElib.units.player.player_prefab")

---@class ReimuPlayer:PlayerBase
local M = Prefab.NewX(PlayerBase, "units.player.reimu")

local Input = require("BHElib.input.input_and_recording")
local ReimuSupport = require("player.reimu.reimu_support")

---------------------------------------------------------------------------------------------------

M.SHOT_TYPE_ID = "shot_type:reimu"
M.SHOT_TYPE_DISPLAY_NAME = "Reimu"

---------------------------------------------------------------------------------------------------

---@param stage Stage
---@param spawning_player Prefab.Player the player to inherit player resources (life, bombs etc.) from; nil if this is the first player
---@param player_resource gameplay_resources.Player specifies the initial resources this player holds
function M:init(stage, spawning_player, player_resource)
    PlayerBase.init(
            self,
            Input,
            8,
            4.5,
            2,
            player_resource,
            stage)
    self.support = ReimuSupport(self.stage, self, "image:reimu_support")
end

---------------------------------------------------------------------------------------------------

function M:loadResources()
    if CheckRes("tex", "tex:reimu_sprite") then
        return
    end
    --sprite
    LoadTexture("tex:reimu_sprite", "THlib\\player\\reimu\\reimu.png")

    --main shot
    LoadImage("image:reimu_bullet", "tex:reimu_sprite", 192, 160, 64, 16, 16, 16)
    SetImageState("image:reimu_bullet", '', Color(0xA0FFFFFF))
    SetImageCenter("image:reimu_bullet", 56, 8)
    LoadAnimation("image:reimu_bullet_cancel_effect", "tex:reimu_sprite", 0, 144, 16, 16, 4, 1, 4)
    SetAnimationState("image:reimu_bullet_cancel_effect", "mul+add", Color(0xA0FFFFFF))

    --sub shots
    LoadImage("image:reimu_needle", "tex:reimu_sprite", 64, 176, 64, 16, 16, 16)
    SetImageState("image:reimu_needle", '', Color(0x80FFFFFF))
    SetImageCenter("image:reimu_needle", 32, 8)
    LoadImage("image:reimu_needle_cancel_effect", "tex:reimu_sprite", 64, 176, 64, 16, 16, 16)
    SetImageState("image:reimu_needle_cancel_effect", '', Color(0x80FFFFFF))
    SetImageCenter("image:reimu_needle_cancel_effect", 32, 8)

    LoadImage("image:reimu_support", "tex:reimu_sprite", 64, 144, 16, 16)
    LoadImage("image:reimu_follow_bullet", "tex:reimu_sprite", 0, 160, 16, 16, 16, 16)
    SetImageState("image:reimu_follow_bullet", '', Color(0x80FFFFFF))
    LoadAnimation("image:reimu_follow_bullet_cancel_effect", "tex:reimu_sprite", 0, 160, 16, 16, 4, 1, 4)
    SetAnimationState("image:reimu_follow_bullet_cancel_effect", "mul+add", Color(0xA0FFFFFF))

    --bomb
    LoadTexture("tex:reimu_kekkai", "THlib\\player\\reimu\\reimu_kekkai.png")
    LoadImage("image:reimu_kekkai", "tex:reimu_kekkai", 0, 0, 256, 256, 0, 0)
    SetImageState("image:reimu_kekkai", "mul+add", Color(0x804040FF))

    LoadImage("image:reimu_bomb_square", "tex:reimu_sprite", 0, 192, 64, 64, 0, 0)
end

---------------------------------------------------------------------------------------------------

---setup sprite animation
function M:initAnimation()
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
                false)
    end
end

---------------------------------------------------------------------------------------------------
---setters and getters

---@return player_support.Reimu
function M:getSupport()
    return self.support
end

---@param inc_power number the power to add; can be negative
function M:addPower(inc_power)
    local min_power, max_power = self.support:getPowerRange()
    local player_resource = self.player_resource
    player_resource.num_power = max(min_power, min(player_resource.num_power + inc_power, max_power))
end

---------------------------------------------------------------------------------------------------

function M:frame()
    PlayerBase.frame(self)

    self.support:update(1)
end

local _shoot = require("BHElib.scripts.shoot")
---@param player_input InputManager
function M:processAttackInput(player_input)
    if self.timer % 4 == 0 then
        if player_input:isAnyRecordedKeyDown("shoot") then
            PlaySound("se:plst00", 0.2, self.x / 1024, true)
            local attack = 1
            local img = "image:reimu_bullet"
            local cancel_img = "image:reimu_bullet_cancel_effect"

            local offset_x = -9
            for i = 1, 2 do
                _shoot.createPlayerBullet(
                        img,
                        cancel_img,
                        attack,
                        self.x + offset_x,
                        self.y,
                        0,
                        16,
                        90,
                        12,
                        0.4)
                offset_x = -offset_x
            end
            self.support:fireAllSub()
        end
    end
end

function M:processBombInput(player_input)
    if self.bomb_cooldown_timer <= 0 and player_input:isAnyRecordedKeyDown("spell") then
        local player_resource = self.player_resource
        if player_resource.num_bomb > 0 then
            self.stage:onPlayerMissOrBomb()
            player_resource.num_bomb = player_resource.num_bomb - 1
            self:saveFromMiss()
            require("BHElib.unclassified.screen_effect"):shakePlayfield(
                    self.stage,
                    3,
                    180,
                    3)
            require("player.reimu.reimu_bomb"):bomb(self, self.stage)
            self.bomb_cooldown_timer = 480
            self:increaseInvincibilityTimerTo(510)
        end
    end
end

---------------------------------------------------------------------------------------------------
---render

function M:render()
    PlayerBase.render(self)
    self.support:render()
end

---------------------------------------------------------------------------------------------------

function M:teleportTo(x, y)
    self.support:setPosition(x, y)
    PlayerBase.teleportTo(self, x, y)
end


return M