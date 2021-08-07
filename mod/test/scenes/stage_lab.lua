-- created some time around 2021.5

local Stage = require("BHElib.scenes.stage.stage")

---@class StageLab:Stage
local M = LuaClass("stage.StageLab", Stage)
local Prefab = require("core.prefab")

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

function M.__create(...)
    local self = Stage.__create(...)
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

    --local node = cc.DrawNode:create()
    --node:drawSolidRect(cc.p(-50, -50), cc.p(50, 50), {a = 1, r = 1, g = 1, b = 1})
    --canvas:addChild(node, 0)
    --self.rect = node

    task.New(self, function()
        PlaySound("don00", 1)
        WBG(0, 0, 10)
        BBG(0, 0, 10)
        local Nue = require("enemy.nue_boss_fight")

        local boss_fight = Nue(self)
        self.boss_fight = boss_fight
        while boss_fight:isContinuing() do
            boss_fight:update(1)
            task.Wait(1)
        end
        local callbacks = require("BHElib.scenes.stage.stage_transition_callbacks")
        self:transitionWithCallback(callbacks.restartStageAndKeepRecording)
    end)

    return scene
end

function M:getDisplayName()
    return "sample stage"
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

local function IsIntersected()  end

function M:update(dt)
    for i, button in ipairs(self.exit_button) do
        button:update(1)
    end

    self:fetchEnemyTargets()

    Stage.update(self, dt)
end

local _hud_painter = require("BHElib.ui.hud_painter")
function M:render()
    Stage.render(self)
    do
        local x, y = 720, 160
        RenderText("font:test",
                string.format("Time:%d/200", tostring(math.floor(self.timer / 60))),
                x, y, 0.4, "right")

        local session = self.boss_fight.session
        if session ~= nil then
            local boss = session.hitbox
            if IsValid(boss) then
                RenderText("font:test", "Boss hp:"..tostring(int(boss.hp)), 720, 130, 0.4, "right")
            end
        end
    end
    --_hud_painter:drawPerfromanceProfile("font:menu")
    _hud_painter:drawKeys()
end

return M