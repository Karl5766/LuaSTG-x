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
        self:completeSceneGroup()
    end)

    return scene
end

function SampleStage:getDisplayName()
    return "sample stage"
end

function SampleStage:cleanup()
    Stage.cleanup(self)
end

local _input = require("BHElib.input.input_and_recording")

local Bullet = Prefab.New(Prefab.Object)
Bullet.frame = task.Do
function Bullet:init(x, y, vx, vy, color)
    self.x = x
    self.y = y
    self.vx = vx
    self.vy = vy
    self.img = "img:ball_mid"..int(1)
    self.group = GROUP_ENEMY_BULLET
    self.resImg = FindResSprite(self.img)
    self.color = color
    --self.resImg:setColor(self.color)
end

Bullet.render = DefaultRenderFunc

function SampleStage:update(dt)
    Stage.update(self, dt)

    for i = 1, 9 do
        local a = ran:Float(0, 360)
        if self.timer < 3 then
            print(a)
        end
        New(Bullet, 0, 125, 4.5 * cos(a), 4.5 * sin(a), Color(255, ran:Int(0, 255), ran:Int(0, 255), 255))
    end
end

local _hud_painter = require("BHElib.ui.hud_painter")
function SampleStage:render()
    Stage.render(self)
    _hud_painter.drawKeys()
end


return SampleStage