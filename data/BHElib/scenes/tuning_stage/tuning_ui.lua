---------------------------------------------------------------------------------------------------
---tuning_ui.lua
---reference: -x/src/xe/main.lua
---desc: Manages the ui of a tuning stage
---------------------------------------------------------------------------------------------------

---@class TuningUI
local M = LuaClass("TuningUI")

local TuningMatrix = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix")
local TuningManager = require("BHElib.scenes.tuning_stage.imgui.tuning_manager")
local WidgetWindow = require('imgui.widgets.Window')

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

    self.matrices = {}
    self:appendMatrixWindow()

    local manager = TuningManager(self)
    self:registerChildWidget(manager, "Manager")
    self.tuning_manager = manager

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
---matrix windows

---create a window for the imgui widget child
function M:registerChildWidget(widget, window_label)
    local window = WidgetWindow(window_label)
    window:addChild(widget)
    self.imgui_la:addChild(window)
end

function M:getNumMatrices()
    return #self.matrices
end

---add a new matrix window
---@return im.TuningMatrix newly appended matrix
function M:appendMatrixWindow()
    local matrices = self.matrices
    local i = #matrices + 1

    local matrix = TuningMatrix()
    self:registerChildWidget(matrix, "Matrix"..i)

    matrices[i] = matrix
    return matrix
end

---remove the most recent matrix window
function M:popMatrixWindow()
    local matrices = self.matrices
    local matrix = matrices[#matrices]
    matrices[#matrices] = nil
    local window = matrix:getParent()
    window:removeFromParent()  -- remove window from la
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
        lstg.eventDispatcher:dispatchEvent("onTuningUIExit")
        self.imgui_la:setVisible(false)
    end
end

local TuningMatrixSave = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix_save")
local TuningManagerSave = require("BHElib.scenes.tuning_stage.imgui.tuning_manager_save")

function M:getSave()
    local matrix_saves = {}
    for i = 1, #self.matrices do
        local matrix = self.matrices[i]
        matrix_saves[i] = TuningMatrixSave(matrix)
    end

    local manager_save = TuningManagerSave(self.tuning_manager)

    return {
        matrix_saves = matrix_saves,
        manager_save = manager_save,
    }
end

function M:loadSave(save)
    local matrix_saves = save.matrix_saves
    for i = 1, #matrix_saves do
        local matrix_save = matrix_saves[i]
        local matrix = self:appendMatrixWindow()
        matrix_save:writeBack(matrix)
    end

    save.manager_save:writeBack(self.tuning_manager)
end

---get callbacks from matrices that would create chains
function M:getChainCallbacks()
    local save = self:getSave()

    local code = save.manager_save:getLuaString()
    code = code.."return {"
    local matrix_saves = save.matrix_saves
    for i = 1, #matrix_saves do
        local matrix_save = matrix_saves[i]
        local matrix_str = matrix_save:getLuaString()
        local matrix_code = [==[
            function(master)
                local n_row, n_col, matrix = ]==]..matrix_str..[==[

                local ParameterMatrix = require("BHElib.scripts.linear_tuning.parameter_matrix")
                local BulletOutputColumn = require("BHElib.scripts.units.bullet_output_column")
                local AccController = require("BHElib.scripts.units.acc_controller")

                local col = BulletOutputColumn(master)
                col.x = 0
                col.y = 0
                col.angle = -90
                col.bullet_type_name = "ball"
                col.color_index = COLOR_BLUE
                col.controller = 1 --AccController.shortInit(3, 30, 1)
                col.blink_time = 12
                col.inc_rot = 3
                col.effect_size = 1
                col.destroyable = true

                return ParameterMatrix.MatrixInit(master, n_row, n_col, matrix, col)
            end,
        ]==]
        code = code..matrix_code
    end
    code = code.."}"

    SystemLog(code)

    local f, msg = loadstring(code)
    if msg then
        error(msg)
    end

    return f()
end

---------------------------------------------------------------------------------------------------
---cleanup

function M:cleanup()
    self.is_cleaned = true
    im.off()
end

return M