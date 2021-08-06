---------------------------------------------------------------------------------------------------
---author: Karl
---date created: 2021.6.1
---desc: a session is an object that can represent a time period that starts at some point and
---     eventually ends, in which a particular gameplay activity (boss fight, dialogue, etc.) takes
---     place
---------------------------------------------------------------------------------------------------
---A virtual class only for describing the basic interfaces of a session

---@class Session
local M

---------------------------------------------------------------------------------------------------
---interface

---Session(...) -> Session object
---update() : frame update
---isContinuing() -> (boolean) whether the session is going or has reached an end
---endSession() : end the session if it is still going; must be called for proper deletion of the object

---------------------------------------------------------------------------------------------------