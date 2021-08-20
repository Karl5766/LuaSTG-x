---------------------------------------------------------------------------------------------------
---enemy_types.lua
---date created: 2021.8.19
---reference: THlib/enemy/enemy.lua
---desc: Defines a varieties of enemy types
---------------------------------------------------------------------------------------------------

local MoveAnimatedEnemyType = require("BHElib.units.enemy.enemy_type.move_animated_enemy_type")
local ImgEnemyType = require("BHElib.units.enemy.enemy_type.img_enemy_type")

---------------------------------------------------------------------------------------------------

local function DefineFairy(color_theme, image_array_name)
    local idle_ani = {image_array_name, 1, 4}
    local move_right_ani = {image_array_name, 5, 12}
    return MoveAnimatedEnemyType(color_theme, true, true, false, 8, 1, idle_ani, nil, move_right_ani, 8, 8, 4, 8)
end

local function DefineBigFairy(color_theme, image_array_name)
    local idle_ani = {image_array_name, 1, 4}
    local move_right_ani = {image_array_name, 5, 12}
    return MoveAnimatedEnemyType(color_theme, false, true, false, 16, 1, idle_ani, nil, move_right_ani, 8, 8, 4, 8)
end

---@param rot number initial rotation
---@param inc_rot number initial rotation speed
---@param use_aura boolean if ture, use aura corresponding to the color theme
---@param use_spin_image boolean if true, use spin image corresponding to the color theme
local function DefineImgEnemy(color_theme, img, rot, inc_rot, use_aura, use_spin_image)
    return ImgEnemyType(color_theme, use_aura, true, use_spin_image, 8, img, rot, inc_rot)
end

local function DefineFurBall(color_theme, img)
    return DefineImgEnemy(color_theme, img, 0, 12, true, false)
end

local function DefineYinYangOrb(color_theme, img)
    return DefineImgEnemy(color_theme, img, 0, 6, true, true)
end

local function DefineSpirit(color_theme, img)
    return DefineImgEnemy(color_theme, img, -90, 0, false, false)
end

---------------------------------------------------------------------------------------------------

---@class EnemyTypes
local M = {
    fairy_red = DefineFairy(COLOR_RED, "image_array:fairy_red"),
    fairy_green = DefineFairy(COLOR_GREEN, "image_array:fairy_green"),
    fairy_blue = DefineFairy(COLOR_BLUE, "image_array:fairy_blue"),
    fairy_yellow = DefineFairy(COLOR_YELLOW, "image_array:fairy_yellow"),
    fairy_purple = DefineFairy(COLOR_YELLOW, "image_array:fairy_purple"),
    fairy_pink = DefineFairy(COLOR_RED, "image_array:fairy_pink"),
    fairy_light_blue = DefineFairy(COLOR_BLUE, "image_array:fairy_light_blue"),
    fairy_shadow = DefineFairy(COLOR_RED, "image_array:fairy_shadow"),

    flower_fairy_blue = DefineFairy(COLOR_BLUE, "image_array:flower_fairy_blue"),
    flower_fairy_red = DefineFairy(COLOR_RED, "image_array:flower_fairy_red"),

    bow_tie_fairy_red = DefineBigFairy(COLOR_RED, "image_array:bow_tie_fairy_red"),
    bow_tie_fairy_blue = DefineBigFairy(COLOR_BLUE, "image_array:bow_tie_fairy_blue"),

    butterfly_fairy_white = DefineBigFairy(COLOR_RED, "image_array:butterfly_fairy_white"),
    butterfly_fairy_black = DefineBigFairy(COLOR_BLUE, "image_array:butterfly_fairy_black"),

    fur_ball_red = DefineFurBall(COLOR_RED, "image:fur_ball_red"),  -- 毛玉 | けだま
    fur_ball_green = DefineFurBall(COLOR_GREEN, "image:fur_ball_green"),
    fur_ball_blue = DefineFurBall(COLOR_BLUE, "image:fur_ball_blue"),
    fur_ball_yellow = DefineFurBall(COLOR_YELLOW, "image:fur_ball_yellow"),

    yin_yang_orb_red = DefineYinYangOrb(COLOR_RED, "image:yin_yang_orb_red"),
    yin_yang_orb_green = DefineYinYangOrb(COLOR_GREEN, "image:yin_yang_orb_green"),
    yin_yang_orb_blue = DefineYinYangOrb(COLOR_BLUE, "image:yin_yang_orb_blue"),
    yin_yang_orb_purple = DefineYinYangOrb(COLOR_YELLOW, "image:yin_yang_orb_purple"),

    moon_fairy_red = DefineFairy(COLOR_RED, "image_array:moon_fairy_red"),
    moon_fairy_green = DefineFairy(COLOR_GREEN, "image_array:moon_fairy_green"),
    moon_fairy_blue = DefineFairy(COLOR_BLUE, "image_array:moon_fairy_blue"),
    moon_fairy_yellow = DefineFairy(COLOR_YELLOW, "image_array:moon_fairy_yellow"),

    spirit_red = DefineSpirit(COLOR_RED, "psi:spirit_red"),
    spirit_green = DefineSpirit(COLOR_GREEN, "psi:spirit_green"),
    spirit_blue = DefineSpirit(COLOR_BLUE, "psi:spirit_blue"),
    spirit_yellow = DefineSpirit(COLOR_YELLOW, "psi:spirit_yellow"),
}

