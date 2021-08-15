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

local RENDER_BUFFER_NAME = "rt:background"
CreateRenderTarget(RENDER_BUFFER_NAME)
local WARP_EFFECT_NAME = "fx:boss_distortion"
LoadFX(WARP_EFFECT_NAME, "shader/boss_distortion.fx")
SetShaderUniform("fx:boss_distortion", {
    centerX   = 100.0,
    centerY   = 100.0,
    size      = 50.0,
    arg       = 25.0,
    color     = Color(255, 163, 73, 164),
    colorsize = 80.0,
    timer     = 0.0,
})

---@param stage Stage the stage this background is created in
---@param coordinates_name string the coordinates to render textures in
---@param layer number specifies the order of render with respect to other render objects
function M.__create(stage, coordinates_name, layer)
    local self = Session.__create(stage)

    local Renderer = require("BHElib.ui.renderer_prefab")
    self.renderer = Renderer(layer, self, coordinates_name)
    self.render_buffer_name = RENDER_BUFFER_NAME
    self.render_buffer = FindResRenderTarget(RENDER_BUFFER_NAME)

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

function M:preRender()
    self.render_buffer:push()
end

---render the background
function M:render()
end

function M:postRender()
    self.render_buffer:pop()
    local x1, y1 = 0, 0
    local fxr = 163
    local fxg = 73
    local fxb = 164
    local aura_alpha = 1
    PostEffect(self.render_buffer, WARP_EFFECT_NAME, "mul+alpha", {
        centerX   = x1,
        centerY   = y1,
        size      = aura_alpha * 200,
        color     = Color(125, fxr, fxg, fxb),
        colorsize = aura_alpha * 200,
        arg       = 1500 * aura_alpha / 128,
        timer     = self.timer
    })
end

---------------------------------------------------------------------------------------------------
---deletion

function M:endSession()
    Session.endSession(self)
    Del(self.renderer)
end

return M