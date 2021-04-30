---------------------------------------------------------------------------------------------------
---bullet_types.lua
---author: Karl
---date: 2021.4.22
---references: THlib/bullet/bullet.lua
---desc: Defines bullet types, parameters and manages loading enemy bullet related sprites
---------------------------------------------------------------------------------------------------

---@class BulletTypes
local M = {}

---contains information about a given bullet type
---has 3 attributes:
---color_to_sprite_name (table) - map from color to the sprite name
---sprite_array_name (string) - name of sprite array
---size (number) - size of visual effect
M.bullet_type_to_info = {}
local bullet_type_to_info = M.bullet_type_to_info

---color_index to image name of the blink effect
M.color_index_to_blink_effects = {}
local color_index_to_blink_effects = M.color_index_to_blink_effects

---color_index to animation name of the cancel effect
M.color_index_to_cancel_effects = {}
local color_index_to_cancel_effects = M.color_index_to_cancel_effects

---------------------------------------------------------------------------------------------------
---bullets

---width, height, x, y (from up-left), collision_radius, size (of visual effect), num_images_in_row, num_images_in_col, tex_name,
---dx, dy (default to width, height), blend_mode (default to "mul+alpha")
local bullets = {
    -- each row loads a column in the image file
    arrowhead =     {16, 16, 0, 0, 2.5, 0.6, 1, 16, "tex:bullet_sprite_1"},
    gun_bullet =    {16, 16, 24, 0, 2.5, 0.4, 1, 16, "tex:bullet_sprite_1"},
    butterfly =     {32, 32, 112, 0, 4.0, 0.7, 1, 8, "tex:bullet_sprite_1"},
    square =        {16, 16, 152, 0, 3.0, 0.8, 1, 16, "tex:bullet_sprite_1"},
    ball =          {32, 32, 176, 0, 4.0, 0.75, 1, 8, "tex:bullet_sprite_1"},
    mildew =        {16, 16, 208, 0, 2.0, 0.401, 1, 16, "tex:bullet_sprite_1"},
    ellipse =       {32, 32, 224, 0, 4.5, 0.701, 1, 8, "tex:bullet_sprite_1"},

    star =          {16, 16, 96, 0, 3.0, 0.5, 1, 16, "tex:bullet_sprite_2"},
    star_big =      {32, 32, 224, 0, 5.5, 0.998, 1, 8, "tex:bullet_sprite_2"},
    ball_big =      {32, 32, 192, 0, 4.5, 1.0, 1, 8, "tex:bullet_sprite_2"},
    pellet =        {16, 16, 176, 0, 2.0, 0.402, 1, 16, "tex:bullet_sprite_2"},
    grain =         {16, 16, 160, 0, 2.5, 0.403, 1, 16, "tex:bullet_sprite_2"},
    shard =         {16, 16, 128, 0, 2.5, 0.404, 1, 16, "tex:bullet_sprite_2"},

    knife =         {32, 32, 0, 0, 4.0, 0.754, 1, 8, "tex:bullet_sprite_3"},
    grain_dark =    {16, 16, 48, 0, 2.5, 0.405, 1, 16, "tex:bullet_sprite_3"},
    kunai =         {16, 16, 80, 0, 2.5, 0.407, 1, 16, "tex:bullet_sprite_3"},
    droplet =       {16, 16, 112, 0, 2.5, 0.406, 1, 16, "tex:bullet_sprite_3"},

    ball_glow =     {32, 32, 64, 0, 4.0, 0.751, 1, 8, "tex:bullet_sprite_4"},
    arrow =         {32, 32, 96, 0, 3.5, 0.61, 1, 8, "tex:bullet_sprite_4"},
    heart =         {32, 32, 128, 0, 9.0, 1.0, 1, 8, "tex:bullet_sprite_4"},
    knife_b =       {32, 32, 192, 0, 3.5, 0.755, 1, 8, "tex:bullet_sprite_4"},
    ball_ring =     {16, 16, 232, 8, 4.0, 0.752, 1, 8, "tex:bullet_sprite_4", 16, 32},  -- not aligned the same way as others
    money =         {16, 16, 168, 0, 4.0, 0.753, 1, 8, "tex:bullet_sprite_4"},

    -- miscellaneous
    ball_light =    {64, 64, 0, 0, 11.5, 2.0, 4, 2, "tex:bullet_ball_light", nil, nil, "mul+add"},  -- with 2 rows & 4 columns
    bubble =        {64, 64, 0, 0, 14.0, 2.0, 4, 2, "tex:bullet_bubble", nil, nil, "mul+add"},
    music_rest =    {32, 32, 192, 0, 4.5, 0.8, 1, 8, "tex:bullet_sprite_6"},
}

