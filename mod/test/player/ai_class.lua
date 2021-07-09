---------------------------------------------------------------------------------------------------
---player_class.lua
---date: 2021.4.12
---desc: This file defines the player class, from which all player sub-classes derive from
---------------------------------------------------------------------------------------------------

local Prefab = require("BHElib.prefab")

---@class M
local M = Prefab.NewX(Prefab.Object)

local ClockedAnimation = require("BHElib.units.clocked_animation")
local Coordinates = require("BHElib.coordinates_and_screen")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local max = max

---------------------------------------------------------------------------------------------------
---virtual methods

---virtual M:loadResources()  -- for loading player sprite etc.
---virtual M:initAnimation()  -- initialize sprite animation

---------------------------------------------------------------------------------------------------
---engine callbacks

local function Hash(x, y)
    local xi = math.floor(x / 32) % 12 + (math.floor(y / 32) % 8) * 12
    return xi
end

local sprite_animation = ClockedAnimation()
function M:loadResources()
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
        sprite_animation:loadRowImagesFromTexture(
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

---@param player_input InputManager an object that manages recorded player input
---@param stage Stage the current stage this player is at
function M:init(
        x,
        y,
        unfocused_speed,
        is_moving,
        direction,
        collection_info,
        stage,
        record
)
    self.x = x
    self.y = y
    self.layer = LAYER_PLAYER
    self.group = GROUP_PLAYER
    self.bound = false

    self:loadResources()


    self.collection_info = collection_info
    self.unfocused_speed = unfocused_speed

    self.stage = stage
    self.record = record

    self.direction = direction
    self:updateSprite()

    self.is_moving = is_moving
    self.split_time = 1
    local a = direction * 45
    if is_moving then
        self.vx, self.vy = unfocused_speed * cos(a), unfocused_speed * sin(a)
    end
end

function M:updateSprite()
    local dir = self.direction % 8
    if self.is_moving and dir ~= 2 and dir ~= 6 then
        if dir > 2 and dir < 6 then
            self.img = "image_array:reimu_move_left"..(math.floor(self.timer / 4) % 4 + 1)
        else
            self.img = "image_array:reimu_move_right"..(math.floor(self.timer / 4) % 4 + 1)
        end
    else
        self.img = "image_array:reimu_idle"..(math.floor(self.timer / 4) % 4 + 1)
    end
end

function M:frame()
    self:updateSprite()
    self:limitMovementInBound()
    self.stage.player = self
    if self.timer == self.split_time then
        local i = Hash(self.x, self.y)
        if self.collection_info[i] < 2 then
            self:split()
        end
        self.split_time = self.split_time + 1
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

---------------------------------------------------------------------------------------------------

function M:split()
    local x, y = self.x, self.y
    if self.is_moving then
        local i = Hash(x, y)
        self.collection_info[i] = self.collection_info[i] + 1
        for i = 1, 7 do
            local record = {self.record, self.timer, i + self.direction, true, x, y}
            M(x, y, self.unfocused_speed, true, i + self.direction, self.collection_info, self.stage, record)
        end
        local record = {self.record, self.timer, 0, false, x, y}
        M(x, y, self.unfocused_speed, false, 0, self.collection_info, self.stage, record)
    else
        for i = 0, 7 do
            local record = {self.record, self.timer, i, true, x, y}
            M(x, y, self.unfocused_speed, true, i, self.collection_info, self.stage, record)
        end
    end
end

function M:miss()
    self:endCurrentSession()
end

function M:endCurrentSession()
    self.stage:transitionWithCallback(Stage.RESTART_AND_KEEP_RECORDING)
end

function M:colli(other)
    Del(self)
    if not self.is_moving and self.del_flag == nil then
        local i = Hash(self.x, self.y)
        self.collection_info[i] = self.collection_info[i] - 1
        self.del_flag = true
    end
end

Prefab.Register(M)

return M