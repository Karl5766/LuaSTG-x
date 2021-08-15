---------------------------------------------------------------------------------------------------
---scriptable_session.lua
---author: Karl
---date created: 2021.8.5
---desc: Defines a session that uses a script (coroutine) and may run other sessions or tasks as
---     its children; the session will start (resume) the script once immediately after creation
---------------------------------------------------------------------------------------------------

local ParentSession = require("BHElib.sessions.parent_session")

---@class ScriptableSession:ParentSession
local M = LuaClass("ScriptableSession", ParentSession)

---------------------------------------------------------------------------------------------------
---init

---@param parent ParentSession the parent session of this session
---@param script function a coroutine function that takes self as first parameter
function M.__create(parent, script)
    assert(script and type(script) == "function", "Error: Incorrect parameter type for script!")

    local self = ParentSession.__create(parent)

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
---coroutine

---resume the script
function M:resumeCoroutine()
    local success, errmsg = coroutine.resume(self.coroutine)
    if errmsg then
        error(errmsg)
    end
end

return M