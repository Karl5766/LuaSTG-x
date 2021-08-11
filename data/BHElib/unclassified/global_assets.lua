
--LoadTexture('logo', 'game/blank.png')
--local bg_path = 'game/front/stage_ui.png'
--LoadImageFromFile('stage_bg', bg_path)
--
--XASSETS = {}
--XASSETS.font = {
--    wqy    = 'font/WenQuanYiMicroHeiMono.ttf',
--}

assert(LoadFont("font:hud_default","THlib\\enemy\\bonus2.fnt"))
assert(LoadTTF("font:menu", "fonts/averia/Averia-Regular.ttf", 40))
assert(LoadTTF("font:test", "fonts/averia/Averia-Regular.ttf", 40))
assert(LoadFontOTF("font:noto_sans_sc", "fonts/Noto_Sans_SC/NotoSansSC-Medium.otf", 40))

LoadImageFromFile('image:white', 'THlib\\misc\\white.png')

LoadImageFromFile("image:test", "data_assets/THlib/bullet/Magic1.png")

LoadImageFromFile("image:button_normal", "creator/image/default_btn_normal.png")
LoadImageFromFile("image:button_pressed", "creator/image/default_btn_pressed.png")

LoadImageFromFile("image:menu_hud_background", "THlib\\UI\\menu_bg.png")

-- hint.png, line.png, rank.png and item.png etc.
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

        {"image:hint_extend_life", 0, 192, 160, 64},
        {"image:hint_spell_bonus_failed", 0, 64, 256, 64},
        {"image:hint_get_spell_bonus", 0, 128, 396, 64},
        {"image:hint_total_spell_time", 232, 200, 152, 56},
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

    --item.png
    images = {
        {"image:item_power", 0, 0, 32, 32},
        {"image:item_point", 32, 0, 32, 32},
        {"image:item_hint_power", 64, 0, 32, 32},
        {"image:item_hint_point", 96, 0, 32, 32},
        {"image:item_life_piece", 0, 32, 32, 32},
        {"image:item_full_power", 32, 32, 32, 32},
        {"image:item_hint_life_piece", 64, 32, 32, 32},
        {"image:item_hint_full_power", 96, 32, 32, 32},
        {"image:item_faith", 0, 64, 32, 32},
        {"image:item_big_power", 32, 64, 32, 32},
        {"image:item_hint_faith", 64, 64, 32, 32},
        {"image:item_hint_big_power", 96, 64, 32, 32},
        {"image:item_extend", 0, 96, 32, 32},
        {"image:item_small_faith", 32, 96, 32, 32},
        {"image:item_hint_extend", 64, 96, 32, 32},
        {"image:item_hint_small_faith", 96, 96, 32, 32},
        {"image:item_bomb_piece", 0, 128, 32, 32},
        {"image:item_bomb", 32, 128, 32, 32},
        {"image:item_hint_bomb_piece", 64, 128, 32, 32},
        {"image:item_hint_bomb", 96, 128, 32, 32},
    }
    LoadTextureAndImages("tex:item", images, "THlib\\item\\item.png")

    LoadImageGroup('lifechip', "tex:hint", 288, 16, 16, 15, 4, 1)
    LoadImageGroup('bombchip', "tex:hint", 288, 32, 16, 16, 4, 1)

    -- line.png
    LoadTexture("tex:line", "THlib\\UI\\line.png", true)
    LoadImageGroup("image_array:icon_line", "tex:line", 0, 0, 200, 8, 1, 7)

    ---boss fight and spell
    LoadImageFromFile("image:hint_spell_card_left", "THlib\\enemy\\boss_cardleft.png")
    -- sc_his_stage.png
    images = {
        {"image:boss_ui_spell_bonus_failed", 0, 0, 128, 32, 0, 16},
        {"image:boss_ui_spell_master", 0, 32, 128, 32, 0, 16},
    }
    LoadTextureAndImages("tex:boss_ui_status", images, "THlib\\enemy\\sc_his_stage.png")
    -- scname_sign.png
    images = {
        {"image:boss_ui_spell_bonus", 0, 0, 64, 32, 0, 16},
        {"image:boss_ui_spell_capture_rate", 0, 32, 64, 32, 0, 16},
    }
    LoadTextureAndImages("tex:boss_ui_icon", images, "THlib\\enemy\\scname_sign.png")
    -- boss_ui.png
    images = {
        {"image:boss_ui_spell_name_decoration", 0, 0, 256, 64},
        {"image:boss_ui_position_indicator", 0, 64, 48, 16},
    }
    LoadTextureAndImages("tex:boss_ui", images, "THlib\\ui\\boss_ui.png")
end


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

--lasers
LoadTexture("tex:laser_default", "THlib\\laser\\laser1.png")