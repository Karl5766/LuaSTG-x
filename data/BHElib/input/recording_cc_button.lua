---------------------------------------------------------------------------------------------------
---RecordingCCButton.lua
---author: Karl
---date: 2021.4.29
---reference: src/cc/ui/ButtonToggle.lua
---desc: Defines a button that receives recorded or device input
---------------------------------------------------------------------------------------------------

---@class RecordingCCButton
local M = class("input.RecordingCCButton")

local Input = require("BHElib.input.input_and_recording")

---------------------------------------------------------------------------------------------------

function M.__create(...)
    local self = ccui.Button:create(...)

    return self
end

function M:ctor()
    self:setScale9Enabled(true)
    self:setContentSize(cc.size(10, 10))
    self:setSwallowTouches(true)

    local param = ccui.LinearLayoutParameter:create()
    self:setLayoutParameter(param)

    -- text title
    --self:setTitleFontName('Arial')
    --self:setTitleText("hw")
    --self:setTitleColor(cc.c3b(255, 125, 125))
    --self:setTitleAlignment(cc.TEXT_ALIGNMENT_LEFT)
    --self:setTitleFontSize(180)
    --local lb = self:getTitleRenderer()
    --lb:setAnchorPoint(cc.p(0, 0.5))
    --lb:setPosition(cc.p(5, 0))

    self:setName("button")
    self:setPosition(cc.p(500, 200))

    self:setTouchEnabled(false)
    self:setEnabled(true)
    self:setBright(true)

    self.user_input = Input
    self.is_recording = false
    self.is_pressed = false
end

---set the button to use or not use recording input (opposed to device input)
function M:setUseRecordingInput(is_recording)
    self.is_recording = is_recording
end

local _director = cc.Director:getInstance()
---process user input
---@param dt number time elapsed since previous update
function M:update(dt)
    local input = self.user_input

    -- compute mouse-related information
    local x, y
    if self.is_recording then
        x, y = input:getRecordedMousePosition()
    else
        x, y = input:getMousePosition()
    end
    local cam = _director:getRunningScene():getDefaultCamera()
    local is_colliding = self:hitTest(cc.p(x, y), cam)
    local just_changed = input:isMouseButtonJustChanged(self.is_recording)
    local pressed
    if self.is_recording then
        pressed = input:isRecordedMousePressed()
    else
        pressed = input:isMousePressed()
    end

    if self.is_pressed then
        ---mouse may release, move or stay
        if just_changed and not pressed then  -- mouse is released
            self.is_pressed = false
            if is_colliding then  -- released over the button
                self:onTouchEnded(x, y)
            else  -- released outside the button
                self:onTouchCanceled()
            end
        end
        local dx, dy = input:getMousePositionChange(self.is_recording)
        if dx == 0 and dy == 0 then
            -- mouse not moving, do nothing
        else
            self:onTouchMoved(x, y)
        end
    elseif is_colliding then
        if just_changed and pressed then
            self.is_pressed = true
            self:onTouchBegan(x, y)
        else
            self:onHover(x, y)
        end
    end
end

function M:onHover(x, y)
end

function M:onTouchBegan(x, y)
    self:setBrightStyle(ccui.BrightStyle.highlight)
end

function M:onTouchMoved(x, y)
end

function M:onTouchEnded(x, y)
    self:setBrightStyle(ccui.BrightStyle.normal)
end

function M:onTouchCanceled(x, y)
    self:setBrightStyle(ccui.BrightStyle.normal)
end

return M