---some bullet sprites are not exactly centered, set the image center manually
local bullet_sprite_center = {
    star_big = {15.5, 16},
    arrow = {24, 16},
}

---some bullets are animated, they need to be loaded via LoadAnimation
---width, height (of a single frame), x, y (from up-left), collision_radius, size, num_images_in_animation, num_animations,
---interval (time between two images in frames), tex_name, blend_mode (default to "")
local animated_bullets = {
    -- each animation is a column of images; we can load each row for each color of the bullet
    fireball =      {48, 32, 0, 0, 4.0, 0.702, 4, 8, 4, "tex:bullet_fireball", "mul+add"},
    music_note =    {60, 32, 0, 0, 4.0, 0.8, 3, 8, 8, "tex:bullet_music_note"},
}

---------------------------------------------------------------------------------------------------
---bullet type & color related mappings

local NUM_COLORS = 16

COLOR_DEEP_RED = 1
COLOR_RED = 2
COLOR_DEEP_PURPLE = 3
COLOR_PURPLE = 4
COLOR_DEEP_BLUE = 5
COLOR_BLUE = 6
COLOR_ROYAL_BLUE = 7
COLOR_CYAN = 8
COLOR_DEEP_GREEN = 9
COLOR_GREEN = 10
COLOR_CHARTREUSE = 11
COLOR_YELLOW = 12
COLOR_GOLDEN_YELLOW = 13
COLOR_ORANGE = 14
COLOR_DEEP_GRAY = 15
COLOR_GRAY = 16


---------------------------------------------------------------------------------------------------
--- init

---@param sprite_name_prefix string prefix of the sprite name; the sprite names are obtained by appending 1, 2, ... to the end of it
---@param half_flag boolean if true, the sprite to map to only has half of the number of images
local function CreateColorToSpriteNameMap(sprite_name_prefix, half_flag)
    -- typically there are NUM_COLORS / 2 or NUM_COLORS images for a bullet type, each has a different color
    local color_to_sprite_name = {}
    if half_flag then
        for i = 1, NUM_COLORS do
            color_to_sprite_name[i] = sprite_name_prefix..math.ceil(i / 2)
        end
    else
        for i = 1, NUM_COLORS do
            color_to_sprite_name[i] = sprite_name_prefix..i
        end
    end
    return color_to_sprite_name
end

---create a mapping that maps from bullet type & color to sprite name
local function CreateColorToSpriteNameMapFromImageNum(sprite_name_prefix, total_image_num)
    if total_image_num == NUM_COLORS then
        return CreateColorToSpriteNameMap(sprite_name_prefix, false)
    elseif total_image_num == NUM_COLORS / 2 then
        return CreateColorToSpriteNameMap(sprite_name_prefix, true)
    else
        error("the grid for this bullet type contains unexpected number of images. \n"..
                "The number needs to be 8 or 16. bullet type has sprite name prefix "..sprite_name_prefix)
    end
end

function M.init()
    -- image bullets
    for bullet_type_name, item in pairs(bullets) do
        local image_array_name = "image_array:"..bullet_type_name

        local center_x, center_y = nil, nil
        if bullet_sprite_center[bullet_type_name] ~= nil then
            center_x, center_y = unpack(bullet_sprite_center[bullet_type_name])
        end

        M.loadSprite(
                image_array_name,
                item[1], item[2], item[3], item[4], item[5],
                item[7], item[8], item[9], item[10], item[11],
                item[12], center_x, center_y
        )

        local total_image_num = item[7] * item[8]  -- nImg = nRow * nCol
        local bullet_info = {
            color_to_sprite_name = CreateColorToSpriteNameMapFromImageNum(image_array_name, total_image_num),
            sprite_array_name = image_array_name,
            size = item[6]  -- visual effect size
        }
        bullet_type_to_info[bullet_type_name] = bullet_info
    end

    -- animated bullets
    for bullet_type_name, item in pairs(animated_bullets) do
        local ani_array_name = "ani_array:"..bullet_type_name
        M.loadColumnAnimation(
                ani_array_name,
                item[1], item[2], item[3], item[4], item[5],
                item[7], item[8], item[9], item[10], item[11]
        )
        local total_image_num = item[8]
        local bullet_info = {
            color_to_sprite_name = CreateColorToSpriteNameMapFromImageNum(ani_array_name, total_image_num),
            sprite_array_name = ani_array_name,
            size = item[6]  -- visual effect size
        }
        bullet_type_to_info[bullet_type_name] = bullet_info
    end

    M.initBulletEffects()
