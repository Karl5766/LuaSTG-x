---------------------------------------------------------------------------------------------------
---bullet_types.lua
---author: Karl
---date: 2021.4.22
---references: THlib/bullet/bullet.lua
---desc: Defines bullet types, parameters and manages loading enemy bullet related sprites
---------------------------------------------------------------------------------------------------

---@class BulletTypes
local M = {}

---below are some information tables that this file is responsible for initializing

---contains information about a given bullet type
---has 3 attributes:
---color_to_sprite_name (table) - map from color to the sprite name
---sprite_array_name (string) - name of sprite array
---available_colors (table) - show an array of available colors; indexed by bullet type name
---size (number) - size of visual effect
M.bullet_type_to_info = {}
local bullet_type_to_info = M.bullet_type_to_info

---names of all bullet types as an array
M.all_bullet_types = {}

---a 2d array [bullet_type_i][color_j] = {bullet_type_name, color_index} of all possible type color
---combinations; note here i and j are not the same as bullet_type and color_index, the order is not
---guaranteed
M.all_bullet_type_color = {}

---color_index to image name of the blink effect
M.color_index_to_blink_effects = {}
local _color_index_to_blink_effects = M.color_index_to_blink_effects

---color_index to animation name of the cancel effect
M.color_index_to_cancel_effects = {}
local color_index_to_cancel_effects = M.color_index_to_cancel_effects

---------------------------------------------------------------------------------------------------

local ColorThemes = require("BHElib.unclassified.color")
local _touhou_theme = ColorThemes.touhou_theme
local _touhou_theme_half = ColorThemes.touhou_theme_half
local _mugenri_theme = ColorThemes.mugenri_theme
local _mugenri_theme_animated = ColorThemes.mugenri_theme_animated

---------------------------------------------------------------------------------------------------
---bullets

---width, height, x, y (from up-left), collision_radius, size (of visual effect), num_images_in_row, num_images_in_col, tex_name,
---available_colors, dx, dy (default to width, height), blend_mode (default to "mul+alpha")
local bullets = {
    -- each row loads a column in the image file
    arrowhead =     {16, 16, 0, 0, 2.5, 0.6, 1, 16, "tex:bullet_sprite_1", _touhou_theme},
    gun_bullet =    {16, 16, 24, 0, 2.5, 0.4, 1, 16, "tex:bullet_sprite_1", _touhou_theme},
    butterfly =     {32, 32, 112, 0, 4.0, 0.7, 1, 8, "tex:bullet_sprite_1", _touhou_theme_half},
    square =        {16, 16, 152, 0, 3.0, 0.8, 1, 16, "tex:bullet_sprite_1", _touhou_theme},
    ball =          {32, 32, 176, 0, 4.0, 0.75, 1, 8, "tex:bullet_sprite_1", _touhou_theme_half},
    ball_big =      {32, 32, 192, 0, 4.5, 1.0, 1, 8, "tex:bullet_sprite_2", _touhou_theme_half},
    mildew =        {16, 16, 208, 0, 2.0, 0.401, 1, 16, "tex:bullet_sprite_1", _touhou_theme},
    ellipse =       {32, 32, 224, 0, 4.5, 0.701, 1, 8, "tex:bullet_sprite_1", _touhou_theme_half},

    star =          {16, 16, 96, 0, 3.0, 0.5, 1, 16, "tex:bullet_sprite_2", _touhou_theme},
    star_big =      {32, 32, 224, 0, 5.5, 0.998, 1, 8, "tex:bullet_sprite_2", _touhou_theme_half},
    point =         {16, 16, 176, 0, 2.0, 0.402, 1, 16, "tex:bullet_sprite_2", _touhou_theme},
    grain =         {16, 16, 160, 0, 2.5, 0.403, 1, 16, "tex:bullet_sprite_2", _touhou_theme},
    shard =         {16, 16, 128, 0, 2.5, 0.404, 1, 16, "tex:bullet_sprite_2", _touhou_theme},

    --knife =         {32, 32, 0, 0, 4.0, 0.754, 1, 8, "tex:bullet_sprite_3", _touhou_theme_half},
    --grain_dark =    {16, 16, 48, 0, 2.5, 0.405, 1, 16, "tex:bullet_sprite_3", _touhou_theme},
    --kunai =         {16, 16, 80, 0, 2.5, 0.407, 1, 16, "tex:bullet_sprite_3", _touhou_theme},
    --droplet =       {16, 16, 112, 0, 2.5, 0.406, 1, 16, "tex:bullet_sprite_3", _touhou_theme},
    --
    --ball_glow =     {32, 32, 64, 0, 4.0, 0.751, 1, 8, "tex:bullet_sprite_4", _touhou_theme_half},
    --arrow =         {32, 32, 96, 0, 3.5, 0.61, 1, 8, "tex:bullet_sprite_4", _touhou_theme_half},
    --heart =         {32, 32, 128, 0, 9.0, 1.0, 1, 8, "tex:bullet_sprite_4", _touhou_theme_half},
    --knife_b =       {32, 32, 192, 0, 3.5, 0.755, 1, 8, "tex:bullet_sprite_4", _touhou_theme_half},
    --ball_ring =     {16, 16, 232, 8, 4.0, 0.752, 1, 8, "tex:bullet_sprite_4", _touhou_theme_half, 16, 32},  -- not aligned the same way as others
    --money =         {16, 16, 168, 0, 4.0, 0.753, 1, 8, "tex:bullet_sprite_4", _touhou_theme_half},
    --
    ---- miscellaneous
    --ball_light =    {64, 64, 0, 0, 11.5, 2.0, 4, 2, "tex:bullet_ball_light", _touhou_theme_half, nil, nil, "mul+add"; is_row_major = true},  -- with 2 rows & 4 columns
    bubble =        {64, 64, 0, 0, 14.0, 2.0, 4, 2, "tex:bullet_bubble", _touhou_theme_half, nil, nil, "mul+add"; is_row_major = true},
    --music_rest =    {32, 32, 192, 0, 4.5, 0.8, 1, 8, "tex:bullet_sprite_6", _touhou_theme_half},

    ---Mugenri Shots for experimentation
    --mugenri_jewel = {16, 16, 752, 0, 5.5, 0.75, 1, 9, "tex:mugenri_shot", _mugenri_theme},
}

