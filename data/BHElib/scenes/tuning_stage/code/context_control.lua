
local ParameterMatrix = require("BHElib.scripts.linear_tuning.parameter_matrix")
local OutputColumns = require("BHElib.scripts.linear_tuning.output_columns")
local AccController = require("BHElib.scripts.units.acc_controller")
local ColumnScripts = require("BHElib.scripts.linear_tuning.column_scripts")
local EnemyTypes = require("BHElib.units.enemy.enemy_type.enemy_types")
local HotIter = require("BHElib.scripts.iter.hot_iter")
local IterTypes = require("BHElib.scripts.iter.iter_types")

local hot_iter = HotIter()
if external_objects.hot_iter then
    hot_iter:inheritIndices(external_objects.hot_iter)
end
external_objects.hot_iter = hot_iter

local ADD = ColumnScripts.ConstructAdd
local AIM = ColumnScripts.ConstructAimFromPos
local MIR = ColumnScripts.ConstructMirror
local MUL = ColumnScripts.ConstructMultiply
local PO = ColumnScripts.ConstructPolarVec
local R = ColumnScripts.ConstructRandom
local RCIRC = ColumnScripts.ConstructOffsetRandomOnCircle
local ROT = ColumnScripts.ConstructRotation
local RNORM = ColumnScripts.ConstructRandomNormal
local S,SETI,SETJ,SETK = ColumnScripts.ConstructSet,ColumnScripts.SetI,ColumnScripts.SetJ,ColumnScripts.SetK

local AIMP = ColumnScripts.ConstructAimFromPos("a","x","y")
local ARA = ColumnScripts.ConstructAdd("a","ra")
local F = ColumnScripts.ConstructFollow("x", "y")
local PP = PO("x", "y", "r", "ra")
local PV = PO("vx", "vy", "v", "a")

local MakeMS = ColumnScripts.MakeMatrixScript
local mR = MakeMS(R)
local mS = MakeMS(S)
local mAIM = MakeMS(AIM)
local mADD = MakeMS(ADD)
local mMIR = MakeMS(MIR)
local mRNORM = MakeMS(RNORM)