
--LoadTexture('logo', 'game/blank.png')
--local bg_path = 'game/front/stage_ui.png'
--LoadImageFromFile('stage_bg', bg_path)
--
--XASSETS = {}
--XASSETS.font = {
--    wqy    = 'font/WenQuanYiMicroHeiMono.ttf',
--}

assert(LoadFont("font:hud_default","THlib\\enemy\\bonus2.fnt"))
assert(LoadTTF("font:menu", "averia/Averia-Regular.ttf", 40))
assert(LoadTTF("font:test", "averia/Averia-Regular.ttf", 40))

LoadImageFromFile('image:white', 'THlib\\misc\\white.png')

LoadImageFromFile("image:test", "data_assets/THlib/bullet/Magic1.png")

LoadImageFromFile("image:button_normal", "creator/image/default_btn_normal.png")
LoadImageFromFile("image:button_pressed", "creator/image/default_btn_pressed.png")

LoadImageFromFile("image:menu_hud_background", "THlib\\UI\\menu_bg.png")

-- hint.png, line.png and rank.png
do
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
    local function LoadTextureAndImages(tex_name, images, tex_file_path)
        LoadTexture(tex_name, tex_file_path, true)
        LoadImages(tex_name, images)
    end

    -- hint.png
    local images
    images = {
        {"image:icon_life_outline", 288, 0, 16, 15},
        {"image:icon_life", 304, 0, 16, 15},
        {"image:icon_bomb_outline", 320, 0, 16, 16},
        {"image:icon_bomb", 336, 0, 16, 16},

        {"image:icon_power_title", 0, 12, 84, 32, 0, 16},
        {"image:icon_graze_title", 86, 12, 74, 32, 0, 16},
        {"image:icon_hiscore_title", 424, 8, 80, 20, 0, 10},
        {"image:icon_score_title", 424, 30, 64, 20, 0, 10},
        {"image:icon_life_title", 352, 8, 56, 20, 0, 10},
        {"image:icon_bomb_title", 352, 30, 72, 20, 0, 10},

        {"image:hint_spell_bonus_failed", 0, 64, 256, 64},
        {"image:hint_get_spell_bonus", 0, 128, 396, 64},
        {"image:hint_extend_life", 0, 192, 160, 64},
        {"image:hint_capture_time", 232, 200, 152, 56},
    }
    LoadTextureAndImages("tex:hint", images, "THlib\\UI\\hint.png")

    -- rank.png
    images = {
        {"image:icon_easy_title", 0, 0, 144, 32},
        {"image:icon_normal_title", 0, 32, 144, 32},
        {"image:icon_hard_title", 0, 64, 144, 32},
        {"image:icon_lunatic_title", 0, 96, 144, 32},
        {"image:icon_extra_title", 0, 128, 144, 32},
    }
    LoadTextureAndImages("tex:rank", images, "THlib\\UI\\rank.png")

    LoadImageGroup('lifechip', "tex:hint", 288, 16, 16, 15, 4, 1)
    LoadImageGroup('bombchip', "tex:hint", 288, 32, 16, 16, 4, 1)

    -- line.png
    LoadTexture("tex:line", "THlib\\UI\\line.png", true)
    LoadImageGroup("image_array:icon_line", "tex:line", 0, 0, 200, 8, 1, 7)
end

-- boss fight and spell
LoadImageFromFile("image:boss_spell_left", "THlib\\enemy\\boss_cardleft.png")


-- bullets
local bullet_path = "THlib\\bullet\\"
LoadTexture("tex:bullet_sprite_1", bullet_path.."bullet1.png")
LoadTexture("tex:bullet_sprite_2", bullet_path.."bullet2.png")
LoadTexture("tex:bullet_sprite_3", bullet_path.."bullet3.png")
LoadTexture("tex:bullet_sprite_4", bullet_path.."bullet4.png")
LoadTexture("tex:bullet_sprite_6", bullet_path.."bullet6.png")

LoadTexture("tex:bullet_ball_light", bullet_path.."bullet5.png")  -- #5 only contains one type of bullet
LoadTexture("tex:bullet_bubble", bullet_path.."bullet_ball_huge.png")
LoadTexture("tex:bullet_music_note", bullet_path.."bullet_music.png")
LoadTexture("tex:bullet_fireball", bullet_path.."bullet_water_drop.png")

LoadTexture("tex:bullet_cancel", bullet_path.."etbreak.png")

LoadImageGroup('img:ball_mid', 'tex:bullet_sprite_1', 176, 0, 32, 32, 1, 8, 4, 4)