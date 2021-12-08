-- created some time around 2021.5

local Stage = require("BHElib.scenes.tuning_stage.tuning_stage")

---@class StageLab:TuningStage
local M = LuaClass("stage.StageLab", Stage)
local Prefab = require("core.prefab")

require("se")

---------------------------------------------------------------------------------------------------
---BG

local WBG = Prefab.NewX(Prefab.Object, "background.white")

function WBG:init(ix, iy, scale, time)
    self.img = "image:white"
    self.layer = LAYER_TOP
    self.group = GROUP_GHOST
    self.hscale = scale
    self.vscale = scale
    self.color = Color(255, 255, 255, 255)
    self.x = ix
    self.y = iy

    task.New(self, function()
        for i = 1, time do
            local c = 255 * (time - i) / time
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

function M.__create(...)
    local self = Stage.__create(...)
    self.targets = {}
    return self
end

---@param player Prefab.Player the player that is collecting the items
function M:borderCollectAllItems(player)
    for i, object in ObjList(GROUP_ITEM) do
        if IsValid(object) and object.onBorderCollect then
            object:onBorderCollect(player)
        end
    end
end

function M:createScene()
    local scene = Stage.createScene(self)

    local canvas = require('imgui.Widget').ChildWindow('canvas')
    scene:addChild(canvas)
    self.canvas = canvas

    task.New(self, function()
        PlaySound("se:don00", 0.5, 0, true)

        local NightPassage = require("backgrounds.night_passage.night_passage")
        NightPassage(self)

        WBG(0, 0, 10, 30)
        local Nue = require("enemy.nue_boss_fight")

        while true do
            local boss_fight = Nue(self)
            self.boss_fight = boss_fight
            while boss_fight:isContinuing() do
                task.Wait(1)
            end
        end
        --local callbacks = require("BHElib.scenes.stage.stage_transition_callbacks")
        --self:transitionWithCallback(callbacks.restartStageAndKeepRecording)
    end)

    self.player:getPlayerResource().num_power = 400

    return scene
end

local FindTarget = require("BHElib.scripts.target").findTargetByAngleWithVerticalLine
local ObjList = ObjList

function M:fetchEnemyTargets()
    -- maintain a list of collidable enemies in the player object
    local collidable_enemies = {}
    for i, object in ObjList(GROUP_ENEMY) do
        if IsValid(object) and object.colli then
            collidable_enemies[#collidable_enemies + 1] = object
        end
    end
    -- object may have colli set to false after in the same frame, but no need to be too precise here
    self.targets = collidable_enemies
end

---@return Prefab.Object
function M:getEnemyTargetFrom(source)
    return FindTarget(source, self.targets)
end

function M:update(dt)
    self:fetchEnemyTargets()

    Stage.update(self, dt)
end

local _hud_painter = require("BHElib.ui.hud_painter")
local Input = require("BHElib.input.input_and_recording")

function M:render()
    Stage.render(self)
    if Input:isAnyDeviceKeyDown("retry") then
        _hud_painter:drawPerformanceProfile("font:menu")
    end
    -- _hud_painter:drawKeys()
end

return M