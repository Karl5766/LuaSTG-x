---------------------------------------------------------------------------------------------------
---tuning_ui.lua
---reference: -x/src/xe/main.lua
---desc: Manages the ui of a tuning stage
---------------------------------------------------------------------------------------------------

---@class TuningUI
local M = LuaClass("TuningUI")

local TuningMatrix = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix")
local TuningManager = require("BHElib.scenes.tuning_stage.imgui.tuning_manager")
local EditText = require("BHElib.scenes.tuning_stage.imgui.edit_text")
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
    self.current_matrix_index = 1  -- uniquely assign ids to matrices
    return self
end

function M:ctor()
    local stage = self.stage
    local cocos_scene = stage.cocos_scene

    local la = im.on(cocos_scene)
    self.imgui_la = la

    la:addChild(function()
        -- modified from intellij idea theme color, looks a bit more comfortable
        im.pushStyleColor(im.Col.Text, im.vec4(255/255, 255/255, 255/255, 1.0))
        im.pushStyleColor(im.Col.Button, im.vec4(65/255, 66/255, 67/255, 1.0))
        im.pushStyleColor(im.Col.FrameBg, im.vec4(20/255, 0/255, 20/255, 1.0))
        im.pushStyleColor(im.Col.WindowBg, im.vec4(40/255, 41/255, 42/255, 1.0))
        im.pushStyleColor(im.Col.ButtonHovered, im.vec4(78/255, 82/255, 84/255, 1.0))
        im.pushStyleColor(im.Col.ButtonActive, im.vec4(51/255, 53/255, 55/255, 1.0))

        -- normally would need to be popped somewhere, but whatever
    end)

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

    local manager = TuningManager(self)
    self:registerChildWidget(manager, "Manager", im.WindowFlags.MenuBar)
    self.tuning_manager = manager
    local InitTuningManagerSaves = require("BHElib.scenes.tuning_stage.imgui.init_tuning_manager_saves")
    InitTuningManagerSaves.Default:writeBack(manager)  -- use default locals

    local edit_code = EditText()
    self.edit_code = edit_code
    local window = self:registerChildWidget(edit_code, "Output Control")
    window:setVisible(false)

    -- la:addChild(im.showDemoWindow)

    la:setVisible(false)
end

local _font_inited = false

