local base = require('imgui.Widget')
---@class tuning_ui.InputBase:im.Widget
local M = class('tuning_ui.InputBase', base)

---@param node xe.SceneNode
function M:ctor(node, type)
    base.ctor(self)
    assert(node and type)
    ---@type xe.SceneNode
    self._node = node
    self._type = type
end

function M:getValue()
    return self._value
end

function M:setValue(v)
    self._value = v
end

function M:getString()
    return M:getValue()
end

function M:getType()
    return self._type
end

return M
