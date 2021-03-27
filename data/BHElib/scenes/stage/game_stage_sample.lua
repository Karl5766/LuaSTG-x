---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Karl2.
--- DateTime: 2021/3/4 17:08
---

local Stage = require("BHElib.scenes.stage.stage")

---@class SampleStage:Stage
local SampleStage = LuaClass("scenes.SampleStage", Stage)
Stage.registerStageClass(SampleStage)

---------------------------------------------------------------------------------------------------
---override/virtual

function SampleStage.__create(...)
    local self = Stage.__create(...)
    return self
end

function SampleStage:createScene()
    local scene = Stage.createScene(self)

    local canvas = require('imgui.Widget').ChildWindow('canvas')
    scene:addChild(canvas)

    local exit_button = ccui.Button:create(
            "creator/image/default_btn_normal.png",
            "creator/image/default_btn_pressed.png",
            "creator/image/default_btn_pressed.png", 0)
    exit_button:setScale9Enabled(true)
    exit_button:setContentSize(cc.size(340, 300))
    exit_button:setSwallowTouches(true)
    local param = ccui.LinearLayoutParameter:create()
    exit_button:setLayoutParameter(param)
    exit_button:setTitleFontName('Arial')
    exit_button:setTitleText("hello world")
    exit_button:setTitleColor(cc.c3b(255, 125, 125))
    exit_button:setTitleAlignment(cc.TEXT_ALIGNMENT_LEFT)
    exit_button:setTitleFontSize(180)
    local lb = exit_button:getTitleRenderer()
    lb:setAnchorPoint(cc.p(0, 0.5))
    lb:setPosition(cc.p(5, 0))
    exit_button:addTouchEventListener(function(self, arg)
        print(arg)
    end)
    exit_button:setName("button_exit2")
    exit_button:setPosition(cc.p(500, 200))

    --exit_button:setTouchEnabled(true)
    exit_button:setEnabled(true)
    exit_button:setBright(true)

    canvas:addChild(exit_button, 0)

    return scene
end

function SampleStage:getDisplayName()
    return "sample stage"
end

function SampleStage:getSid()
    return "sample_stage"
end

function SampleStage:cleanup()
    Stage.cleanup(self)
end

local _input = require("BHElib.input.input_and_replay")

local TestClass = MakePrefab(Object)
TestClass.frame = task.Do
function TestClass:init()
    local scr = require("BHElib.coordinates_and_screen")
    task.New(self, function()
        task.Wait(60)
        for i = 1, 10000000 do
            local w, h = 192 + 96 * sin(i), 224 + 112 * cos(i)
            scr.setPlayFieldBoundary(-w, w, -h, h)
            scr.setOutOfBoundDeletionBoundary(-w - 30, w + 30, -h - 30, h + 30)
            task.Wait(1)
        end
    end)
end
RegisterPrefab(TestClass)

local Bullet = MakePrefab(Object)
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
--function Bullet:render()
--    --self.resImg:setColor(self.color)
--    --Render(self.img, self.x, self.y, self.rot, self.hscale, self.vscale, 0.5)
--    --self.resImg:render(self.x, self.y, self.rot, self.hscale * factor, self.vscale * factor, 0.5)
--    DefaultRenderFunc(self)
--end
RegisterPrefab(Bullet)

function SampleStage:update(dt)
    Stage.update(self, dt)

    --if self.timer > 1.5 and self.timer < 2.5 then
    --    local obj = New(TestClass)
    --    obj.img = "image:test"
    --end

    if self.timer > 600.5 and self.timer < 601.5 then
        local Menu = require("BHElib.scenes.menu.menu_scene")
        local SceneTransition = require("BHElib.scenes.scene_transition")
        SceneTransition.transitionTo(self, Menu(), SceneTransition.instantTransition)
    end

    for i = 1, 2 do
        local a = ran:Float(0, 360)
        New(Bullet, 0, 0, 2 * cos(a), 2 * sin(a), Color(255, ran:Int(0, 255), ran:Int(0, 255), 255))
    end

    --if _input.isMouseButtonJustChanged(true, true) then
    --if _input.isAnyRecordedKeyDown("down") then
    --    for _=1, 9 do
    --        if ran:Float(0, 1) > 0 then
    --            local obj = New(Object)
    --            obj.img = "image:test"
    --            obj.vx = ran:Float(-4, 4)
    --            obj.vy = ran:Float(-4, 4)
    --        end
    --    end
    --end
end

local _hud_painter = require("BHElib.ui.hud_painter")
function SampleStage:render()
    Stage.render(self)
    _hud_painter.drawKeys()
end


return SampleStage