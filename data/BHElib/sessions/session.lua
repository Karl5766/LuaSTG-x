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
---init

---@param parent ParentSession the parent session of this session
function M.__create(parent)
    local self = {
        ---@type boolean
        sessionHasEnded = false,
        ---@type number
        timer = 0,
        ---@type ParentSession
        parent = parent,
    }

    ---@type GameScene
    self.game_scene = assert(parent:getGameScene(), "Error: Game scene does not exist for class "..parent[".classname"].."!")
    parent:addSession(self)

    return self
end

---------------------------------------------------------------------------------------------------

---@return Stage
function M:getGameScene()
    return self.game_scene
end

---@return boolean true if endSession() has not been called
function M:isContinuing()
    return not self.sessionHasEnded
end

---@return boolean true if endSession() has been called
function M:isEnded()
    return self.sessionHasEnded
end

---------------------------------------------------------------------------------------------------
---update

---@param dt number
function M:update(dt)
    assert(self.sessionHasEnded == false, "Error: Attempt to update a session that has ended!")
    self.timer = self.timer + (dt or 1)
end

---------------------------------------------------------------------------------------------------
---deletion

---end the session if it is still going; must be called exactly once for proper deletion of the object
function M:endSession()
    assert(self.sessionHasEnded == false, "Error: Attempt to call endSession() on a session twice!")
    self.sessionHasEnded = true
    self.parent:removeSession(self)
end

return M