function M:setupImguiFont()
    if _font_inited then
        return  -- stop repeated loading of font which will cause memory leak
    end
    _font_inited = true

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
    self.imgui_la:addChild(ImguiWidget.Widget(function()
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
---@return im.Window
function M:registerChildWidget(widget, window_label, flags)
    local window = WidgetWindow(window_label)
    window:addChild(widget)
    if flags then
        window:setFlags(flags)
    end
    self.imgui_la:addChild(window)
    return window
end

function M:getMatrices()
    return self.matrices
end

function M:getNumMatrices()
    return #self.matrices
end

---add a new matrix window
---@param save TuningMatrixSave if non-nil, load the matrix from this save
---@param title string if non-nil, use this as the prefix of the title
---@return im.TuningMatrix newly appended matrix
function M:appendMatrixWindow(save, title)
    local matrices = self.matrices
    local i = self.current_matrix_index
    self.current_matrix_index = i + 1

    local matrix = TuningMatrix(self, "", i)
    self:registerChildWidget(matrix, "", bit.bor(im.WindowFlags.MenuBar, im.WindowFlags.HorizontalScrollbar))
    matrix:setWindowTitle(title or "Matrix")
    if save then
        save:writeBack(matrix)
    end

    matrices[#matrices + 1] = matrix
    return matrix
end

---remove the most recent matrix window
function M:popMatrixWindow()
    self:removeMatrixWindowByIndex(#self.matrices)
end

---remove the most recent matrix window
function M:removeMatrixWindowByIndex(index)
    local matrices = self.matrices
    local matrix = matrices[index]

    -- update references
    for i = 1, #matrices do
        ---@type im.TuningMatrix
        local cur_matrix = matrices[i]
        cur_matrix:getIndicesArray():onRemoveMatrix(index)
    end

    table.remove(matrices, index)

    local edit_code = self.edit_code
    if edit_code:isVisible() and edit_code:getNode() == matrix then
        edit_code:off()
    end

    local window = matrix:getParent()
    window:removeFromParent()  -- remove window from la
end

---@param matrix im.TuningMatrix
function M:removeMatrixWindow(matrix)
    local matrices = self.matrices
    for i = 1, #matrices do
        if matrices[i] == matrix then
            self:removeMatrixWindowByIndex(i)
            return
        end
    end
    error("Error: Matrix to remove is not found!")
end

---------------------------------------------------------------------------------------------------
---interfaces

function M:on()
    if not self.is_cleaned then
        self.imgui_la:setVisible(true)
    end
end

function M:clearMatrices()
    while #self.matrices > 0 do
        self:popMatrixWindow()
    end
end

function M:off()
    if not self.is_cleaned then
        local edit_code = self.edit_code
        if edit_code:isActive() then
            edit_code:commitChanges()
        end
        self.imgui_la:setVisible(false)
    end
end

function M:callStageTransition(callback)
    local replay_io_manager = self.stage.scene_group:getReplayIOManager()
    local file_writer = replay_io_manager:getReplayFileWriter():getFileWriter()
    file_writer:writeByte(0)
    self.stage:transitionWithCallback(callback)
end

function M:createEditCode(node, init_str, title)
    local edit_code = self.edit_code
    edit_code:reset(node, title, init_str, self.font_mono)
    local window = edit_code:getParent()
    window:setVisible(true)
    window:setName(title)
end

function M:getEditCode()
    return self.edit_code
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
    self:clearMatrices()

    self:loadMatricesFromSave(save)
    self:loadManagerFromSave(save)
end

function M:loadMatricesFromSave(save)
    local matrix_saves = save.matrix_saves
    for i = 1, #matrix_saves do
        local matrix_save = matrix_saves[i]
        local matrix = self:appendMatrixWindow()
        matrix_save:writeBack(matrix)
        matrix:setWindowTitle(matrix.matrix_title)
    end
end

function M:loadManagerFromSave(save)
    save.manager_save:writeBack(self.tuning_manager)
end

---get callbacks from matrices that would create chains
function M:getChains(master, environment)
    local save = self:getSave()

    local code = save.manager_save:getLuaString()
    code = code.."\nreturn external_objects, {"
    local matrix_saves = save.matrix_saves
    for i = 1, #matrix_saves do
        local matrix_save = matrix_saves[i]
        local matrix_str = matrix_save:getLuaString()
        local matrix_code = [==[
            function(master)
                local n_row, n_col, matrix = ]==]..matrix_str.."\nend,"
        code = code..matrix_code
    end
    code = code.."}"

    SystemLog("Initializing chains...")
    SystemLog(code)

    local f, msg = load(code, nil, "t", environment)
    if msg then
        error(msg)
    end

    local external_objects, chain_functions = f()
    local matrices = self.matrices
    local num_matrices = #matrices  -- should equal to #chain_functions
    local references = {}
    for i = 1, num_matrices do
        references[i] = matrices[i]:getIndicesArray()
    end

    local ret = {}
    for i = 1, num_matrices do
        ret[i] = chain_functions[i](master)
    end
    for i = 1, num_matrices do
        ---@type TuningMatrixIndicesArray
        local indices = references[i]
        for j = 1, indices:getNumIndices() do
            if indices:isMatrix(j) then
                local index = indices:getMatrixIndex(j)
                local master_chain = ret[index]
                master_chain.output_column.s_chains = master_chain.output_column.s_chains or {}
                table.insert(master_chain.output_column.s_chains, ret[i])
            end
        end
    end

    return {external_objects, ret, references}
end

---------------------------------------------------------------------------------------------------
---file I/O

---save the object to file at the current file cursor position
---@param file_writer SequentialFileWriter the object for writing to file
function M.writeSaveToFile(file_writer, save)
    local matrix_saves = save.matrix_saves
    file_writer:writeUInt(#matrix_saves)
    for i = 1, #matrix_saves do
        ---@type TuningMatrixSave
        local matrix_save = matrix_saves[i]
        matrix_save:writeToFile(file_writer)
    end

    ---@type TuningManagerSave
    local manager_save = save.manager_save
    manager_save:writeToFile(file_writer)
end

---read the object from file at the current file cursor position
---@param file_reader SequentialFileReader the object for reading from file
function M.readSaveFromFile(file_reader)
    local matrix_saves = {}
    local num_matrices = file_reader:readUInt()
    for i = 1, num_matrices do
        local matrix_save = TuningMatrixSave(nil)
        matrix_save:readFromFile(file_reader)
        matrix_saves[i] = matrix_save
    end

    local manager_save = TuningManagerSave(nil)
    manager_save:readFromFile(file_reader)

    return {
        matrix_saves = matrix_saves,
        manager_save = manager_save,
    }
end

local FileStream = require("file_system.file_stream")
local SequentialFileReader = require("file_system.sequential_file_reader")
local SequentialFileWriter = require("file_system.sequential_file_writer")

---@param load_mode number pass nil or 0 for replace, 1 for load matrices, 2 for load manager
function M:loadBackup(file_path, load_mode)
    local stream = FileStream(file_path, "rb")
    local file_reader = SequentialFileReader(stream)
    local save = M.readSaveFromFile(file_reader)
    file_reader:close()
    if load_mode == 0 then
        self:loadSave(save)
    elseif load_mode == 1 then
        self:loadMatricesFromSave(save)
    elseif load_mode == 2 then
        self:loadManagerFromSave(save)
    else
        error("ERROR: Unrecognized load mode!")
    end
end

function M:saveBackup(file_path)
    local stream = FileStream(file_path, "wb")
    local file_writer = SequentialFileWriter(stream)
    local save = self:getSave()
    M.writeSaveToFile(file_writer, save)
    file_writer:close()
end

local FS = require("file_system.file_system")

function M:autoSaveBackup()
    local dir = self.tuning_manager.backup_dir.."auto/"
    if not FS.isFileExist(dir) then
        FS.createDirectory(dir)
    end
    local file_name = "Auto"..os.date("_%Y%m%d_%H%M%S.bak")
    self:saveBackup(dir..file_name)
end

---------------------------------------------------------------------------------------------------
---cleanup

function M:cleanup()
    self.is_cleaned = true
    im.off()
end

return M