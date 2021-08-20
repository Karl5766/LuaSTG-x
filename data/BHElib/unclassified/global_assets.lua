---------------------------------------------------------------------------------------------------
---global_assets
---date: <2021.4
---desc: Loads some global assets into the resource pool
---------------------------------------------------------------------------------------------------

assert(LoadFont("font:hud_default","THlib\\enemy\\bonus2.fnt"))
assert(LoadTTF("font:menu", "fonts/averia/Averia-Regular.ttf", 40))
assert(LoadTTF("font:test", "fonts/averia/Averia-Regular.ttf", 40))
assert(LoadFontOTF("font:noto_sans_sc", "fonts/Noto_Sans_SC/NotoSansSC-Medium.otf", 40))

LoadImageFromFile("image:white", "THlib\\misc\\white.png")
LoadImageFromFile('image:void', 'THlib\\misc\\img_void.png')

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

    LoadImageArray('lifechip', "tex:hint", 288, 16, 16, 15, 4, 1)
    LoadImageArray('bombchip', "tex:hint", 288, 32, 16, 16, 4, 1)

    -- line.png
    LoadTexture("tex:line", "THlib\\UI\\line.png", true)
    LoadImageArray("image_array:icon_line", "tex:line", 0, 0, 200, 8, 1, 7)

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
    -- lifebar.png  -- why is the image rotated???
    images = {
        {"image:boss_ui_hp_bar_full", 0, 0, 10, 32, 5, 0},
        {"image:boss_ui_hp_bar_empty", 10, 0, 8, 32, 5, 0},
        {"image:boss_ui_hp_bar_tip", 18, 0, 10, 16},
    }
    LoadTextureAndImages("tex:boss_ui_hp_bar", images, "THlib\\enemy\\lifebar.png")

    ---enemy1,2,3.png
    images = {
        {"image:fairy_aura_red", 192, 32, 32, 32},
        {"image:fairy_aura_green", 224, 32, 32, 32},
        {"image:fairy_aura_blue", 256, 32, 32, 32},
        {"image:fairy_aura_purple", 288, 32, 32, 32},
        {"image:yin_yang_orb_ring_red", 192, 96, 32, 32},
        {"image:yin_yang_orb_ring_green", 224, 96, 32, 32},
        {"image:yin_yang_orb_ring_blue", 256, 96, 32, 32},
        {"image:yin_yang_orb_ring_purple", 288, 96, 32, 32},
    }
    LoadTextureAndImages("tex:enemy1", images, "THlib/enemy/enemy1.png")
    LoadTexture("tex:enemy2", "THlib/enemy/enemy2.png")
    LoadTexture("tex:enemy3", "THlib/enemy/enemy3.png")

    ---misc
    -- misc.png
    images = {
        {"image:leaf", 0, 32, 32, 32},
        {"image:boss_aura", 0, 128, 128, 128},
        {"image:enemy_kill_effect_red", 192, 0, 64, 64},
        {"image:enemy_kill_effect_green", 192, 64, 64, 64},
        {"image:enemy_kill_effect_blue", 192, 128, 64, 64},
        {"image:enemy_kill_effect_yellow", 192, 192, 64, 64},
    }
    LoadTextureAndImages("tex:misc", images, "THlib\\misc\\misc.png")
    -- SetImageState("image:boss_aura", "mul+add", Color(0x80FFFFFF))

    -- particles.png
    LoadTexture("tex:particles", "THlib\\misc\\particles.png")
    LoadImageArray("image_array:particle", "tex:particles", 0, 0, 32, 32, 4, 4)
end

--lasers
LoadTexture("tex:laser_default", "THlib\\laser\\laser1.png")

-- background
do
    -- boss distortion effect (unused)
    local RENDER_BUFFER_NAME = "rt:boss_distortion"
    local WARP_EFFECT_NAME = "fx:boss_distortion"
    LoadFX(WARP_EFFECT_NAME, "shader/boss_distortion.fx")
    CreateRenderTarget(RENDER_BUFFER_NAME)
    SetShaderUniform("fx:boss_distortion", {
        centerX   = 100.0,
        centerY   = 100.0,
        size      = 50.0,
        arg       = 25.0,
        color     = Color(255, 163, 73, 164),
        colorsize = 80.0,
        timer     = 0.0,
    })
end