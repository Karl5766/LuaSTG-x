---------------------------------------------------------------------------------------------------
---parent_session.lua
---author: Karl
---date created: 2021.8.14
---desc: Defines a session that can hold child tasks and child sessions, and update them when the
---     parent session itself is updated
---------------------------------------------------------------------------------------------------

local Session = require("BHElib.sessions.session")

---@class ParentSession:Session
local M = LuaClass("ParentSession", Session)

---------------------------------------------------------------------------------------------------
---init

---@param parent ParentSession the parent session of this session
function M.__create(parent)
    local self = Session.__create(parent)

    ---a table in which keys are Session objects, and values are boolean true;
    ---these sessions are children of the parent session object
    ---@type table
    self.sessions = {}
    self.task = {}

    return self
end

---------------------------------------------------------------------------------------------------

---@param session Session the session to run
function M:addSession(session)
    local sessions = self.sessions
    assert(sessions[session] == nil, "Error: The session to add to parent session already exists as a child session!")
    sessions[session] = true
end

---remove a child session
---@param session Session
function M:removeSession(session)
    local sessions = self.sessions
    assert(sessions[session], "Error: The session to be removed does not exist")
    sessions[session] = nil
end

---@return table a table with all children sessions as its keys
function M:getSessions()
    return self.sessions
end

---------------------------------------------------------------------------------------------------
---update

---run every available tasks and session
---@return boolean true if anything is run in this function; false if nothing is run (in the case there are no children)
function M:updateChildren(dt)
    local flag = false

    -- tasks
    if #self.task ~= 0 then
        task.Do(self)
        flag = true
    end

    -- sessions
    local to_be_del = {}
    for session, _ in pairs(self.sessions) do
        if session and not session.sessionHasEnded then
            session:update(dt)

            if not session.sessionHasEnded then
                flag = true
            else
                to_be_del[#to_be_del + 1] = session
            end
        end
    end
    M.deleteSessionsInArray(to_be_del)

    return flag
end

---update children of this session
function M:update(dt)
    Session.update(self, dt)

    self:updateChildren(dt)  -- run children
end

---------------------------------------------------------------------------------------------------
---deletion

---end the session
function M:endSession()
    Session.endSession(self)

    self:deleteAllChildrenSessions()
end

function M:deleteAllChildrenSessions()
    ---important to implement the sessions so that:
    ---order of deletion doesn't matter (even though some sessions are others' child sessions)
    local session_array = {}
    for session, _ in pairs(self.sessions) do
        session_array[#session_array + 1] = session
    end
    M.deleteSessionsInArray(session_array)
end

---delete all sessions in the given array;
---can handle cases when a session deletes another session in the array
---@param session_array table an array of sessions
function M.deleteSessionsInArray(session_array)
    for i = 1, #session_array do
        local session = session_array[i]
        if session:isContinuing() then
            session:endSession()
        end
    end
end

return M