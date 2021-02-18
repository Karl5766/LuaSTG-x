---------------------------------------------------------------------------------------------------
---screen_capture.lua
---date: 2021.2.17
---desc: Defines functions for screen shot and screen texture capture
---modifier:
---     Karl, 2021.2.17, split the file from corefunc.lua
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
    local coordinates = require("BHElib.coordinates_and_screen")
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