---some bullet sprites are not exactly centered, set the image center manually
local bullet_sprite_center = {
    star_big = {15.5, 16},
    arrow = {24, 16},
}

---some bullets are animated, they need to be loaded via LoadAnimation
---width, height (of a single frame), x, y (from up-left), collision_radius, size, num_images_in_animation, num_animations,
---interval (time between two images in frames), tex_name, available_colors, blend_mode (default to "")
local animated_bullets = {
    -- each animation is a column of images; we can load each row for each color of the bullet
    fireball =      {48, 32, 0, 0, 4.0, 0.702, 4, 8, 4, "tex:bullet_fireball", _touhou_theme_half, "mul+add"},
    music_note =    {60, 32, 0, 0, 4.0, 0.8, 3, 8, 8, "tex:bullet_music_note", _touhou_theme_half},

    --mugenri_crystal = {32, 32, 128, 0, 10.0, 1.6, 4, 9, 4, "tex:mugenri_shot", _mugenri_theme_animated},
    --mugenri_shuriken = {32, 32, 128, 256, 6.0, 1.0, 3, 9, 8, "tex:mugenri_shot", _mugenri_theme_animated},
    --mugenri_sperm = {32, 32, 128, 640, 6.0, 1.0, 3, 9, 8, "tex:mugenri_shot", _mugenri_theme_animated},
    --
    --mugenri_yin_yang = {32, 32, 416, 0, 11.5, 2.0, 4, 9, 8, "tex:mugenri_shot", _mugenri_theme_animated},
    --mugenri_rot_ellipse = {32, 32, 416, 256, 9.0, 1.5, 4, 9, 8, "tex:mugenri_shot", _mugenri_theme_animated},
    --mugenri_fire_sword = {32, 32, 416, 512, 6.0, 1.0, 4, 9, 8, "tex:mugenri_shot", _mugenri_theme_animated},
    --mugenri_fire_sword_shadow = {32, 32, 416, 640, 6.0, 1.0, 4, 9, 8, "tex:mugenri_shot", _mugenri_theme_animated},
    --mugenri_shock_wave = {32, 32, 416, 768, 10.0, 1.8, 4, 9, 8, "tex:mugenri_shot", _mugenri_theme_animated},

}

