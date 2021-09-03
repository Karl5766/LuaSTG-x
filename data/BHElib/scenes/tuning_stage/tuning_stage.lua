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
    local save = self.scene_group.tuning_save
    if save then
        self.tuning_ui:loadSave(save)
    end

    return cocos_scene
end

---------------------------------------------------------------------------------------------------
---pause menu

function M:getTuningUI()
    return self.tuning_ui
end

---check if pause menu should be created
---only create it if no other pause menu is existing
---@return PauseMenu If a new pause menu is created, return the menu
function M:createUserPauseMenuIfNeeded()
    if Input:isAnyKeyJustChanged("recorded_pause_menu", true, true) and
            not self.is_paused then
        self.is_paused = true
        local TuningSession = require("BHElib.scenes.tuning_stage.tuning_session")
        self.pause_menu = TuningSession(self)
        self.is_in_user_pause_menu = true
    end
end

function M:updatePauseMenuStatus(dt)
    if self:isReplay() then
        -- immediately resume and simulate the output of pause menu by reading from replay
        local file_reader = self.replay_io_manager:getReplayFileReader():getFileReader()
        local file_writer = self.replay_io_manager:getReplayFileWriter():getFileWriter()

        if file_reader:readByte() == 1 then
            local tuning_ui = self.tuning_ui
            local save = tuning_ui.readSaveFromFile(file_reader)
            tuning_ui:loadSave(save)
            file_writer:writeByte(1)
            tuning_ui.writeSaveToFile(file_writer, save)  -- have to be write back to support real time replay mode switch
            self.is_paused = false
            self.is_in_user_pause_menu = false
            lstg.eventDispatcher:dispatchEvent("onTuningUIExit")
        else
            file_writer:writeByte(0)
            local Callbacks = require("BHElib.scenes.stage.stage_transition_callbacks")
            self.tuning_ui:callStageTransition(Callbacks.createMenuAndSaveReplay)
        end
    else
        Stage.updatePauseMenuStatus(self, dt)
        if not self.is_paused then
            self.is_in_user_pause_menu = false
            local tuning_ui = self.tuning_ui
            local save = tuning_ui:getSave()
            ---@type SequentialFileWriter
            local file_writer = self.replay_io_manager:getReplayFileWriter():getFileWriter()
            file_writer:writeByte(1)  -- without going to stage
            tuning_ui.writeSaveToFile(file_writer, save)
            lstg.eventDispatcher:dispatchEvent("onTuningUIExit")
        end
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
    --_hud_painter:drawHudBackground(
    --        "image:menu_hud_background",
    --        1.3)
end

---------------------------------------------------------------------------------------------------
---quick restart

function M:frameUpdate(dt)
    Stage.frameUpdate(self, dt)
    if self.timer >= 2
            and Input:isAnyKeyJustChanged("retry", true, true)
            and Input:isAnyRecordedKeyDown("recorded_ctrl") then
        self:transitionWithCallback(TransitionCallbacks.restartStageAndKeepRecording)
    end
end

---------------------------------------------------------------------------------------------------
---deletion

function M:endSession(continue_scene_group)
    self.scene_group.tuning_save = self.tuning_ui:getSave()
    self.tuning_ui:cleanup()
    Stage.endSession(self, continue_scene_group)
end

return M
