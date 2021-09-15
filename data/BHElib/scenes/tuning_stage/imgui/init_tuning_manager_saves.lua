local M = {}

local TuningManagerSave = require("BHElib.scenes.tuning_stage.imgui.tuning_manager_save")

local Default = TuningManagerSave()
Default:loadLocalArray({})
Default.context_str = [==[

local ParameterMatrix = require("BHElib.scripts.linear_tuning.parameter_matrix")
local OutputColumns = require("BHElib.scripts.linear_tuning.output_columns")
local AccController = require("BHElib.scripts.units.acc_controller")
local ColumnScripts = require("BHElib.scripts.linear_tuning.column_scripts")
local EnemyTypes = require("BHElib.units.enemy.enemy_type.enemy_types")
local ADD = ColumnScripts.ConstructAdd
local AIM = ColumnScripts.ConstructAimFromPos
local AIMP = ColumnScripts.ConstructAimFromPos("da","x","y")
local F = ColumnScripts.ConstructFollow("x", "y")
local MIR = ColumnScripts.ConstructMirror
local PO = ColumnScripts.ConstructPolarVec
local PP = PO("x", "y", "r", "ra")
local PV = PO("vx", "vy", "v", "a")
local R = ColumnScripts.ConstructRandom
local RCIR = ColumnScripts.ConstructOffsetRandomOnCircle
local ROT = ColumnScripts.ConstructRotation
local SET,SETI,SETJ,SETK = ColumnScripts.ConstructSet,ColumnScripts.SetI,ColumnScripts.SetJ,ColumnScripts.SetK

]==]
M.Default = Default

return M