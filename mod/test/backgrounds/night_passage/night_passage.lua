---date created: 2021.8.4
---reference: THlib/background/icepool/icepool.lua

local BackgroundSession = require("BHElib.background.background_session")

---@class background.NightPassage:Prefab.Background
local M = LuaClass("background.NightPassage", BackgroundSession)

local Coordinates = require("BHElib.unclassified.coordinates_and_screen")

---------------------------------------------------------------------------------------------------

local Vec3 = math.Vec3

---------------------------------------------------------------------------------------------------

local _image_road = "image:background_night_passage_road"
local _image_pillar = "image:background_night_passage_pillar"
local _image_ground = "image:background_night_passage_ground"
LoadImageFromFile(_image_road, "THlib/background/temple/road.png")
LoadImageFromFile(_image_pillar, "THlib/background/temple/pillar.png")
LoadImageFromFile(_image_ground, "THlib/background/temple/ground.png")
local _image_road_sprite = FindResSprite(_image_road)

---------------------------------------------------------------------------------------------------

function M.__create(stage)
    local self = BackgroundSession.__create(stage, "3d", LAYER_BG)

    self.camera_target_pos = Vec3(0, 0, 0)  -- where camera looks at
    self.camera_offset = Vec3(-2.2, 0, 1)
    self.camera_forward_speed = 0.013
    self.fog_color = Color(255, 40, 0, 20)
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
    view3d.fovy = 0.7
    view3d.fog = {3, 5, self.fog_color}
    view3d.dirty = true
end

local function TileHorizontallyWithImage(image_name, dx, z, xi_range, yi_range, base_x, base_y, flipped)
    local size = FindResSprite(image_name):getSprite():getContentSize()

    local scale = dx / size.height
    local width, height = dx, size.height * scale

    for j = xi_range[1], xi_range[2] do
        local xmin = base_x + j * width
        local xmax = xmin + width
        for i = yi_range[1], yi_range[2] do
            local ymin = base_y + i * height
            local ymax = ymin + height
            if not flipped then
                Render4V(image_name,
                        xmax, ymin, z,
                        xmax, ymax, z,
                        xmin, ymax, z,
                        xmin, ymin, z)
            else
                Render4V(image_name,
                        xmax, ymax, z,
                        xmax, ymin, z,
                        xmin, ymin, z,
                        xmin, ymax, z)
            end
        end
    end
end

local function RenderPillars(image_name, dx, y, pillar_height, xi_range, base_x, base_y, base_z, radius, imin, light_angle)
    local top_z = base_z + pillar_height

    for j = xi_range[2], xi_range[1], -1 do
        local pillar_x = base_x + j * dx
        local pillar_y = base_y + y

        local imax, di = imin + 7, 1

        for i = imin, imax, di do
            -- compute two base points of the rectangles that touch the ground
            local angle1 = i * 45 - 22.5
            local x1, y1 = pillar_x + radius * cos(angle1), pillar_y + radius * sin(angle1)
            local angle2 = angle1 + 45
            local x2, y2 = pillar_x + radius * cos(angle2), pillar_y + radius * sin(angle2)
            local dot = cos(angle1) * cos(light_angle) + sin(angle1) * sin(light_angle)
            local brightness = 125 + 125 * dot

            SetImageState(image_name, "mul+alpha", Color(255, brightness, brightness, brightness))
            Render4V(image_name,
                    x2, y2, top_z,
                    x1, y1, top_z,
                    x1, y1, base_z,
                    x2, y2, base_z)
        end
    end
end

function M:render()
    self:preRender()
    RenderClear(self.fog_color)  -- clear the view port

    local repeat_dx = self.repeat_dx
    local c_x = self.c_x - math.floor(self.c_x, repeat_dx) - 0.5
    local c_y = self.c_y - math.floor(self.c_y, repeat_dx) - 0.5

    local alpha = self.timer * 1
    if alpha > 255 then
        alpha = 255
    end

    TileHorizontallyWithImage(_image_ground, repeat_dx, 0, {-2, 2}, {-1, -1}, 0, -0.5 * repeat_dx, false)
    TileHorizontallyWithImage(_image_ground, repeat_dx, 0, {-2, 2}, {1, 1}, 0, -0.5 * repeat_dx, true)
    TileHorizontallyWithImage(_image_road, repeat_dx, 0, {-2, 2}, {0, 0}, 0, -0.5 * repeat_dx, true)
    local size = _image_road_sprite:getSprite():getContentSize()
    local pillar_y = repeat_dx / size.height * size.width * 0.5
    RenderPillars(_image_pillar, repeat_dx, pillar_y, 1, {-1, 3}, 0, 0, 0, 0.13, -1, 225)
    RenderPillars(_image_pillar, repeat_dx, -pillar_y, 1, {-1, 3}, 0, 0, 0, 0.13, -2, 225)

    self:postRender()
end

return M