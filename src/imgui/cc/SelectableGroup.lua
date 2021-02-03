local base = require('imgui.Widget')

---@class im.cc.SelectableGroup:im.Widget
local M = class('im.cc.SelectableGroup', base)
local im = imgui

function M:ctor(nodes, current, flags, sizes)
    assert(#nodes > 0)
    local n = cc.Node()
    for i, v in ipairs(nodes) do
        n:addChild(v)
    end
    n:setVisible(false)
    self:addChild(n)
    ---@type cc.Node[]
    self._nodes = nodes
    self._cur = current
    self._flags = {}
    if flags then
        if type(flags) == 'number' then
            local t = {}
            for _ = 1, #labels do
                table.insert(t, flags)
            end
            self._flags = t
        else
            self._flags = flags
        end
    end
    self._sizes = {}
    if sizes then
        if #sizes == 0 then
            local t = {}
            for _ = 1, #labels do
                table.insert(t, sizes)
            end
            self._flags = t
        else
            self._flags = sizes
        end
    end
    self:setLabelAutoColor(true)
end

function M:setOnSelect(f)
    self._onsel = f
    return self
end

function M:setLabelAutoColor(b)
    self._lac = b
end

function M:_handler()
    local w = im.getWindowWidth() - im.getStyle().WindowPadding.x * 2
    local dl = im.getWindowDrawList()
    for i = 1, #self._nodes do
        local node = self._nodes[i]
        local nsz = node:getContentSize()
        local pos = im.getCursorScreenPos()
        local sz = self._sizes[i]
        if not sz then
            sz = im.vec2(0, nsz.height)
        end
        if sz.y == 0 then
            sz.y = nsz.height
        end
        local ww, hh = sz.x, sz.y
        if ww == 0 then
            ww = w
        end
        local xx = pos.x + (ww - nsz.width) / 2
        local yy = pos.y + (hh - nsz.height) / 2
        local param = { '', i == self._cur, self._flags[i] or 0, sz }
        im.pushID(tostring(self) .. i)
        if im.selectable(unpack(param)) then
            self._cur = i
            if self._onsel then
                self:_onsel(i)
            end
            self._ret = { i }
        end
        im.popID()

        if self._lac then
            im.setCCLabelColor(node)
        end
        dl:addCCNode(node, im.vec2(xx, yy))
    end
    base._handler(self)
end

return M
