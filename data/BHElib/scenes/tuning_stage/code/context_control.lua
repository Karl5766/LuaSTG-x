
local ParameterMatrix = require("BHElib.scripts.linear_tuning.parameter_matrix")
local OutputColumns = require("BHElib.scripts.linear_tuning.output_columns")
local AccController = require("BHElib.scripts.units.acc_controller")
local ColumnScripts = require("BHElib.scripts.linear_tuning.column_scripts")
local EnemyTypes = require("BHElib.units.enemy.enemy_type.enemy_types")
local ADD = ColumnScripts.ConstructAdd
local AIM = ColumnScripts.ConstructAimFromPos
local MIR = ColumnScripts.ConstructMirror
local MUL = ColumnScripts.ConstructMultiply
local PO = ColumnScripts.ConstructPolarVec
local R = ColumnScripts.ConstructRandom
local RCIR = ColumnScripts.ConstructOffsetRandomOnCircle
local ROT = ColumnScripts.ConstructRotation
local RNORM = ColumnScripts.ConstructRandomNormal
local S,SETI,SETJ,SETK = ColumnScripts.ConstructSet,ColumnScripts.SetI,ColumnScripts.SetJ,ColumnScripts.SetK

local AIMP = ColumnScripts.ConstructAimFromPos("a","x","y")
local ARA = ColumnScripts.ConstructAdd("a","ra")
local F = ColumnScripts.ConstructFollow("x", "y")
local PP = PO("x", "y", "r", "ra")
local PV = PO("vx", "vy", "v", "a")

local hot_iter = require("BHElib.scripts.iter.hot_iter")()
local IterTypes = require("BHElib.scripts.iter.iter_types")
IterTypes:addBulletColorTypeIter(hot_iter, "aimed")
external_objects.hot_iter = hot_iter

local function MIRROR_I(cur, next, i)
	if next.i % 2 == 1 then
		next.x = -next.x
		next.ra = - next.ra
		next.a = -next.a
	end
end

local rainbow = {COLOR_PURPLE, COLOR_PURPLE, COLOR_RED, COLOR_RED, COLOR_RED}

local x_offsets = {-133, -67, 0, 67, 133}
local v_list = {1, 2, 1.5, 2, 1}

local function HORIZONTAL(cur, next, i)
	local index = i % 5 + 1
	next.color_index = rainbow[index]
	next.x = next.x + x_offsets[index]
	next.v = v_list[index]	
end

local color_list = {COLOR_PURPLE, COLOR_PURPLE}

local function MIRROR_I2(cur, next, i)
	if next.i % 2 == 0 and i == 0 then
		next.s_n = 0
	end
	if next.i  % 2 == 0 then
		next.a = cur.a - cur.d_a * i
	end
end

local function SET_COLOR(cur,next,i)
	next.color_index = color_list[i % 2 + 1]
end
