---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Karl2.
--- DateTime: 2021/3/4 17:08
---

local Stage = require("BHElib.scenes.stage.stage")

---@class SampleStage:Stage
local SampleStage = LuaClass("stage.SampleStage", Stage)
local Prefab = require("core.prefab")
local Button = require("BHElib.input.recording_cc_button")

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

    --local exit_button = ccui.Button:create(
    --        "creator/image/default_btn_normal.png",
    --        "creator/image/default_btn_pressed.png",
    --        "creator/image/default_btn_disabled.png", 0)
    --exit_button:setScale9Enabled(true)
    --exit_button:setContentSize(cc.size(340, 300))
    --exit_button:setSwallowTouches(true)
    --local param = ccui.LinearLayoutParameter:create()
    --exit_button:setLayoutParameter(param)
    --
    ---- text title
    ----exit_button:setTitleFontName('Arial')
    ----exit_button:setTitleText("hw")
    ----exit_button:setTitleColor(cc.c3b(255, 125, 125))
    ----exit_button:setTitleAlignment(cc.TEXT_ALIGNMENT_LEFT)
    ----exit_button:setTitleFontSize(180)
    ----local lb = exit_button:getTitleRenderer()
    ----lb:setAnchorPoint(cc.p(0, 0.5))
    ----lb:setPosition(cc.p(5, 0))
    --
    --exit_button:addTouchEventListener(function(self, arg)
    --    if arg == 3 then
    --        self:setEnabled(not self:isEnabled())
    --    end
    --end)
    --exit_button:setName("button_exit2")
    --exit_button:setPosition(cc.p(500, 200))
    --
    ----exit_button:setTouchEnabled(true)
    --exit_button:setEnabled(true)
    --exit_button:setBright(true)
    --self.exit_button = exit_button
    --canvas:addChild(exit_button, 0)

    self.exit_button = {}
    for j = 1, 12 do
        for i = 1, 100 do
            local exit_button = require("BHElib.input.recording_cc_button")(
                    "creator/image/default_btn_normal.png",
                    "creator/image/default_btn_pressed.png",
                    "creator/image/default_btn_disabled.png", 0)
            exit_button:setPosition(cc.p(200 + i * 6, 200 + j * 10))
            exit_button:setUseRecordingInput(true)
            canvas:addChild(exit_button, 0)
            table.insert(self.exit_button, exit_button)
        end
    end


    task.New(self, function()
        task.Wait(600)
        self:goToNextScene()
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

    for i = 1, 7 do
        local a = ran:Float(0, 360)
        local bullet_type_name = "grain"
        local bullet_info = BulletTypes.bullet_type_to_info[bullet_type_name]
        local b = BulletPrefabs.Base("grain", COLOR_BLUE, GROUP_ENEMY_BULLET, 11, bullet_info.size)
        b.x = 0
        b.y = 120
        b.vx = 4 * cos(a)
        b.vy = 4 * sin(a)
        b.rot = a
    end

    for i, button in ipairs(self.exit_button) do
        button:update(1)
    end
end

local _hud_painter = require("BHElib.ui.hud_painter")
function SampleStage:render()
    Stage.render(self)
    _hud_painter:drawKeys()
end


return SampleStage