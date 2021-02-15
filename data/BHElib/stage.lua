---------------------------------------------------------------------------------------------------
---stage.lua
---author: Karl
---date: 2021.2.12
---references: -x/src/core/stage.lua, -x/src/core/corefunc.lua
---desc: Defines the Stage class.
---------------------------------------------------------------------------------------------------

---@class Stage
---@comment an instance of this class represents a shmup stage.
Stage = {
    init = function(self) end
}

---@comment an array of all stages created by Stage.new().
Stage.all_stages = {}

---metatable for Stage.new
Stage.mt = { __index = Stage }

---------------------------------------------------------------------------------------------------

---create and return a new stage object
---@param sid string a string that should be unique to each stage
---@param display_name string for displaying the name of the stage
---@param init function function called at the start of the stage
---@return Stage a stage object
function Stage.new(sid, display_name, init)
    local self = {}
    setmetatable(self, Stage.mt)

    self.sid = sid
    self.display_name = display_name
    self.init = init

    return self
end

---@return table an array of all stages created by Stage.new()
function Stage.getAll()
    return Stage.all_stages
end

---------------------------------------------------------------------------------------------------

---Initialize the stage each playthrough
function Stage.enter(self)
    self.timer = 0
    self:init()
end

function Stage.update(self, dt)
    self.timer = self.timer + dt
end