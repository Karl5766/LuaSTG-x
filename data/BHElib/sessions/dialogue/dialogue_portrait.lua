---------------------------------------------------------------------------------------------------
---dialogue_portrait.lua
---author: Karl
---date created: 2021.7.23
---desc: Defines the portrait objects of the dialogue
---------------------------------------------------------------------------------------------------

---@class DialoguePortrait
local M = LuaClass("DialoguePortrait")

---------------------------------------------------------------------------------------------------
---cache functions and variables

local Vec2 = math.Vec2

---------------------------------------------------------------------------------------------------

---@param image string
---@param high_color lstg.Color
---@param high_pos math.vec2
---@param low_color lstg.Color
---@param low_pos math.vec2
---@param is_highlighted boolean
function M.__create(image, high_color, high_pos, low_color, low_pos, is_highlighted)
    local self = {}
    self.image = image
    self.high_color = high_color
    self.high_pos = high_pos
    self.low_color = low_color
    self.low_pos = low_pos
    self.hscale = 1
    self.vscale = 1

    self.is_highlighted = is_highlighted
    return self
end

function M:ctor()
    self:setHighlight(self.is_highlighted)
    self.pos = self.target_pos
end

function M:setHighlight(highlight)
    self.is_highlighted = highlight
    if highlight then
        self.color = self.high_color
        self.target_pos = self.high_pos
    else
        self.color = self.low_color
        self.target_pos = self.low_pos
    end
end

function M:update(dt)
    self.pos = self.pos + (self.target_pos - self.pos) * 0.1
end

function M:render()
    local pos = self.pos
    SetImageState(self.image, "", self.color)
    Render(self.image, pos.x, pos.y, 0, self.hscale, self.vscale)
end

return M