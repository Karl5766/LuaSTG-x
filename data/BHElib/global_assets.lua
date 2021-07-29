
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

-- hud, icons and hints
LoadImageFromFile("image:menu_hud_background", "THlib\\UI\\menu_bg.png")

LoadTexture("tex:hint", 'THlib\\UI\\hint.png', true)
LoadImage("image:hint_bonus_failed", "tex:hint", 0, 64, 256, 64)
LoadImage('hint.getbonus', "tex:hint", 0, 128, 396, 64)
LoadImage('hint.extend', "tex:hint", 0, 192, 160, 64)
LoadImage('hint.power', "tex:hint", 0, 12, 84, 32)
LoadImage('hint.graze', "tex:hint", 86, 12, 74, 32)
LoadImage('hint.point', "tex:hint", 160, 12, 120, 32)
LoadImage("image:icon_life_outline", "tex:hint", 288, 0, 16, 15)
LoadImage("image:icon_life", "tex:hint", 304, 0, 16, 15)
LoadImage("image:icon_bomb_outline", "tex:hint", 320, 0, 16, 16)
LoadImage("image:icon_bomb", "tex:hint", 336, 0, 16, 16)
LoadImage('kill_time', "tex:hint", 232, 200, 152, 56, 16, 16)
SetImageCenter('hint.power', 0, 16)
SetImageCenter('hint.graze', 0, 16)
SetImageCenter('hint.point', 0, 16)
LoadImageGroup('lifechip', "tex:hint", 288, 16, 16, 15, 4, 1, 0, 0)
LoadImageGroup('bombchip', "tex:hint", 288, 32, 16, 16, 4, 1, 0, 0)
LoadImage('hint.hiscore', "tex:hint", 424, 8, 80, 20)
LoadImage('hint.score', "tex:hint", 424, 30, 64, 20)
LoadImage('hint.Pnumber', "tex:hint", 352, 8, 56, 20)
LoadImage('hint.Bnumber', "tex:hint", 352, 30, 72, 20)
LoadImage('hint.Cnumber', "tex:hint", 352, 52, 40, 20)
SetImageCenter('hint.hiscore', 0, 10)
SetImageCenter('hint.score', 0, 10)
SetImageCenter('hint.Pnumber', 0, 10)
SetImageCenter('hint.Bnumber', 0, 10)


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