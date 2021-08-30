---------------------------------------------------------------------------------------------------
---tuning_ui.lua
---reference: -x/src/xe/main.lua
---desc: Manages the ui of a tuning stage
---------------------------------------------------------------------------------------------------

---@class TuningUI
local M = LuaClass("TuningUI")

---------------------------------------------------------------------------------------------------

local im = imgui

---------------------------------------------------------------------------------------------------
---init

local ImguiWidget = require('imgui.Widget')
---@type xe.main

local window_flags = bit.bor(
        --im.WindowFlags.MenuBar,
        im.WindowFlags.NoDocking,
        im.WindowFlags.NoTitleBar,
        im.WindowFlags.NoCollapse,
        im.WindowFlags.NoResize,
        im.WindowFlags.NoMove,
        im.WindowFlags.NoBringToFrontOnFocus,
        im.WindowFlags.NoNavFocus,
        im.WindowFlags.NoBackground)

---@param stage TuningStage
function M.__create(stage)
    local self = {}
    self.stage = stage
    self.is_cleaned = false
    return self
end

function M:ctor()
    local stage = self.stage
    local cocos_scene = stage.cocos_scene

    local la = im.on(cocos_scene)
    self.imgui_la = la

    cc.Director:getInstance():setDisplayStats(false)

    im.show()
    im.clear()

    self:setupImguiFont(stage)

    local dock = ImguiWidget.wrapper(function()
        local viewport = im.getMainViewport()
        im.setNextWindowPos(viewport.Pos)
        im.setNextWindowSize(viewport.Size)
        im.setNextWindowViewport(viewport.ID)
        im.pushStyleVar(im.StyleVar.WindowRounding, 0)
        im.pushStyleVar(im.StyleVar.WindowBorderSize, 0)
        im.pushStyleVar(im.StyleVar.WindowPadding, im.p(0, 0))
        im.begin('Dock Space', nil, window_flags)
        im.popStyleVar(3)
        im.dockSpace(im.getID('xe.dock_space'), im.p(0, 0), im.DockNodeFlags.PassthruCentralNode)
    end, function()
        im.endToLua()
    end)
    dock:addTo(la)

    --self.console = require('imgui.ui.Console').createWindow('Console##xe')
    --la:addChild(self.console)
    --la:addChild(function()
    --    local ret = im.button('1')
    --    if ret then
    --        Print("button 1 is pressed")
    --    end
    --    im.separator()
    --    im.sameLine()
    --    ret = im.button('2')
    --    if ret then
    --        Print("button 2 is pressed")
    --    end
    --end)

    local TuningMatrix = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix")

    local window = require('imgui.widgets.Window')("Matrix1##TuningUI")
    local matrix = TuningMatrix()
    matrix:resizeTo(9, 4)
    window:addChild(matrix)
    la:addChild(window)
    self.tuning_matrix = matrix

    -- la:addChild(im.showDemoWindow)

    la:setVisible(false)
end

function M:setupImguiFont()
    local la = self.imgui_la

    local cfg = im.ImFontConfig()
    cfg.OversampleH = 2
    cfg.OversampleV = 2
    local font_default = im.addFontTTF('font/WenQuanYiMicroHeiMono.ttf', 14, cfg, {
        --0x0080, 0x00FF, -- Basic Latin + Latin Supplement
        0x2000, 0x206F, -- General Punctuation
        0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
        0x31F0, 0x31FF, -- Katakana Phonetic Extensions
        0xFF00, 0xFFEF, -- Half-width characters
        0x4e00, 0x9FAF, -- CJK Ideograms
        0,
    })
    cfg = im.ImFontConfig()
    cfg.OversampleH = 3
    cfg.OversampleV = 3
    cfg.MergeMode = true
    im.addFontTTF('font/NotoSansDisplay-Regular.ttf', 18, cfg, im.GlyphRanges.Default)
    --
    local fa = require('xe.ifont')
    cfg = im.ImFontConfig()
    cfg.OversampleH = 2
    cfg.OversampleV = 2
    cfg.MergeMode = true
    cfg.GlyphMinAdvanceX = 12
    cfg.GlyphMaxAdvanceX = 12
    im.addFontTTF('font/' .. fa.FontIconFileName, 14, cfg, {
        fa.IconMin, fa.IconMax, 0
    })
    --
    cfg = im.ImFontConfig()
    cfg.OversampleH = 2
    cfg.OversampleV = 2
    cfg.MergeMode = false
    local font_mono = im.addFontTTF('font/JetBrainsMono-Regular.ttf', 14, cfg, {
        0x0020, 0x00FF, -- Basic Latin + Latin Supplement
        0x2000, 0x206F, -- General Punctuation
        0
    })

    local built
    la:addChild(ImguiWidget.Widget(function()
        if built then
            return
        end
        built = im.getIO().Fonts:isBuilt()
        if built then
            -- reuse CJK glyphs
            font_mono:mergeGlyphs(font_default, 0x3000, 0x30FF)
            font_mono:mergeGlyphs(font_default, 0x31F0, 0x31FF)
            font_mono:mergeGlyphs(font_default, 0xFF00, 0xFFEF)
            font_mono:mergeGlyphs(font_default, 0x4e00, 0x9FAF)
        end
    end))

    self.imgui_font_default = font_default
    self.imgui_font_mono = font_mono
end

---------------------------------------------------------------------------------------------------
---menu bar

function M.menuBar()
    local tool = require('xe.ToolMgr')
    local opened = require('xe.Project').getFile() and true or false
    local data = require('xe.menu.data')
    for _, v in ipairs(data) do
        if v.title and im.beginMenu(v.title) then
            for _, item in ipairs(v.content) do
                local f = tool[item.event or '']
                local enabled = opened or not item.need_proj
                if im.menuItem(i18n(item.title), item.shortcut, false, enabled) and f then
                    f()
                end
            end
            im.endMenu()
        end
    end
    if require('cocos.framework.device').isMobile then
        local pos = im.getIO().MousePos
        if M._kbCode then
            im.text(('Key(%d)'):format(M._kbCode))
        end
        local dl = im.getForegroundDrawList()
        dl:addCircle(pos, 10, 0xff0000ff)
    end
end

---------------------------------------------------------------------------------------------------
---interfaces

function M:on()
    if not self.is_cleaned then
        self.imgui_la:setVisible(true)
    end
end

function M:off()
    if not self.is_cleaned then
        self.imgui_la:setVisible(false)
    end
end

function M:getInfo()
    return {
        matrix = self.tuning_matrix:saveToTable()
    }
end

function M:loadInfo(info)
    self.tuning_matrix:loadFromTable(info.matrix)
end

function M:getMatrixOutput()
    local str = self.tuning_matrix:getMatrixStringRepr()
    local num_row, num_col, matrix = loadstring("return "..str)()
    return num_row, num_col, matrix
end

---------------------------------------------------------------------------------------------------
---cleanup

function M:cleanup()
    self.is_cleaned = true
    im.off()
end

return M