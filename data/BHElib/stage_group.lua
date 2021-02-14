---------------------------------------------------------------------------------------------------
---stage.lua
---author: Karl
---date: 2021.2.12
---references: -x/THlib/ext.lua
---desc: Defines the StageGroup class.
---------------------------------------------------------------------------------------------------

---@class StageGroup
---@comment an instance of this class represents a sequence of stages.
StageGroup = {}

---@comment an array of all stage groups created by StageGroup.new().
StageGroup.all_stage_groups = {}

---------------------------------------------------------------------------------------------------

---create and return a new stage group object
---@param gid string a string that should be unique to each stage group
---@param display_name string for displaying the name of the stage group
---@return StageGroup a stage group object
function StageGroup.new(gid, display_name, init_callback)
    local self = {}
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

---------------------------------------------------------------------------------------------------

---insert a stage to the stage array
---@param self StageGroup the stage group to insert to
---@param stage Stage the stage to insert
function StageGroup.appendStage(self, stage)
    table.insert(self.stage_array, stage)
end

---return a stage of specified index in the stage array
---@param self StageGroup the stage group to query on
---@param stage_index number index of the stage in the stage group
function StageGroup.getStageByIndex(self, stage_index)
    return self.stage_array[stage_index]
end

function StageGroup.startGame(self, game_init_params, first_stage)
    StageGroup.setNextStage(self, first_stage)
end

---@return Stage the currently running stage in the group
function StageGroup.getCurrentStage(self)
    return self.current_stage
end

function StageGroup.update(self, dt)
    if self.current_stage then
        Stage.update(self.current_stage, dt)
    end
end

function StageGroup.render(self)
    Render("test:image", 0, 0, 0, 1, 1, 0.5)
end

---set the next stage to switch to at the end of this frame; after this is set, readyForNextStage()
---will return true
function StageGroup.setNextStage(self, next_stage)
    self.next_stage = next_stage
end

---return whether the stage group is prepared to switch to the next stage
function StageGroup.readyForNextStage(self)
    return self.next_stage ~= nil
end

---set the next stage as the current stage, and start the stage;
---called by the game update function
function StageGroup.goToNextStage(self)

    -- make sure the next stage has been set
    assert(StageGroup.readyForNextStage(self), "Error: Next stage is not set!")

    local current_stage = self.current_stage
    local next_stage = self.next_stage

    if current_stage then
        current_stage:del()
        task.Clear(current_stage)

        --LPOOL.ResetPool 清空对象池
        ResetPool()
        SystemLog(i18n 'clear object pool')
    end

    --next_stage顶替current_stage
    self.current_stage = next_stage
    self.next_stage = nil

    Stage.start(next_stage)
end

---return true when the stage group is ready to be rendered
function StageGroup.readyForRender(self)
    local stage = self.current_stage
    return stage ~= nil and stage.timer > 1 and self.next_stage == nil
end