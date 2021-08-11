---------------------------------------------------------------------------------------------------
---scriptable_session.lua
---author: Karl
---date created: 2021.8.5
---desc: Defines a session that uses a script (coroutine) and may run other sessions or tasks as
---     its children
---------------------------------------------------------------------------------------------------

local Session = require("BHElib.sessions.session")

---@class ScriptableSession:Session
local M = LuaClass("ScriptableSession", Session)

---------------------------------------------------------------------------------------------------
---init

---@param stage Stage
---@param script function a coroutine function that takes self as first parameter
function M.__create(stage, script)
    assert(script and type(script) == "function", "Error: Incorrect parameter type for script!")

    local self = Session.__create(stage)

    self.task = {}
    ---@type Session
    self.session = nil  -- can hold one child session

    -- following coroutine is resumed whenever there are no more tasks and session to execute
    local function func()
        script(self)
    end
    self.coroutine = coroutine.create(func)

    return self
end

---run coroutine once at creation
function M:ctor()
    self:resumeCoroutine()
end

---------------------------------------------------------------------------------------------------
---update

---run every available tasks and session
---@return boolean true if anything is run in this function; false if nothing is run (in the case there are no children)
function M:updateChildren()
    local flag = false

    -- tasks
    if #self.task ~= 0 then
        task.Do(self)
        flag = true
    end

    -- session
    local session = self.session
    if session and not session.endSessionFlag then
        session:update(1)

        if not session.endSessionFlag then
            flag = true
        else
            self.session = nil
        end
    end

    return flag
end

function M:update(dt)
    Session.update(self, dt)

    local is_updated = false

    while not is_updated do
        is_updated = self:updateChildren()  -- run children

        if is_updated == false then
            -- resume the script to find something to update
            if coroutine.status(self.coroutine) == "dead" then
                self:endSession()
                is_updated = true
            else
                self:resumeCoroutine()
            end
        end
    end
end

---------------------------------------------------------------------------------------------------

---@param session Session the session to run
function M:setSession(session)
    self.session = session
end

---------------------------------------------------------------------------------------------------
---deletion

---end the session
function M:endSession()
    Session.endSession(self)
    local child_session = self.session
    if child_session and not child_session.endSessionFlag then
        child_session:endSession()
    end
end

---------------------------------------------------------------------------------------------------
---coroutine and coroutine functions

---resume the script
function M:resumeCoroutine()
    local success, errmsg = coroutine.resume(self.coroutine)
    if errmsg then
        error(errmsg)
    end
end

---@param session Session the session to run
function M:playSession(session)
    self:setSession(session)
    coroutine.yield()
end

---@param task_func function task function
function M:playTask(task_func)
    task.New(self, task_func)
    coroutine.yield()
end

return M