---------------------------------------------------------------------------------------------------
---load resources

function M.init()
    local function LoadImageArraysFromTexture(tex_name, image_arrays)
        for i = 1, #image_arrays do
            local t = image_arrays[i]
            -- image_name, x, y, width, height, num_col, num_row
            LoadImageArray(t[1], tex_name, t[2], t[3], t[4], t[5], t[6], t[7])--红
        end
    end
    local function LoadImageAndSetCenter(tex_name, img_name, x, y, w, h, center_x, center_y)
        LoadImage(img_name, tex_name, x, y, w, h)
        if center_x then
            SetImageCenter(img_name, center_x, center_y)
        end
    end
    local function LoadImages(tex_name, images)
        for i = 1, #images do
            LoadImageAndSetCenter(tex_name, unpack(images[i]))
        end
    end

    do
        local images
        local image_arrays
        images = {
            {"image:fur_ball_red", 288, 320, 32, 32},
            {"image:fur_ball_green", 256, 352, 32, 32},
            {"image:fur_ball_blue", 256, 320, 32, 32},
            {"image:fur_ball_yellow", 288, 352, 32, 32},
            {"image:yin_yang_orb_red", 192, 64, 32, 32},
            {"image:yin_yang_orb_green", 224, 64, 32, 32},
            {"image:yin_yang_orb_blue", 256, 64, 32, 32},
            {"image:yin_yang_orb_purple", 288, 64, 32, 32},
        }
        image_arrays = {
            {"image_array:fairy_red", 0, 384, 32, 32, 12, 1},
            {"image_array:fairy_green", 0, 416, 32, 32, 12, 1},
            {"image_array:fairy_blue", 0, 448, 32, 32, 12, 1},
            {"image_array:fairy_yellow", 0, 480, 32, 32, 12, 1},
            {"image_array:flower_fairy_blue", 0, 0, 48, 32, 4, 3},
            {"image_array:flower_fairy_red", 0, 96, 48, 32, 4, 3},
            {"image_array:bow_tie_fairy_blue", 320, 0, 48, 48, 4, 3},
            {"image_array:bow_tie_fairy_red", 320, 144, 48, 48, 4, 3},
            {"image_array:butterfly_fairy_white", 0, 192, 64, 64, 4, 3},
        }
        LoadImages("tex:enemy1", images)
        LoadImageArraysFromTexture("tex:enemy1", image_arrays)

        image_arrays = {
            {"image_array:fairy_purple", 0, 0, 32, 32, 12, 1},
            {"image_array:fairy_pink", 0, 32, 32, 32, 12, 1},
            {"image_array:fairy_light_blue", 0, 64, 32, 32, 12, 1},
            {"image_array:fairy_shadow", 0, 96, 32, 32, 12, 1},
            {"image_array:moon_fairy_red", 0, 352, 32, 32, 12, 1},
            {"image_array:moon_fairy_green", 0, 416, 32, 32, 12, 1},
            {"image_array:moon_fairy_blue", 0, 288, 32, 32, 12, 1},
            {"image_array:moon_fairy_yellow", 0, 480, 32, 32, 12, 1},
            {"image_array:butterfly_fairy_black", 0, 128, 64, 64, 6, 2},
        }
        LoadImageArraysFromTexture("tex:enemy2", image_arrays)

        image_arrays = {
            {"image_array:spirit_red", 0, 0, 32, 32, 8, 1},
            {"image_array:spirit_green", 0, 32, 32, 32, 8, 1},
            {"image_array:spirit_blue", 0, 64, 32, 32, 8, 1},
            {"image_array:spirit_yellow", 0, 96, 32, 32, 8, 1},
        }
        LoadImageArraysFromTexture("tex:enemy2", image_arrays)
    end

    LoadPS("psi:spirit_red", "THlib/enemy/ghost_fire_r.psi", "image_array:particle1")
    LoadPS("psi:spirit_green", "THlib/enemy/ghost_fire_g.psi", "image_array:particle1")
    LoadPS("psi:spirit_blue", "THlib/enemy/ghost_fire_b.psi", "image_array:particle1")
    LoadPS("psi:spirit_yellow", "THlib/enemy/ghost_fire_y.psi", "image_array:particle1")
end

return M