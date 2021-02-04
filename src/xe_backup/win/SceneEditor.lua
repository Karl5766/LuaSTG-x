local base = require('imgui.widgets.Window')
---@class xe.SceneEditor:im.Window
local M = class('xe.SceneEditor', base)
local im = imgui
local wi = require('imgui.Widget')

function M:ctor()
    base.ctor(self, 'Scene Editor')
    self:addChild(function()
        if im.isWindowFocused(im.FocusedFlags.ChildWindows) then
            self:_handleKeyboard()
        end
    end)

    self._toolbar = require('xe.tools.ToolBar')()
    self:addChild(self._toolbar)

    self._toolpanel = require('xe.tools.ToolPanel')()
    self:addChild(self._toolpanel)
    self._toolpanel:disableAll()

    local win = wi.ChildWindow('xe.scene.tree', im.vec2(-1, -1), true)
    self:addChild(win)
    self._treewin = win

    -- replace default navigation in tree
    win:addChild(function()
        self:_handleNav()
        if im.isWindowFocused(im.FocusedFlags.ChildWindows) then
            self:_handleTreeKeyboard()
        end
    end)

    local setting = setting.xe
    local style = wi.style(nil, {
        [im.StyleVar.FramePadding] = function()
            local v = setting.editor_tree_padding or 0
            return im.vec2(v, v)
        end
    })
    style:addTo(win)

    self._tree = require('xe.SceneTree')()
    self._tree:addTo(style)

    self._game = require('xe.win.GameView')()
    self._game:addTo(self):setVisible(false)
    --[[
    local N = 256
    local sz = 16
    local n = math.floor(N / sz)
    local rt = cc.RenderTexture:create(N, N)
    rt:begin()
    local info = {}
    local files = cc.FileUtils:getInstance():listFiles('res/xe/node_small')
    local ii = 0
    for i, v in ipairs(files) do
        if v:ends_with('.png') then
            ii = ii + 1
            local sp = cc.Sprite(v)
            rt:addChild(sp)

            local xx = sz / 2 + (ii - 1) % n * sz
            local yy = N - sz / 2 - math.floor((ii - 1) / n) * sz
            sp:setPosition(xx, yy)
            sp:visit()

            local t = { (ii - 1) % n * sz, math.floor((ii - 1) / n) * sz, sz, sz }
            info[v:filename()] = t
        end
    end
    rt:endToLua()
    rt:setVisible(false):addTo(self)
    local ii = 0
    self:addChild(function()
        im.image(rt:getSprite())
        ii = ii + 1
        if ii == 2 then
            rt:saveToFile('node_small.png')
            local str = json.encode(info)
            cc.FileUtils:getInstance():writeStringToFile(str, 'node_small.json')
        end
    end)
    --]]
    --[[
    cc.Image:setPNGPremultipliedAlphaEnabled(false)
    local img = cc.Image()
    img:initWithImageFile('xe/node.png')

    assert(not img:hasPremultipliedAlpha())

    local fu = cc.FileUtils:getInstance()
    local path = fu:fullPathForFilename('res/xe/node')
    assert(path ~= '')
    img:saveToFile(('%s/%s.png'):format(path, 'node'))

    local tex = cc.Texture2D()
    tex:initWithImage(img)
    assert(not tex:hasPremultipliedAlpha())
    tex:newImage():saveToFile(('%s/%s.png'):format(path, 'node2'))

    --local t = json.decode(fu:getStringFromFile('xe/node.json'))
    --for k, v in pairs(t) do
    --    local sp = cc.Sprite:createWithTexture(tex, cc.rect(unpack(v)))
    --    assert(sp:getTexture():getPixelFormat() == 2)
    --    local rect = sp:getTextureRect()
    --    assert(rect.width > 0 and rect.height > 0)
    --
    --    local i = sp:newImage()
    --    assert(i)
    --    i:saveToFile(('%s/%s.png'):format(path, k))
    --end
    --]]

    --[[
    self._treewin:setVisible(false)
    local plt = implot
    local xs = {}
    for i = 0, 100 do
        table.insert(xs, i / 100)
    end
    local yss = {}
    for k, v in pairs(math.tween) do
        local ys = {}
        for _, x in ipairs(xs) do
            table.insert(ys, v(x))
        end
        table.insert(yss, { k, ys })
    end
    table.sort(yss, function(a, b)
        return a[1] < b[1]
    end)
    self:addChild(function()
        if plt.beginPlot('title', 'x', 'y', im.vec2(-1, -1)) then
            for i, v in ipairs(yss) do
                plt.plotLine(v[1], xs, v[2], #xs)
            end
            plt.endPlot()
        end
    end)
    --]]
    --require('util.mbg.__init__')
end

---@return xe.SceneTree
function M:getTree()
    return self._tree
end

function M:setEditor()
    self._toolbar:setVisible(true)
    self._toolpanel:setVisible(true)
    self._treewin:setVisible(true)
    self._game:setVisible(false)
end

function M:setGame()
    self._toolbar:setVisible(false)
    self._toolpanel:setVisible(false)
    self._treewin:setVisible(false)
    self._game:setVisible(true)
end

local kbNav, gpNav
local kbNavFlag = im.ConfigFlags.NavEnableKeyboard
local gpNavFlag = im.ConfigFlags.NavEnableGamepad
local disabled
function M:_handleNav()
    if im.isWindowFocused() then
        if not disabled then
            kbNav = im.configFlagCheck(kbNavFlag)
            gpNav = im.configFlagCheck(gpNavFlag)
            disabled = true
        end
        im.configFlagDisable(kbNavFlag, gpNavFlag)
    else
        disabled = false
        if kbNav then
            im.configFlagEnable(kbNavFlag)
        end
        if gpNav then
            im.configFlagEnable(gpNavFlag)
        end
    end
end

function M:_handleKeyboard()
    -- only handle node operations
    if self._treewin:isVisible() then
        -- editor
        local tool = require('xe.ToolMgr')
        local t = {
            { 'ctrl', 'c', tool.copy },
            { 'ctrl', 'x', tool.cut },
            { 'ctrl', 'v', tool.paste },
            { 'delete', nil, tool.delete },
        }
        for _, v in ipairs(t) do
            if im.checkKeyboard(v[1], v[2]) then
                v[3]()
                break
            end
        end
    end
end

function M:_handleTreeKeyboard()
    if self._treewin:isVisible() then
        -- tree navigation
        local tree = self._tree
        local cur = tree:getCurrent()
        if not cur then
            return
        end
        local skip = { 'ctrl', 'alt', 'shift' }
        for _, v in ipairs(skip) do
            if im.checkKeyboard(v) then
                return
            end
        end

        if im.checkKeyboard('up') then
            local prev = cur:getBrotherPrev()
            if prev then
                prev = prev:getLastVisibleChild()
            end
            if not prev then
                prev = cur:getParentNode()
            end
            if prev then
                prev:select()
            end
        elseif im.checkKeyboard('down') then
            local next
            if not cur:isFold() and cur:getChildrenCount() > 0 then
                next = cur:getChildAt(1)
            end
            if not next then
                next = cur:getBrotherNext()
            end
            if not next then
                local p = cur:getParentNode()
                local idx = cur:getIndex()
                while p do
                    if p:getChildrenCount() > idx then
                        next = p:getChildAt(idx + 1)
                    else
                        idx = p:getIndex()
                    end
                    if next then
                        break
                    end
                    p = p:getParentNode()
                end
            end
            if next then
                next:select()
            end
        elseif im.checkKeyboard('left') then
            if cur:getChildrenCount() > 0 then
                cur:fold()
            end
        elseif im.checkKeyboard('right') then
            if cur:getChildrenCount() > 0 then
                cur:unfold()
            end
        end
    end
end

M.KeyEvent = {
    { 'ctrl', 'n', 'new' },
    { 'ctrl', 'o', 'open' },
    { 'ctrl', 's', 'save' },
    { 'ctrl', 'w', 'close' },
    { 'f7', nil, 'build' },
    { 'f6', nil, 'debugStage' },
    { 'shift', 'f6', 'debugSC' },
    { 'f5', nil, 'run' },

    { 'alt', 'up', 'moveUp' },
    { 'alt', 'down', 'moveDown' },
    { 'ctrl', 'up', 'insertBefore' },
    { 'ctrl', 'down', 'insertAfter' },
    { 'ctrl', 'right', 'insertChild' },
}

return M
