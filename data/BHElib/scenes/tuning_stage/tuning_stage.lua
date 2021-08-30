---------------------------------------------------------------------------------------------------
---tuning_stage.lua
---author: Karl
---date created: 2021.8.29
---desc: A stage used for tuning parameters of a pattern
---------------------------------------------------------------------------------------------------

local Stage = require("BHElib.scenes.stage.stage")

---@class TuningStage:Stage
local M = class("scenes.TuningStage", Stage)

---------------------------------------------------------------------------------------------------

local Input = require("BHElib.input.input_and_recording")
local TransitionCallbacks = require("BHElib.scenes.stage.stage_transition_callbacks")
local TuningUI = require("BHElib.scenes.tuning_stage.tuning_ui")

---------------------------------------------------------------------------------------------------
---init

function M.__create(scene_init_state, scene_group)
    local self = Stage.__create(scene_init_state, scene_group)
    self.is_in_user_pause_menu = false
    return self
end

function M:createScene()
    local cocos_scene = Stage.createScene(self)

    self.tuning_ui = TuningUI(self)
    local info = self.scene_group.tuning_info
    if info then
        self.tuning_ui:loadInfo(info)
    end

    return cocos_scene
end

---------------------------------------------------------------------------------------------------
---pause menu

function M:getTuningUI()
    return self.tuning_ui
end

function M:createUserPauseMenu()
    self.is_paused = true
    local TuningSession = require("BHElib.scenes.tuning_stage.tuning_session")
    self.pause_menu = TuningSession(self)
    self.is_in_user_pause_menu = true

    return self.pause_menu
end

function M:updatePauseMenuStatus(dt)
    Stage.updatePauseMenuStatus(self, dt)
    if not self.is_paused then
        self.is_in_user_pause_menu = false
    end
end

function M:renderObjects()
    if self.is_in_user_pause_menu then
        self:renderUserPauseMenuBG()
    else
        Stage.renderObjects(self)  -- will call self:render()
    end
end

local _hud_painter = require("BHElib.ui.hud_painter")
function M:renderUserPauseMenuBG()
    _hud_painter:drawHudBackground(
            "image:menu_hud_background",
            1.3)
end

---------------------------------------------------------------------------------------------------
---quick restart

function M:frameUpdate(dt)
    Stage.frameUpdate(self, dt)
    if self.timer >= 2
            and Input:isAnyDeviceKeyJustChanged("retry", false, true)
            and Input:isAnyDeviceKeyDown("repfast") then
        self:transitionWithCallback(TransitionCallbacks.restartStageAndKeepRecording)
    end
end

---------------------------------------------------------------------------------------------------
---deletion

function M:endSession(continue_scene_group)
    self.scene_group.tuning_info = self.tuning_ui:getInfo()
    self.tuning_ui:cleanup()
    Stage.endSession(self, continue_scene_group)
end

return M
