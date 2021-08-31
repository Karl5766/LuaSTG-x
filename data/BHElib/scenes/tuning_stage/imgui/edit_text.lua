---------------------------------------------------------------------------------------------------
---edit_text.lua
---date: 2021.8.29
---reference: src/xe/input/EditText.lua, src/xe/input/Code.lua
---desc: Defines a simpler version of the edit text xe has
---------------------------------------------------------------------------------------------------

local base = require('imgui.Widget')
---@class tuning_ui.EditText:im.Widget
local M = class('xe.iunput.EditText', base)
local im = imgui
local wi = require('imgui.Widget')
local PaletteIndex = im.ColorTextEdit.PaletteIndex

function M:ctor()
    base.ctor(self)

    local input = im.ColorTextEdit()
    input:setText("")
    input:setPaletteLight()
    input:setShowWhitespaces(false)
    input:setAutoTooltip(false)
    --
    --input:setPalette(require('xe.util').getCodeLightPalette())

    self._lang = "lua"
    local u = require('xe.util')
    local keywords = table.clone(u.getLuaKeywords())
    table.insert(keywords, 'self')
    input:setLanguageDefinition(
            'Lua', keywords, {}, {}, u.getLuaTokenRegex(), '--[[', ']]', '--')
    input:addLanguageIdentifier(require('xe.input.code_lua_doc'))

    self._input = input
    input:addTo(self)

    self._title = "Title"
end

---@param node im.Widget the node that handles the output string of this widget
function M:reset(node, title, init_str, code_font)
    self._title = title or "Default Edit Text Title"

    self.code_font = code_font
    self.node = node
    self._input:setText(init_str)
end

function M:setString(str)
    self._input:setText(str)
end

function M:getString()
    return self._input:getText()
end

function M:_handler()
    local input = self._input
    local cpos = input:getCursorPosition()

    local font_scale = 120
    if font_scale then
        im.setWindowFontScale(font_scale / 100)
    end

    local hh = -im.getTextLineHeightWithSpacing()
    im.pushFont(self.code_font)
    input:render(self._title, im.vec2(-1, hh), true)
    im.popFont()

    local dec = input:getHoveredDeclaration()
    local word = input:getHoveredWord()
    local idx = input:getHoveredWordIndex()
    if word ~= '' and dec ~= '' and idx == PaletteIndex.KnownIdentifier then
        im.setTooltip(('%s'):format(dec))
    end

    if font_scale then
        im.setWindowFontScale(1)
    end

    local pressed = im.button("cancel")
    if pressed then
        self:getParent():setVisible(false)
    end

    im.sameLine()

    im.text(('%6d/%6d %6d lines  | %s | %s'):format(
            cpos[1] + 1, cpos[2] + 1, input:getTotalLines(),
            input:isOverwrite() and 'Ovr' or 'Ins',
            "LUA"))

    im.sameLine()

    pressed = im.button("ok")
    if pressed then
        self.node:onEditCodeSave(input:getText())
        self:getParent():setVisible(false)
    end
end

return M
