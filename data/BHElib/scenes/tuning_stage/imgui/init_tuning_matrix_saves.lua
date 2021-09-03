
---@class InitTuningMatrixSaves
local M = {}

local TuningMatrixSave = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix_save")


local save

---------------------------------------------------------------------------------------------------
---StandardAcc

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", "N/A", "nil", "nil"},
    {"s_n", "N/A", "INFINITE", "1"},
    {"s_dt", "N/A", "0", "0"},
    {"da", "0", "0", "0"},
    {"v", "0", "0", "0"},
    {"x", "0", "0", "0"},
    {"y", "0", "0", "0"},
}
save.num_col = 4
save.num_row = 7
save.output_str = [==[
local col = AccCol(master)
col.x = 0
col.y = 0
col.da = 0
col.v = 2
col.bullet_type_name = "ball"
col.color_index = COLOR_BLUE
col.blink_time = 12
col.inc_rot = 3
col.effect_size = 1
col.destroyable = true

function col:spark()
    self.angle = self.da
    self.controller = AccController.shortInit(6, 30, self.v)
    AccCol.spark(self)
end

return ParameterMatrix.MatrixInit(master, n_row, n_col, matrix, col)
]==]
M.StandardAcc = save

---------------------------------------------------------------------------------------------------
---StandardAcc

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", "N/A", "nil", "PP,F"},
    {"s_n", "N/A", "INFINITE", "1"},
    {"s_t", "N/A", "0", "0"},
    {"s_dt", "N/A", "60", "0"},
    {"a", "0", "0", "0"},
    {"r", "0", "0", "0"},
    {"da", "0", "0", "0"},
    {"v", "0", "0", "0"},
    {"x", "0", "0", "0"},
    {"y", "0", "0", "0"},
}
save.num_col = 4
save.num_row = 10
save.output_str = [==[
local col = AccCol(master)
col.x = 0
col.y = 0
col.da = 0
col.v = 2
col.a = 0
col.r = 0
col.bullet_type_name = "ball"
col.color_index = COLOR_BLUE
col.blink_time = 12
col.inc_rot = 3
col.effect_size = 1
col.destroyable = true

function col:spark()
    self.angle = self.da
    self.controller = AccController.shortInit(6, 30, self.v)
    AccCol.spark(self)
end

return ParameterMatrix.MatrixInit(master, n_row, n_col, matrix, col)
]==]
M.PolarAcc = save

return M