end

---------------------------------------------------------------------------------------------------
---loading images/animations from textures

---@param image_array_name string name of the image array
---@param width number width of the bullet sprite in pixels
---@param height number height of the bullet sprite in pixels
function M.loadSprite(image_array_name,
                            width,
                            height,
                            x,
                            y,
                            collision_radius,
                            num_images_in_row,
                            num_images_in_col,
                            tex_name,
                            dx,
                            dy,
                            blend_mode,
                            set_center_x,
                            set_center_y)
    -- default values
    dx = dx or width
    dy = dy or height
    blend_mode = blend_mode or "mul+alpha"

    local counter = 1
    for i = 1, num_images_in_row do
        for j = 1, num_images_in_col do
            local cur_x, cur_y = x + (i - 1) * dx, y + (j - 1) * dy
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

---load a grid of animations, each animation is a grid of images
function M.loadAnimationArray(animation_array_name,
                             width,
                             height,
                             x,
                             y,
                             collision_radius,
                             num_image_row,
                             num_image_col,
                             num_animation_row,
                             animation_row_dy,
                             num_animation_col,
                             animation_col_dx,
                             interval,
                             tex_name,
                             blend_mode)

    blend_mode = blend_mode or "mul+alpha"

    local counter = 1  -- current # of animation
    for l = 1, num_animation_row do
        for m = 1, num_animation_col do
            -- each loop here loads a single animation
            local cur_x, cur_y = x + (m - 1) * animation_col_dx, y + (l - 1) * animation_row_dy

            local animation_name = animation_array_name..counter
            local resAnimation = LoadAnimation(
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
                    collision_radius
            )

            if blend_mode then
                resAnimation:setRenderMode(blend_mode)
            end
            counter = counter + 1
        end
    end
end

---load a grid of images, each column represent a different animation
function M.loadColumnAnimation(animation_array_name,
                            width,
                            height,
                            x,
                            y,
                            collision_radius,
                            num_images_in_animation,
                            num_animations,
                            interval,
                            tex_name,
                            blend_mode)
    M.loadAnimationArray(
            animation_array_name,
            width,
            height,
            x,
            y,
            collision_radius,
            num_images_in_animation,
            1,
            1,
            0,
            num_animations,
            width,
            interval,
            tex_name,
            blend_mode
    )
end

---------------------------------------------------------------------------------------------------

function M.initBulletEffects()

    -- bullet blink
    M.loadSprite("image_array:bullet_blink",
            32,
            32,
            80,
            0,
            nil,
            1,
            8,
            "tex:bullet_sprite_1")
    for i = 1, NUM_COLORS do
        color_index_to_blink_effects[i] = "image_array:bullet_blink"..math.ceil(i / 2)
    end

    -- bullet cancel
    local bullet_cancel_color = {
        Color(0xC0FF3030), --red
        Color(0xC0FF30FF), --purple
        Color(0xC03030FF), --blue
        Color(0xC030FFFF), --cyan
        Color(0xC030FF30), --green
        Color(0xC0FFFF30), --yellow
        Color(0xC0FF8030), --orange
        Color(0xC0D0D0D0), --gray
    }

    ---load the bullet cancel effect as a separate animation for each color
    for i = 1, NUM_COLORS do
        local ani_name = "ani_array:bullet_cancel"..i

        -- compute blend mode
        local blend_mode = "mul+add"
        if i == 15 then
            blend_mode = "mul+alpha"
        end
        LoadAnimation(
                ani_name,
                "tex:bullet_cancel",
                0,
                0,
                64,
                64,
                4,
                2,
                3,
                nil,
                nil
        )

        -- compute color
        local index = math.ceil(i / 2)
        local color = bullet_cancel_color[index]
        if i % 2 == 1 then
            color = 0.5 * color + Color(0x60000000)
        end

        SetAnimationState(ani_name, blend_mode, color)
        color_index_to_cancel_effects[i] = ani_name
    end
end

return M