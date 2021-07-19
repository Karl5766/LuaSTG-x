local Stage = require("BHElib.scenes.stage.stage")

---@class SampleStage:Stage
local SampleStage = LuaClass("stage.SecondSampleStage", Stage)
local Prefab = require("BHElib.prefab")

---------------------------------------------------------------------------------------------------
---override/virtual

function SampleStage.__create(...)
    local self = Stage.__create(...)
    return self
end

function SampleStage:createScene()
    local scene = Stage.createScene(self)

    task.New(self, function()
        task.Wait(600)
        self:transitionWithCallback(Stage.BACK_TO_MENU)
    end)

    return scene
end

function SampleStage:getDisplayName()
    return "sample stage"
end

local _input = require("BHElib.input.input_and_recording")
local BulletPrefabs = require("BHElib.units.bullet.bullet_prefab")
local BulletTypes = require("BHElib.units.bullet.bullet_types")

function SampleStage:update(dt)
    Stage.update(self, dt)

    for i = 1, 9 do
        local a = ran:Float(0, 360)
        local bullet_type_name = "grain"
        local bullet_info = BulletTypes.bullet_type_to_info[bullet_type_name]
        local b = BulletPrefabs.Base("ball", COLOR_BLUE, GROUP_ENEMY_BULLET, 11, bullet_info.size)
        b.x = 0
        b.y = 120
        b.vx = 4 * cos(a)
        b.vy = 4 * sin(a)
        b.rot = a
    end
end

local _hud_painter = require("BHElib.ui.hud_painter")
function SampleStage:render()
    Stage.render(self)
    _hud_painter.drawKeys()
end


return SampleStage