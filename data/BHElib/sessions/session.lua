---------------------------------------------------------------------------------------------------
---author: Karl
---date created: 2021.6.1
---desc: a session is an object that can represent a time period that starts at some point and
---     eventually ends, in which a particular gameplay activity (boss fight, dialogue, etc.) takes
---     place
---------------------------------------------------------------------------------------------------
---A virtual class only for describing the basic interfaces of a session

---@class Session
local M = LuaClass("Session")

---------------------------------------------------------------------------------------------------

---@param stage Stage the stage that this session runs in
function M.__create(stage)
    local self = {
        ---@type boolean
        endSessionFlag = false,
        ---@type number
        timer = 0,
    }

    ---@type Stage
    self.stage = stage
    stage:addSession(self)

    return self
end

---------------------------------------------------------------------------------------------------

---@return Stage
function M:getStage()
    return self.stage
end

---@return boolean true if endSession() has not been called
function M:isContinuing()
    return not self.endSessionFlag
end

---@return boolean true if endSession() has been called
function M:isEnded()
    return self.endSessionFlag
end

---------------------------------------------------------------------------------------------------
---update

---@param dt number
function M:update(dt)
    assert(self.endSessionFlag == false, "Error: Attempt to update a session that has ended!")
    self.timer = self.timer + (dt or 1)
end

---------------------------------------------------------------------------------------------------
---deletion

---end the session if it is still going; must be called exactly once for proper deletion of the object
function M:endSession()
    assert(self.endSessionFlag == false, "Error: Attempt to call endSession() on a session twice!")
    self.endSessionFlag = true
    self.stage:removeSession(self)
end

return M