local inclusion_list = {
    1,2,3,4,5,6,7,8,9,10,
    11,12,13,14,15,16,17,18,19,20,
    21,22,23,24,25,26,27,28,29,30,
    31,32,33,34,35,36,37,38,39,40,
    41,42,43,44,45,46,47,48,49,50,
    51,52,53,54,55,56,57,58,59,60,
    61,62,63,64,65,66,67,
}
local function LoadFireBullet(i)
    local ri = i
    if ri <= 19 then
        animated_bullets["fire_bullet_x2_"..i] = {
            32, 32, 0, (ri - 1) * 32, 6.0, 1.2, 4, 1, 8,
            "tex:fire_bullet_1", ColorThemes.fire_bullet_theme;
            is_row_major = true}
        return
    end
    ri = ri - 19

    if ri <= 14 then
        animated_bullets["fire_bullet_x2_"..i] = {
            32, 32, 0, (ri - 1) * 32, 6.0, 1.2, 4, 1, 8,
            "tex:fire_bullet_2", ColorThemes.fire_bullet_theme;
            is_row_major = true}
        return
    end
    ri = ri - 14

    if ri <= 14 then
        animated_bullets["fire_bullet_x2_"..i] = {
            32, 32, 192, (ri - 1) * 32, 6.0, 1.2, 4, 1, 8,
            "tex:fire_bullet_2", ColorThemes.fire_bullet_theme;
            is_row_major = true}
        return
    end
    ri = ri - 14

    if ri <= 20 then
        animated_bullets["fire_bullet_x2_"..i] = {
            32, 32, 0, (ri - 1) * 32, 6.0, 1.2, 4, 1, 8,
            "tex:fire_bullet_3", ColorThemes.fire_bullet_theme;
            is_row_major = true}
        return
    end
    error("Error: Unexpected index!")
end
for j = 1, #inclusion_list do
    local i = inclusion_list[j]
    LoadFireBullet(i)
end

---------------------------------------------------------------------------------------------------
--- init

---@param sprite_name_prefix string prefix of the sprite name; the sprite names are obtained by appending 1, 2, ... to the end of it
---@param available_colors table an array of available colors for this type of bullet
local function CreateColorToSpriteNameMap(sprite_name_prefix, available_colors)
    local color_to_sprite_name = {}
    for i = 1, #available_colors do
        local color = available_colors[i]
        color_to_sprite_name[color] = sprite_name_prefix..i
    end
    return color_to_sprite_name
end

