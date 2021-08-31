
---@class InitTuningMatrixSaves
local M = {}

local TuningMatrixSave = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix_save")

local StandardAcc = TuningMatrixSave(nil)
StandardAcc.matrix = {
    {"s_script", "N/A", "nil"},
    {"s_n", "N/A", "1"},
    {"s_dt", "N/A", "0"},
    {"angle", "0", "0"},
    {"x", "0", "0"},
    {"y", "0", "0"},
}
StandardAcc.num_col = 3
StandardAcc.num_row = 6
StandardAcc.output_str = [==[

local col = DelayedAccBulletOutputColumn(master)
col.x = 0
col.y = 0
col.angle = -90
col.bullet_type_name = "ball"
col.color_index = COLOR_BLUE
col.controller = AccController.shortInit(3, 30, 1)
col.blink_time = 12
col.inc_rot = 3
col.effect_size = 1
col.destroyable = true

return ParameterMatrix.MatrixInit(master, n_row, n_col, matrix, col)
]==]
M.StandardAcc = StandardAcc

return M