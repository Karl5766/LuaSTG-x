---date created: 2021.8.4
---reference: THlib/background/icepool/icepool.lua

local BackgroundSession = require("BHElib.background.background_session")

---@class background.NightPassage:Prefab.Background
local M = LuaClass("background.NightPassage", BackgroundSession)

local Coordinates = require("BHElib.unclassified.coordinates_and_screen")

---------------------------------------------------------------------------------------------------

local Vec3 = math.Vec3

---------------------------------------------------------------------------------------------------

local _image_road = "image:background_night_passage_bricks"
local _image_sky = "image:background_night_passage_sky"
LoadImageFromFile(_image_road, "THlib/background/temple/road.png")
LoadImageFromFile(_image_sky, "backgrounds/night_passage/bg29.png")

---------------------------------------------------------------------------------------------------

function M.__create(stage)
    local self = BackgroundSession.__create(stage, "3d", LAYER_BG)

    self.camera_target_pos = Vec3(0, 0, 0)  -- where camera looks at
    self.camera_offset = Vec3(-2, 0, 1)
    self.camera_forward_speed = 0.012
    self.fog_color = Color(255, 20, 0, 10)
    self.repeat_dx = 1

    self.d = 0
    self.c_x = 0
    self.c_y = 0

    return self
end

function M:ctor()
    self:update()
end

---------------------------------------------------------------------------------------------------

function M:update(dt)
    BackgroundSession.update(self, dt)

    local view3d = Coordinates.getView3d()

    self.d = self.d + self.camera_forward_speed
    local d = self.d - math.floor(self.d, self.repeat_dx)

    self.c_x = self.c_x + 0.03
    self.c_y = 0

    local camera_target_pos = self.camera_target_pos
    camera_target_pos.x = d

    local camera_eye_pos = (camera_target_pos + self.camera_offset)

    view3d.eye = {camera_eye_pos.x, camera_eye_pos.y, camera_eye_pos.z}
    view3d.at = {camera_target_pos.x, camera_target_pos.y, camera_target_pos.z}
    view3d.z = {0.5, 5}
    view3d.up = {camera_target_pos.x, camera_target_pos.y, camera_target_pos.z + 1}
    view3d.fovy = 0.55
    view3d.fog = {2.5, 4, self.fog_color}
    view3d.dirty = true
end

local function TileHorizontallyWithImage(image_name, dx, z, xi_range, yi_range, base_x, base_y)
    local size = FindResSprite(image_name):getSprite():getContentSize()

    local scale = dx / size.height
    local width, height = dx, size.height * scale

    for j = xi_range[1], xi_range[2] do
        local xmin = base_x + j * width
        local xmax = xmin + width
        for i = yi_range[1], yi_range[2] do
            local ymin = base_y + i * height
            local ymax = ymin + height
            Render4V(image_name,
                    xmax, ymin, z,
                    xmax, ymax, z,
                    xmin, ymax, z,
                    xmin, ymin, z)
        end
    end
end

function M:render()
    RenderClear(self.fog_color)  -- clear the view port

    local c_x = self.c_x - math.floor(self.c_x, self.repeat_dx) - 0.5
    local c_y = self.c_y - math.floor(self.c_y, self.repeat_dx) - 0.5

    TileHorizontallyWithImage(_image_road, self.repeat_dx, 0, {-1, 2}, {0, 0}, 0, -0.5 * self.repeat_dx)
    SetImageState(_image_sky, "mul+add", Color(0xA0FFFFFF))
    TileHorizontallyWithImage(_image_sky, self.repeat_dx, 0.25 + 0.25 * sin(self.timer), {-2, 3}, {-2, 1}, c_x, c_y)
end

return M