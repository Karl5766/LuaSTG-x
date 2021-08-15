---------------------------------------------------------------------------------------------------
---background_prefab.lua
---date created: 2021.8.13
---reference: THlib/background/backgournd.lua
---desc: Defines basic background base, the prefab for background objects
---modifiers:
---     Karl, 2021.8.13, moved the code from THlib and split the file background.lua to two parts,
---     this is the part with the definition of the background object class
---     2021.8.14, rewrite the background to be a session class instead of a lstg game class
---------------------------------------------------------------------------------------------------

local Session = require("BHElib.sessions.session")

---@class BackgroundSession:Session 背景类基类
local M = LuaClass("BackgroundSession", Session)

---------------------------------------------------------------------------------------------------
---init

---@param stage Stage the stage this background is created in
---@param coordinates_name string the coordinates to render textures in
---@param layer number specifies the order of render with respect to other render objects
function M.__create(stage, coordinates_name, layer)
    local self = Session.__create(stage)

    local Renderer = require("BHElib.ui.renderer_prefab")
    self.renderer = Renderer(layer, self, coordinates_name)

    return self
end

---------------------------------------------------------------------------------------------------
---getter

---@return Prefab.Renderer the renderer that calls the render of the session's function each frame
function M:getRenderer()
    return self.renderer
end

---@return string the name of the coordinates to render in
function M:getCoordinatesName()
    return self.renderer.coordinates_name
end

---------------------------------------------------------------------------------------------------
---update

---render the background
function M:render()
end

---------------------------------------------------------------------------------------------------
---deletion

function M:endSession()
    Session.endSession(self)
    Del(self.renderer)
end

return M