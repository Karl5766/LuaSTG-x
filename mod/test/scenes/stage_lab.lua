-- created some time around 2021.5

local Stage = require("BHElib.scenes.stage.stage")

---@class StageLab:Stage
local SampleStage = LuaClass("stage.StageLab", Stage)
local Prefab = require("BHElib.prefab")
local SequentialFileWriter = require("util.sequential_file_writer")
local SequentialFileReader = require("util.sequential_file_reader")
local FileStream = require("util.file_stream")

local GameScene = require("BHElib.scenes.game_scene")
local GameSceneInitState = require("BHElib.scenes.stage.state_of_scene_init")
local SceneGroup = require("BHElib.scenes.stage.scene_group")
local Ustorage = require("util.universal_id")

local _input = require("BHElib.input.input_and_recording")
local BulletPrefabs = require("BHElib.units.enemy_bullet.bullet_prefabs")
local BulletTypes = require("BHElib.units.enemy_bullet.bullet_types")

require("se")

---------------------------------------------------------------------------------------------------
---BG

local BBG = Prefab.NewX(Prefab.Object, "background.black")

function BBG:init(ix, iy, scale)
    self.img = "image:white"
    self.layer = LAYER_BG
    self.group = GROUP_GHOST
    self.hscale = scale
    self.vscale = scale
    self.color = Color(255, 0, 0, 0)
    self.x = ix
    self.y = iy
end

Prefab.Register(BBG)

local WBG = Prefab.NewX(Prefab.Object, "background.white")

function WBG:init(ix, iy, scale)
    self.img = "image:white"
    self.layer = LAYER_TOP
    self.group = GROUP_GHOST
    self.hscale = scale
    self.vscale = scale
    self.color = Color(255, 255, 255, 255)
    self.x = ix
    self.y = iy

    task.New(self, function()
        for i = 1, 60 do
            local c = 255 * (60 - i) / 60
            self.color = Color(c, 255, 255, 255)
            task.Wait(1)
        end
        Del(self)
    end)
end

WBG.frame = task.Do

Prefab.Register(WBG)

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
    self.exit_button = {}
    --for j = 1, 12 do
    --    for i = 1, 30 do
    --        local exit_button = require("BHElib.input.recording_cc_button")(
    --                "creator/image/default_btn_normal.png",
    --                "creator/image/default_btn_pressed.png",
    --                "creator/image/default_btn_disabled.png", 0)
    --        exit_button:setPositionInUI(200 + i * 30, 200 + j * 50)
    --        exit_button:setUseRecordingInput(true)
    --        canvas:addChild(exit_button, 0)
    --        table.insert(self.exit_button, exit_button)
    --    end
    --end

    task.New(self, function()
        PlaySound("don00", 1)
        WBG(0, 0, 10)
        BBG(0, 0, 10)
        local BossFight = require("enemy.nue_boss_fight")
        local boss_fight = BossFight()
        while boss_fight:continueBossFight() do
            boss_fight:update(1)
            task.Wait(1)
        end
        local callbacks = require("BHElib.scenes.stage.stage_transition_callbacks")
        self:transitionWithCallback(callbacks.restartStageAndKeepRecording)
    end)

    return scene
end

function SampleStage:getDisplayName()
    return "sample stage"
end

function SampleStage:update(dt)
    for i, button in ipairs(self.exit_button) do
        button:update(1)
    end

    Stage.update(self, dt)
end

local _hud_painter = require("BHElib.ui.hud_painter")
function SampleStage:render()
    Stage.render(self)
    do
        local color = Color(255, 255, 255, 255)
        local x, y = 620, 440
        RenderTTF("font:menu", "Time", x, x, y, y, color, "center")
        x, y = 660, 440
        RenderTTF("font:menu", tostring(math.floor(self.timer / 60)), x, x, y, y, color, "left")
    end
    _hud_painter.drawPerfromanceProfile("font:hud_default")
    _hud_painter.drawKeys()
end

return SampleStage