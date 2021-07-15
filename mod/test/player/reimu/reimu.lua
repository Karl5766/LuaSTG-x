---------------------------------------------------------------------------------------------------
---reimu.lua
---desc: Defines the Reimu player
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")
local PlayerBase = require("BHElib.units.player.player_class")

---@class ReimuPlayer:PlayerBase
local Player = Prefab.NewX(PlayerBase, "units.player.reimu")

local Input = require("BHElib.input.input_and_recording")

---------------------------------------------------------------------------------------------------

function Player:init(stage)
    PlayerBase.init(
            self,
            Input,
            8,
            4.5,
            2,
            stage
    )
end

---------------------------------------------------------------------------------------------------

function Player:loadResources()
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

    LoadTexture('reimu_kekkai', 'THlib\\player\\reimu\\reimu_kekkai.png')
    LoadTexture('reimu_orange_ef2', 'THlib\\player\\reimu\\reimu_orange_eff.png')
    LoadImageFromFile('reimu_bomb_ef', 'THlib\\player\\reimu\\reimu_bomb_ef.png')
    LoadAnimation('reimu_bullet_orange_ef2', 'reimu_orange_ef2', 0, 0, 64, 16, 1, 9, 1)
    SetAnimationCenter('reimu_bullet_orange_ef2', 0, 8)

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
function Player:initAnimation()
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
---player shot

local PlayerShotPrefabs = require("BHElib.units.player.player_shot_prefabs")

---@class Reimu.MainShot:PlayerShotPrefabs.Base
local MainShot = Prefab.NewX(PlayerShotPrefabs.Base)

function MainShot:init(init_x, init_y, attack, vy)
    PlayerShotPrefabs.Base.init(self, attack)
    self.x = init_x
    self.y = init_y
    self.vy = vy
    self.rot = 90
    self.img = "image:reimu_bullet"
end

function MainShot:createCancelEffect()
    local object = PlayerShotPrefabs.CancelEffect(12)  -- exists for 12 frames
    object.img = "image:reimu_bullet_cancel_effect"
    object.x = self.x
    object.y = self.y
    object.vy = self.vy * 0.4
end

Prefab.Register(MainShot)

---@param PlayerInput InputManager manages player input
function Player:processAttackInput(PlayerInput)
    if self.timer % 4 == 0 then
        if PlayerInput:isAnyRecordedKeyDown("shoot") then
            PlaySound('plst00', 0.2, self.x / 1024, true)
            local attack = 1
            local bullet_1 = MainShot(self.x + 9, self.y, attack, 16)
            local bullet_2 = MainShot(self.x - 9, self.y, attack, 16)
        end
    end
end

return Player