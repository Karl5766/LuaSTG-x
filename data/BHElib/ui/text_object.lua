---------------------------------------------------------------------------------------------------
---text_object.lua
---author: Karl
---date: 2021.4.30
---desc: Defines an object that holds states about color and font info of some text, and can display
---     text according to the states
---------------------------------------------------------------------------------------------------

---@class ui.TextObject
local M = LuaClass("ui.TextObject")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local RenderTTF = RenderTTF
local unpack = unpack

---------------------------------------------------------------------------------------------------

---create a text object; the parameters can be nil, as long as they are provided later before the
---first time the text is rendered
---@param text string text string to display
---@param text_color lstg.Color color of the text
---@param font_name string name of the font to use
---@param font_size number size of the text to display
---@param font_align table an array of strings specifying optional formats, see resources.lua
function M.__create(text, text_color, font_name, font_size, font_align)
    local self = {}
    self.text = text
    self.text_color = text_color
    self.font_name = font_name
    self.font_size = font_size
    self.font_align = font_align
    return self
end

---------------------------------------------------------------------------------------------------

---@param text string text string to display
function M:setText(text)
    self.text = text
end

---@param text_color lstg.Color color of the text
function M:setColor(text_color)
    self.text_color = text_color
end

---@param font_name string name of the font to use
function M:setFontName(font_name)
    self.font_name = font_name
end

---@param font_size number size of the text to display
function M:setFontSize(font_size)
    self.font_size = font_size
end

---@param font_align table an array of strings specifying optional formats, see resources.lua
function M:setFontAlign(font_align)
    self.font_align = font_align
end

---@param x number position to render in x-coordinate
---@param y number position to render in y-coordinate
function M:render(x, y)
    RenderTTF(
            self.font_name,
            self.text,
            x, x,
            y, y,
            self.text_color,
            unpack(self.font_align)
    )
end

return M