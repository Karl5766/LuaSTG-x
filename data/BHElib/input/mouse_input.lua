---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Karl2.
--- DateTime: 2021/3/4 0:03
---

local MouseState = {}
local MouseStatePre = {}

---MouseIsDown
---@param button number
---@return boolean
function MouseIsDown(button)
    return MouseState[button]
end

---MouseIsPressed
---@param button number
---@return boolean
function MouseIsPressed(button)
    return MouseState[button] and (not MouseStatePre[button])
end

---MouseIsReleased
---@param button number
---@return boolean
function MouseIsReleased(button)
    return MouseStatePre[button] and (not MouseState[button])
end

---@return number,number
function MousePosition()
    return MouseState[4], MouseState[5]
end

---@return number,number
function MousePositionPre()
    return MouseStatePre[4], MouseStatePre[5]
end

local _GetMousePosition = lstg.GetMousePosition
local glv = cc.Director:getInstance():getOpenGLView()

---@~chinese 获取鼠标的screen坐标系位置，以窗口左下角为原点。
---
---@~english Get mouse position in screen coordinates starts from the bottom left of the window.
---
---@return number,number
function GetMousePosition()
    local res = glv:getDesignResolutionSize()
    local rect = glv:getViewPortRect()
    local x, y = _GetMousePosition()
    y = res.height - y
    x = x + rect.x / glv:getScaleX()
    y = y + rect.y / glv:getScaleY()
    local ui_scale_x, ui_scale_y = require("BHElib.coordinates_and_screen").getUIScale()
    x = x / ui_scale_x
    y = y / ui_scale_y
    return x, y
end

lstg.eventDispatcher:addListener('onGetInput', function()
    for i = 1, 5 do
        MouseStatePre[i] = MouseState[i]
    end
    for i = 1, 3 do
        MouseState[i] = GetMouseState(i)
    end
    MouseState[4], MouseState[5] = GetMousePosition()
end, 1, 'mouse')