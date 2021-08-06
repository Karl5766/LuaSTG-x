---------------------------------------------------------------------------------------------------
---scriptable_session.lua
---author: Karl
---date created: 2021.8.5
---desc: Defines a session that uses a script (coroutine) and may run other sessions or tasks as
---     its children
---------------------------------------------------------------------------------------------------

---@class ScriptableSession:Session
local M = LuaClass("ScriptableSession")

---@param script function a coroutine function that takes self as first parameter
function M.__create(script)
    assert(script and type(script) == "function", "Error: Incorrect parameter type for script!")

    local self = {
        task = {},
        session = nil,  -- child session
        is_continuing = true,  -- set to false to end the boss fight
    }

    local function func()
        script(self)
    end
    -- this coroutine is resumed whenever there are no more tasks and session to execute
    self.coroutine = coroutine.create(func)

    return self
end

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
    if session then
        session:update(dt)
        if session:isContinuing() then
            flag = true
        else
            self.session = nil
        end
    end

    return flag
end

function M:update(dt)
    assert(self:isContinuing(), "Error: Attempt to update a session that has ended!")

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

---@return boolean true if the session has not ended
function M:isContinuing()
    return self.is_continuing
end

---end the session
function M:endSession()
    self.is_continuing = false
end

---resume the script
function M:resumeCoroutine()
    local success, errmsg = coroutine.resume(self.coroutine)
    if errmsg then
        error(errmsg)
    end
end

return M