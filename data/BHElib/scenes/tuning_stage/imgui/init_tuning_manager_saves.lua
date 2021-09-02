local M = {}

local TuningManagerSave = require("BHElib.scenes.tuning_stage.imgui.tuning_manager_save")

local Default = TuningManagerSave()
Default:loadLocalArray({
    {"ParameterMatrix", "require(\"BHElib.scripts.linear_tuning.parameter_matrix\")"},
    {"BulletOutputColumn", "require(\"BHElib.scripts.linear_tuning.output_columns.bullet_output_column\")"},
    {"AccCol", "require(\"BHElib.scripts.linear_tuning.output_columns.delayed_acc_bullet_output_column\")"},
    {"AccController", "require(\"BHElib.scripts.units.acc_controller\")"},
    {"ColumnScripts", "require(\"BHElib.scripts.linear_tuning.column_scripts\")"},
    {"F", "ColumnScripts.DefaultFollow"},
    {"PV", "ColumnScripts.DefaultPolarVelocity"},
    {"PP", "ColumnScripts.DefaultPolarPos"},
    {"RE", "ColumnScripts.ConstructReplace"},
    {"AIM", "ColumnScripts.ConstructAimFromPos"},
    {"AIMP", "ColumnScripts.ConstructAimFromPos(\"x\",\"y\",\"da\")"},
})
M.Default = Default

return M