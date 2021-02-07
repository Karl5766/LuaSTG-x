-----------------------------------------------------------------------
---launcher_scene.lua
---defines the scene graph etc. for mod launcher scene.
---Karl.
---DateTime: 2021/2/5 21:19
-----------------------------------------------------------------------

---@class cc.Scene
local _launcher_scene = cc.Scene:create()
local button = require("cc.ui.button")

---Initializes the launcher scene object
function _launcher_scene.initScene()
    _launcher_scene:setName("launcher scene")

    -- set up the canvas
    local canvas = require('imgui.Widget').ChildWindow('canvas')
    _launcher_scene:addChild(canvas)

    local cc_size =  cc.Director:getInstance():getVisibleSize();
    local layer = cc.Layer:create()
    local layer_color = cc.LayerColor:create(cc.c4b(0, 0, 255, 255), 300, 300)
    canvas:addChild(layer, 0)

    local exit_button = button.BaseButton(
            nil, -- default size 75
            function()
                print("hello world!")
            end
    )
    exit_button:setName("button_exit")
    canvas:addChild(exit_button, 0)

    _launcher_scene.update = function(self, dt)
        --for i, v in pairs(scene_tasks) do
        --    v()
        --end
    end

    layer:setVisible(true)
    exit_button:setVisible(true)
    _launcher_scene:setVisible(true)

    local lc = require("cc.children_helper").getChildrenWithName(_launcher_scene)
    local lc_size = 0
    for name, node in pairs(lc) do
        print("node name "..name)
        lc_size = lc_size + 1
    end
    print("size of lc: "..lc_size)
end

return _launcher_scene