local M = {}

local TuningManagerSave = require("BHElib.scenes.tuning_stage.imgui.tuning_manager_save")
local CodeSnapshotBufferSave = require("BHElib.scenes.tuning_stage.imgui.code_snapshot_buffer_save")

local Default = TuningManagerSave()
Default:loadLocalArray({})
Default.context_control_save = CodeSnapshotBufferSave.shortInit(
        "data/BHElib/scenes/tuning_stage/default_code/context_control.lua")
M.Default = Default

return M