local M = {}

local TuningManagerSave = require("BHElib.scenes.tuning_stage.imgui.tuning_manager_save")

local Default = TuningManagerSave()
Default:loadLocalArray({
    {"ParameterMatrix", "require(\"BHElib.scripts.linear_tuning.parameter_matrix\")"},
    {"OutputColumns", "require(\"BHElib.scripts.linear_tuning.output_columns\")"},
    {"AccController", "require(\"BHElib.scripts.units.acc_controller\")"},
    {"ColumnScripts", "require(\"BHElib.scripts.linear_tuning.column_scripts\")"},
    {"EnemyTypes", "require(\"BHElib.units.enemy.enemy_type.enemy_types\")"},
    {"ADD", "ColumnScripts.ConstructAdd"},
    {"AIM", "ColumnScripts.ConstructAimFromPos"},
    {"AIMP", "ColumnScripts.ConstructAimFromPos(\"x\",\"y\",\"da\")"},
    {"F", "ColumnScripts.DefaultFollow"},
    {"MIR", "ColumnScripts.ConstructMirror"},
    {"PP,PV", "ColumnScripts.DefaultPolarPos,ColumnScripts.DefaultPolarVelocity"},
    {"RE", "ColumnScripts.ConstructReplace"},
    {"R", "ColumnScripts.ConstructRandom"},
    {"RCIR", "ColumnScripts.ConstructOffsetRandomOnCircle"},
    {"ROT", "ColumnScripts.ConstructRotation"},
    {"SET,SETI,SETJ,SETK", "ColumnScripts.ConstructSet,ColumnScripts.SetI,ColumnScripts.SetJ,ColumnScripts.SetK"}
})
M.Default = Default

return M