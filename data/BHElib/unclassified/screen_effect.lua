---------------------------------------------------------------------------------------------------
---screen_effect.lua
---date: 2021.2.17
---desc: Defines functions for screen shot and screen texture capture; the update function of this
---     file needs to be called once per frame
---reference: -x/data/THlib/misc/misc.lua
---modifier:
---     Karl, 2021.2.17, split the file from corefunc.lua and named screen_capture.lua
---     2021.7.18, renamed to screen_effect.lua and added other functions
---------------------------------------------------------------------------------------------------

---@class ScreenEffect
local M = {}

local _screen = require("BHElib.unclassified.coordinates_and_screen")

---------------------------------------------------------------------------------------------------
---cache functions and variables

local Abs = math.abs

---------------------------------------------------------------------------------------------------

function Screenshot()
    local time = os.date("%Y-%m-%d-%H-%M-%S")
    local path = 'snapshot/' .. time .. '.png'
    lstg.Snapshot(path)
    SystemLog(string.format('%s %q', i18n('save screenshot to'), path))
end

local _capture = {}

---the captured screen will be set to the "img" field of the object by game update function;
---the function will not immediately capture the screen, but will let the game update function so at the end of the
---frame.
--- x,y,w,h are in "ui" coordinates
---@param obj Object
---@param x number x coordinate of left bottom corner
---@param y number y coordinate of left bottom corner
---@param w number width of the screen
---@param h number height of the screen
function CaptureScreen(obj, x, y, w, h)
    ---@type Coordinates
    local coordinates = require("BHElib.unclassified.coordinates_and_screen")
    local ui_origin_x, ui_origin_y = coordinates.getUIOriginInRes()
    local ui_scale_x, ui_scale_y = coordinates.getUIScale()

    x = x * ui_scale_x + ui_origin_x
    y = y * ui_scale_y + ui_origin_y
    w = w * ui_scale_x
    h = h * ui_scale_y

    table.insert(_capture, { obj, x, y, w, h })
end

---process captured screens by the CaptureScreen() function, if any
function ProcessCapturedScreens()
    if #_capture > 0 then
        ---@type cc.RenderTexture
        local fb = CopyFrameBuffer()
        local sp = fb:getSprite()
        local sz = sp:getTextureRect()
        local hh = sz.height
        for _, v in ipairs(_capture) do
            local obj, x, y, w, h = unpack(v)
            local newsp = cc.Sprite:createWithTexture(
                    sp:getTexture(), cc.rect(x, hh - y - h, w, h), false)
            local r = lstg.ResSprite:createWithSprite(
                    string.format('::CAP:: %s', tostring(obj)), newsp, 0, 0, 0)
            obj.img = r
        end
        _capture = {}
    end
end

local _playfield_display_offset_x = 0
local _playfield_display_offset_y = 0

---@param task_host any hosts the task; careful if host is destroyed mid-shake display will be glitched
---@param shake_magnitude number shake magnitude in game(/ui) distance
---@param shake_time number shake time in frames
---@param single_displace_time number the time lasts for a single displacement of the playfield
function M:shakePlayfield(task_host, shake_magnitude, shake_time, single_displace_time)
    task.New(task_host, function()
        for i = 1, shake_time do
            local angle = math.ceil(i / single_displace_time) * 144
            self:addPlayfieldDisplayOffset(
                    shake_magnitude * cos(angle),
                    shake_magnitude * sin(angle))
            coroutine.yield()
        end
    end)
end

---offset the display of playfield in the current frame
---@param dx number offset in x axis
---@param dy number offset in y axis
function M:addPlayfieldDisplayOffset(dx, dy)
    _playfield_display_offset_x = _playfield_display_offset_x + dx
    _playfield_display_offset_y = _playfield_display_offset_y + dy
end

---------------------------------------------------------------------------------------------------
---apis for coordinates_and_screen.lua

---@return number, number the offset of the display of playfield in the current frame
function M:getPlayfieldDisplayOffset()
    return _playfield_display_offset_x, _playfield_display_offset_y
end

---------------------------------------------------------------------------------------------------
---update

function M:update(dt)
    -- reset the displacement
    _playfield_display_offset_x = 0
    _playfield_display_offset_y = 0
end

return M