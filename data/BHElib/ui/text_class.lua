--------------------------------------------------------------------------------------------------
---text_object.lua
---author: Karl
---date: 2021.4.30
---desc: Defines an object that holds states about color and font info of some text, and can display
---     text according to the states
---------------------------------------------------------------------------------------------------

---@class ui.TextClass
local M = LuaClass("ui.TextClass")

---------------------------------------------------------------------------------------------------
---cache variables and functions

local RenderText = RenderText
local unpack = unpack

---------------------------------------------------------------------------------------------------

---create a text object; the parameters can be nil, as long as they are provided later before the
---first time the text is rendered
---@param text string text string to display
---@param text_color lstg.Color color of the text
---@param font_name string name of the font to use
---@param font_size number size of the text to display
---@param ... table an array of strings specifying optional formats, see resources.lua
function M.__create(text, text_color, font_name, font_size, ...)
    local self = {}
    self.text = text
    self.render_mode = "mul+alpha"  -- uncommon to have other render modes, therefore default to "mul+alpha"
    self.text_color = text_color
    self.font_name = font_name
    self.font = FindResFont(font_name)
    self.font_size = font_size

    self.font_align = {...}

    return self
end

---------------------------------------------------------------------------------------------------

---@param text string text string to display
function M:setText(text)
    self.text = text
end

---@param render_mode string specifies a render mode of lstg E.g. "mul+alpha"
function M:setFontRenderMode(render_mode)
    self.render_mode = render_mode
end

---@param text_color lstg.Color color of the text
function M:setFontColor(text_color)
    self.text_color = text_color
end

---@param font_name string name of the font to use
function M:setFontName(font_name)
    self.font_name = font_name
    self.font = FindResFont(font_size)
end

---@param font_size number size of the text to display
function M:setFontSize(font_size)
    self.font_size = font_size
end

---@param ... string an array of strings specifying optional formats, see resources.lua
function M:setFontAlign(...)
    self.font_align = {...}
end

---@param x number position to render in x-coordinate
---@param y number position to render in y-coordinate
function M:render(x, y)
    ---TODO:add font size feature

    local font = self.font
    local color = self.text_color
    local blend_mode = self.render_mode
    if blend_mode then
        font:setRenderMode(blend_mode)
    end
    if color then
        font:setColor(color)
    end
    RenderText(self.font_name,
        self.text,
        x,
        y,
        self.font_size,
        unpack(self.font_align))
end

return M