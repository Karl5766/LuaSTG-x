
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

LoadImageFromFile("image:menu_hud_background", "THlib\\UI\\menu_bg.png")

LoadImageFromFile('image:white', 'THlib\\misc\\white.png')

LoadImageFromFile("image:test", "data_assets/THlib/bullet/Magic1.png")

LoadImageFromFile("image:button_normal", "creator/image/default_btn_normal.png")
LoadImageFromFile("image:button_pressed", "creator/image/default_btn_pressed.png")

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