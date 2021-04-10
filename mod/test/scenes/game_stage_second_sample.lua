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

    return scene
end

function SampleStage:getDisplayName()
    return "sample stage"
end

function SampleStage:cleanup()
    Stage.cleanup(self)
end

local _input = require("BHElib.input.input_and_replay")

local Bullet = Prefab.New(Prefab.Object)
Bullet.frame = task.Do
function Bullet:init(x, y, vx, vy, color)
    self.x = x
    self.y = y
    self.vx = vx
    self.vy = vy
    self.img = "img:ball_mid"..int(1)
    self.group = GROUP_INDES
    self.resImg = FindResSprite(self.img)
    self.color = color
    --self.resImg:setColor(self.color)
end

Bullet.render = DefaultRenderFunc

function SampleStage:update(dt)
    Stage.update(self, dt)

    if self.timer > 600.5 and self.timer < 601.5 then
        self:completeSceneGroup()
    end

    for i = 1, 4 do
        local a = ran:Float(0, 360)
        New(Bullet, 0, 0, 2 * cos(a), 2 * sin(a), Color(255, ran:Int(0, 255), ran:Int(0, 255), 255))
    end
end

local _hud_painter = require("BHElib.ui.hud_painter")
function SampleStage:render()
    Stage.render(self)
    _hud_painter.drawKeys()
end


return SampleStage