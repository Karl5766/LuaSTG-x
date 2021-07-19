---------------------------------------------------------------------------------------------------
---reimu.lua
---date: 2021.4.18
---desc: Defines the Reimu player
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")
local PlayerBase = require("BHElib.units.player.player_class")

---@class ReimuPlayer:PlayerBase
local M = Prefab.NewX(PlayerBase, "units.player.reimu")

local Input = require("BHElib.input.input_and_recording")
local ReimuSupport = require("player.reimu.reimu_support")

---------------------------------------------------------------------------------------------------

function M:init(stage)
    PlayerBase.init(
            self,
            Input,
            8,
            4.5,
            2,
            stage
    )
    self.support = ReimuSupport(self.stage, self, "image:reimu_support")
end

---------------------------------------------------------------------------------------------------

function M:loadResources()
    if CheckRes("tex", "tex:reimu_sprite") then
        return
    end
    LoadTexture("tex:reimu_sprite", "THlib\\player\\reimu\\reimu.png")

    --main shot
    LoadImage("image:reimu_bullet", "tex:reimu_sprite", 192, 160, 64, 16, 16, 16)
    SetImageState("image:reimu_bullet", '', Color(0xA0FFFFFF))
    SetImageCenter("image:reimu_bullet", 56, 8)
    LoadAnimation("image:reimu_bullet_cancel_effect", "tex:reimu_sprite", 0, 144, 16, 16, 4, 1, 4)
    SetAnimationState("image:reimu_bullet_cancel_effect", 'mul+add', Color(0xA0FFFFFF))

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
    SetAnimationState("image:reimu_follow_bullet_cancel_effect", 'mul+add', Color(0xA0FFFFFF))


    LoadTexture('reimu_kekkai', 'THlib\\player\\reimu\\reimu_kekkai.png')
    LoadTexture('reimu_orange_ef2', 'THlib\\player\\reimu\\reimu_orange_eff.png')
    LoadImageFromFile('reimu_bomb_ef', 'THlib\\player\\reimu\\reimu_bomb_ef.png')
    LoadAnimation('reimu_bullet_orange_ef2', 'reimu_orange_ef2', 0, 0, 64, 16, 1, 9, 1)
    SetAnimationCenter('reimu_bullet_orange_ef2', 0, 8)

    LoadImage('reimu_bullet_ef_img', "tex:reimu_sprite", 48, 144, 16, 16)
    LoadImage('reimu_kekkai', 'reimu_kekkai', 0, 0, 256, 256, 0, 0)
    SetImageState('reimu_kekkai', 'mul+add', Color(0x804040FF))
    LoadPS('reimu_bullet_ef', 'THlib\\player\\reimu\\reimu_bullet_ef.psi', 'reimu_bullet_ef_img')
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
                false
        )
    end
end

---------------------------------------------------------------------------------------------------

function M:frame()
    PlayerBase.frame(self)

    self.support:setPower(400)
    self.support:update(1)
end

local _shoot = require("BHElib.scripts.shoot")
---@param player_input InputManager
function M:processAttackInput(player_input)
    if self.timer % 4 == 0 then
        if player_input:isAnyRecordedKeyDown("shoot") then
            PlaySound('plst00', 0.2, self.x / 1024, true)
            local attack = 1
            local img = "image:reimu_bullet"
            local cancel_img = "image:reimu_bullet_cancel_effect"

            local offset_x = -9
            for i = 1, 2 do
                _shoot.createPlayerBulletS(
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
    if player_input:isAnyRecordedKeyDown("spell") then
        require("BHElib.screen_effect"):shakePlayfield(
                self.stage,
                3,
                60,
                3)
    end
end

---------------------------------------------------------------------------------------------------
---render

function M:render()
    PlayerBase.render(self)
    self.support:render()
end


return M