local function GenerateTypeColorCombinations(bullet_type_name, available_colors)
    local ret = {}
    for i = 1, #available_colors do
        local color = available_colors[i]
        ret[#ret + 1] = {bullet_type_name, color}
    end
    return ret
end

local function LoadResources()
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

    LoadTexture("tex:mugenri_shot", "bullets\\Mugenri PC-98 Shot\\MugenriShot.png")

    LoadTexture("tex:fire_bullet_1", "bullets\\FireBullet\\Part1x2.png")
    LoadTexture("tex:fire_bullet_2", "bullets\\FireBullet\\Part2x2.png")
    LoadTexture("tex:fire_bullet_3", "bullets\\FireBullet\\Part3x2.png")
end

function M.init()
    LoadResources()

    M.all_bullet_types = {}

    -- image bullets
    for bullet_type_name, item in pairs(bullets) do
        local image_array_name = "image_array:"..bullet_type_name

        local center_x, center_y = nil, nil
        if bullet_sprite_center[bullet_type_name] ~= nil then
            center_x, center_y = unpack(bullet_sprite_center[bullet_type_name])
        end

        if item.is_row_major then
            M.loadSpriteRowMajor(
                    image_array_name,
                    item[1], item[2], item[3], item[4], item[5],
                    item[7], item[8], item[9], item[11], item[12],
                    item[13], center_x, center_y)
        else
            M.loadSpriteColumnMajor(
                    image_array_name,
                    item[1], item[2], item[3], item[4], item[5],
                    item[7], item[8], item[9], item[11], item[12],
                    item[13], center_x, center_y)
        end

        local available_colors = item[10]
        local color_to_sprite_name = CreateColorToSpriteNameMap(image_array_name, available_colors)
        local bullet_info = {
            color_to_sprite_name = color_to_sprite_name,
            sprite_array_name = image_array_name,
            available_colors = available_colors,
            size = item[6],  -- visual effect size
        }
        bullet_type_to_info[bullet_type_name] = bullet_info

        M.all_bullet_types[#M.all_bullet_types + 1] = bullet_type_name
        M.all_bullet_type_color[#M.all_bullet_type_color + 1] = GenerateTypeColorCombinations(bullet_type_name, available_colors)
    end

    -- animated bullets
    for bullet_type_name, item in pairs(animated_bullets) do
        local ani_array_name = "ani_array:"..bullet_type_name
        M.loadAnimationGrid(
                ani_array_name,
                item[1], item[2], item[3], item[4], item[5],
                item[7], item[8], item[9], item[10], item[12], item.is_row_major)
        local available_colors = item[11]
        local color_to_sprite_name = CreateColorToSpriteNameMap(ani_array_name, available_colors)
        local bullet_info = {
            color_to_sprite_name = color_to_sprite_name,
            sprite_array_name = ani_array_name,
            available_colors = available_colors,
            size = item[6],  -- visual effect size
        }
        bullet_type_to_info[bullet_type_name] = bullet_info

        M.all_bullet_types[#M.all_bullet_types + 1] = bullet_type_name
        M.all_bullet_type_color[#M.all_bullet_type_color + 1] = GenerateTypeColorCombinations(bullet_type_name, available_colors)
    end

    M.initBulletEffects()
end

---------------------------------------------------------------------------------------------------
---loading images/animations from textures

---@param image_array_name string name of the image array
---@param width number width of the bullet sprite in pixels
---@param height number height of the bullet sprite in pixels
function M.loadSprite(image_array_name, width, height,
                        x, y, collision_radius, i_num, j_num,
                        tex_name, dxi, dyi, dxj, dyj,
                        blend_mode, set_center_x, set_center_y,
                        scale)
    -- default values
    blend_mode = blend_mode or "mul+alpha"

    local counter = 1
    for i = 0, i_num - 1 do
        for j = 0, j_num - 1 do
            local cur_x, cur_y = x + i * dxi + j * dxj, y + i * dyi + j * dyj
            local image_name = image_array_name..counter
            local resSprite = LoadImage(image_name, tex_name, cur_x, cur_y, width, height, collision_radius, collision_radius)

            if blend_mode then
                resSprite:setRenderMode(blend_mode)
            end

            if set_center_x or set_center_y then
                set_center_x = set_center_x or width / 2
                set_center_y = set_center_y or height / 2
                SetImageCenter(image_name, set_center_x, set_center_y)
            end
            counter = counter + 1
        end
    end
end

---@param image_array_name string name of the image array
---@param width number width of the bullet sprite in pixels
---@param height number height of the bullet sprite in pixels
function M.loadSpriteRowMajor(image_array_name, width, height,
                      x, y, collision_radius, num_images_in_row,
                      num_images_in_col, tex_name, dx, dy,
                      blend_mode, set_center_x, set_center_y)
    dx = dx or width
    dy = dy or height
    M.loadSprite(image_array_name, width, height,
            x, y, collision_radius, num_images_in_col,
            num_images_in_row, tex_name, 0, dy, dx, 0,
            blend_mode, set_center_x, set_center_y)
end

---@param image_array_name string name of the image array
---@param width number width of the bullet sprite in pixels
---@param height number height of the bullet sprite in pixels
function M.loadSpriteColumnMajor(image_array_name, width, height,
                              x, y, collision_radius, num_images_in_row,
                              num_images_in_col, tex_name, dx, dy,
                              blend_mode, set_center_x, set_center_y)
    dx = dx or width
    dy = dy or height
    M.loadSprite(image_array_name, width, height,
            x, y, collision_radius, num_images_in_row,
            num_images_in_col, tex_name, dx, 0, 0, dy,
            blend_mode, set_center_x, set_center_y)
end

---load a grid of animations, each animation is a grid of images
function M.loadAnimationArray(animation_array_name, width, height,
                             x, y, collision_radius, num_image_row,
                             num_image_col, num_animation_row, animation_row_dy,
                             num_animation_col, animation_col_dx, interval,
                             tex_name, blend_mode)

    blend_mode = blend_mode or "mul+alpha"

    local counter = 1  -- current # of animation
    for l = 1, num_animation_row do
        for m = 1, num_animation_col do
            -- each loop here loads a single animation
            local cur_x, cur_y = x + (m - 1) * animation_col_dx, y + (l - 1) * animation_row_dy

            local animation_name = animation_array_name..counter
            local res_animation = LoadAnimation(
                    animation_name,
                    tex_name,
                    cur_x,
                    cur_y,
                    width,
                    height,
                    num_image_col,
                    num_image_row,
                    interval,
                    collision_radius,
                    collision_radius)


            if blend_mode then
                res_animation:setRenderMode(blend_mode)
            end
            counter = counter + 1
        end
    end
end

function M.loadAnimationGrid(animation_array_name, width, height,
                            x, y, collision_radius, num_images_in_animation,
                            num_animations, interval, tex_name,
                            blend_mode, is_row_major)
    if is_row_major ~= true then
        ---load a grid of images, each column represents a different animation
        M.loadAnimationArray(animation_array_name, width, height, x, y,
                collision_radius, num_images_in_animation, 1, 1,
                0, num_animations, width, interval, tex_name, blend_mode)
    else
        ---load a grid of images, each row represents a different animation
        M.loadAnimationArray(animation_array_name, width, height, x, y,
                collision_radius, 1, num_images_in_animation, num_animations,
                height, 1, 0, interval, tex_name, blend_mode)
    end
end

---------------------------------------------------------------------------------------------------

function M.initBulletEffects()

    -- bullet blink
    M.loadSpriteColumnMajor("image_array:bullet_blink",
            32, 32, 80, 0,
            nil, 1, 8,
            "tex:bullet_sprite_1")
    for i = 1, #_touhou_theme do
        local color = _touhou_theme[i]
        _color_index_to_blink_effects[color] = "image_array:bullet_blink"..math.ceil(i / 2)
    end
    _color_index_to_blink_effects[COLOR_PINK] = _color_index_to_blink_effects[COLOR_RED]

    -- bullet cancel
    local bullet_cancel_color = {
        [COLOR_RED] = Color(0xC0FF3030),
        [COLOR_PURPLE] = Color(0xC0FF30FF),
        [COLOR_BLUE] = Color(0xC03030FF),
        [COLOR_CYAN] = Color(0xC030FFFF),
        [COLOR_GREEN] = Color(0xC030FF30),
        [COLOR_YELLOW] = Color(0xC0FFFF30),
        [COLOR_ORANGE] = Color(0xC0FF8030),
        [COLOR_GRAY] = Color(0xC0D0D0D0),
        [COLOR_PINK] = Color(0xC0FFC0CB),
    }
    for i = 1, #ColorThemes.touhou_theme_other_half do
        local other_index = ColorThemes.touhou_theme_other_half[i]
        local index = _touhou_theme_half[i]
        bullet_cancel_color[other_index] = 0.5 * bullet_cancel_color[index] + Color(0x60000000)
    end

    ---load the bullet cancel effect as a *separate animation for each color
    for i = 1, #ColorThemes.all_color_indices do
        local ani_name = "ani_array:bullet_cancel"..i

        -- compute blend mode
        local blend_mode = "mul+add"
        --if i == 15 then
        --    blend_mode = "mul+alpha"
        --end
        LoadAnimation(
                ani_name, "tex:bullet_cancel", 0, 0,
                64, 64, 4, 2, 3,
                nil, nil)

        -- compute color
        local color = bullet_cancel_color[i]
        SetAnimationState(ani_name, blend_mode, color)
        color_index_to_cancel_effects[i] = ani_name
    end
end

return M