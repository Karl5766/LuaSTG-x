---------------------------------------------------------------------------------------------------
---stage_group.lua
---date: 2021.2.12
---reference: -x/THlib/ext.lua
---desc: Defines the StageGroup class. At any given point, globally only one stage group can be
---running at a time, entry to another stage group will replace the currently running stage group
---with the new one.
---------------------------------------------------------------------------------------------------

---@class StageGroup
---@comment an instance of this class represents a sequence of stages.
StageGroup = {}

---@comment an array of all stage groups created by StageGroup.new().
StageGroup.all_stage_groups = {}

---current running stage group in the game
local _current_stage_group = nil

---metatable for StageGroup.new
StageGroup.mt = { __index = StageGroup }

---------------------------------------------------------------------------------------------------

---create and return a new stage group object
---@param gid string a string that should be unique to each stage group
---@param display_name string for displaying the name of the stage group
---@return StageGroup a stage group object
function StageGroup.new(gid, display_name, init_callback)
    local self = {}
    setmetatable(self, StageGroup.mt)

    self.gid = gid
    self.display_name = display_name
    self.init = init_callback or Stage.init

    self.stage_array = {}
    self.current_stage = nil
    self.next_stage = nil

    return self
end

---@return table an array of all stage groups created by
---StageGroup.new()
function StageGroup.getAll()
    return StageGroup.all_stage_groups
end

---@return StageGroup the currently running stage group in the game
function StageGroup.getRunningInstance()
    return _current_stage_group
end

---------------------------------------------------------------------------------------------------
---setters

---insert a stage to the stage array
---@param self StageGroup the stage group to insert to
---@param stage Stage the stage to insert
function StageGroup.appendStage(self, stage)
    table.insert(self.stage_array, stage)
end

---set the next stage to switch to at the end of this frame; after this is set, readyForNextStage()
---will return true
function StageGroup.setNextStage(self, next_stage)
    self.next_stage = next_stage
end

---------------------------------------------------------------------------------------------------
---getters

---return a stage of specified index in the stage array
---@param self StageGroup the stage group to query on
---@param stage_index number index of the stage in the stage group
function StageGroup.getStageByIndex(self, stage_index)
    return self.stage_array[stage_index]
end

---return the first stage in the stage array
function StageGroup.getFirstStage(self)
    return self.stage_array[1]
end

---@return Stage the currently running stage in the group
function StageGroup.getCurrentStage(self)
    return self.current_stage
end

---return whether the stage group is prepared to switch to the first/next stage
function StageGroup.readyForNextStage(self)
    return self.next_stage ~= nil
end

---return true when the stage group is ready to be rendered by the game render function
function StageGroup.readyForRender(self)
    local stage = self.current_stage
    return stage ~= nil and stage.timer > 1 and self.next_stage == nil
end

---------------------------------------------------------------------------------------------------
---instance methods

---set the stage group as the currently running stage group
---@param self StageGroup the stage group to set
---@param game_init_params table initial parameters for the playthrough
---@param first_stage Stage the entry stage of the stage group
function StageGroup.enter(self, game_init_params, first_stage)
    _current_stage_group = self
    StageGroup.setNextStage(self, first_stage)
end

function StageGroup.update(self, dt)
    if self.current_stage then
        Stage.update(self.current_stage, dt)
    end
end

function StageGroup.render(self)
    local coordinates = require("BHElib.coordinates_and_screen")
    coordinates.setRenderView("ui")
    Render("test:image", 30, 30, 0, 1, 1, 0.5)
end

---set the next stage as the current stage, and enter the stage;
---called by the game update function
function StageGroup.goToNextStage(self)

    -- make sure the next stage has been set
    assert(StageGroup.readyForNextStage(self), "Error: Next stage is not set!")

    local current_stage = self.current_stage
    local next_stage = self.next_stage

    if current_stage then
        current_stage:del()
        task.Clear(current_stage)

        ResetPool()
        SystemLog(i18n 'clear object pool')
    end

    -- next_stage顶替current_stage
    self.current_stage = next_stage
    self.next_stage = nil

    next_stage:enter()
end