
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

LoadImageFromFile("image:menu_hud_background", "THlib\\UI\\menu_bg.png")

LoadImageFromFile('image:white', 'THlib\\misc\\white.png')

LoadImageFromFile("image:test", "data_assets/THlib/bullet/Magic1.png")

LoadImageFromFile("image:button_normal", "creator/image/default_btn_normal.png")
LoadImageFromFile("image:button_pressed", "creator/image/default_btn_pressed.png")