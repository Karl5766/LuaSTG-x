local M = {}

local TuningManagerSave = require("BHElib.scenes.tuning_stage.imgui.tuning_manager_save")

local Default = TuningManagerSave()
Default:loadLocalArray({
    {"ParameterMatrix", "require(\"BHElib.scripts.linear_tuning.parameter_matrix\")"},
    {"OutputColumns", "require(\"BHElib.scripts.linear_tuning.output_columns\")"},
    {"AccController", "require(\"BHElib.scripts.units.acc_controller\")"},
    {"ColumnScripts", "require(\"BHElib.scripts.linear_tuning.column_scripts\")"},
    {"EnemyTypes", "require(\"BHElib.units.enemy.enemy_type.enemy_types\")"},
    {"F", "ColumnScripts.DefaultFollow"},
    {"PV", "ColumnScripts.DefaultPolarVelocity"},
    {"PP", "ColumnScripts.DefaultPolarPos"},
    {"RE", "ColumnScripts.ConstructReplace"},
    {"AIM", "ColumnScripts.ConstructAimFromPos"},
    {"AIMP", "ColumnScripts.ConstructAimFromPos(\"x\",\"y\",\"da\")"},
    {"R", "ColumnScripts.ConstructRandom"},
    {"RCIR", "ColumnScripts.ConstructOffsetRandomOnCircle"},
})
M.Default = Default

return M