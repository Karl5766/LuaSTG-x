---------------------------------------------------------------------------------------------------
---tuning_session.lua
---author: Karl
---date: 2021.8.29
---desc: tuning session is for tuning parameters of patterns
---------------------------------------------------------------------------------------------------

local ParentSession = require("BHElib.sessions.parent_session")

---@class TuningSession:ParentSession
local M = LuaClass("TuningSession", ParentSession)

---------------------------------------------------------------------------------------------------

local Input = require("BHElib.input.input_and_recording")

---------------------------------------------------------------------------------------------------
---init

---@param stage TuningStage the stage with imgui objects initialized
function M.__create(stage)
    local self = ParentSession.__create(stage)

    local tuning_ui = stage:getTuningUI()
    if not stage:isReplay() then
        tuning_ui:on()
    end
    self.tuning_ui = tuning_ui

    return self
end

---------------------------------------------------------------------------------------------------
---update

function M:update(dt)
    ParentSession.update(self, dt)
    if Input:isAnyKeyJustChanged("escape", false, true) then
        self:endSession()
    end
end

---------------------------------------------------------------------------------------------------
---deletion

function M:endSession()
    self.tuning_ui:off()
    ParentSession.endSession(self)
end

return M