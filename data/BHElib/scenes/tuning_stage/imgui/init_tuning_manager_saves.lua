local M = {}

local TuningManagerSave = require("BHElib.scenes.tuning_stage.imgui.tuning_manager_save")

local Default = TuningManagerSave()
Default:loadLocalArray({
    {"ParameterMatrix", "require(\"BHElib.scripts.linear_tuning.parameter_matrix\")"},
    {"BulletOutputColumn", "require(\"BHElib.scripts.units.output_columns.bullet_output_column\")"},
    {"DelayedAccBulletOutputColumn", "require(\"BHElib.scripts.units.output_columns.delayed_acc_bullet_output_column\")"},
    {"AccController", "require(\"BHElib.scripts.units.acc_controller\")"},
})
M.Default = Default

return M