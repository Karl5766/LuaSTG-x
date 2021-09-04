
---@class InitTuningMatrixSaves
local M = {}

local TuningMatrixSave = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix_save")


local save

---------------------------------------------------------------------------------------------------
---BossMove

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", "N/A", "nil"},
    {"s_n", "N/A", "INFINITE"},
    {"s_t", "N/A", "0"},
    {"s_dt", "N/A", "240"},
}
save.num_col = 3
save.num_row = 4
save.output_str = [==[
local col = OutputColumns.BossMove(master)
col.l = -100
col.r = 100
col.b = 80
col.t = 144
col.mt = 60
col.dxmin = 32
col.dxmax = 48
col.dymin = 16
col.dymax = 32

function col:spark()
    OutputColumns.BossMove.spark(self)
end

return ParameterMatrix.ChainInit(master, n_row, n_col, matrix, col)
]==]
M.BossMove = save

---------------------------------------------------------------------------------------------------
---StandardAcc

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", "N/A", "nil", "nil"},
    {"s_n", "N/A", "INFINITE", "1"},
    {"s_dt", "N/A", "0", "0"},
    {"a", "0", "0", "0"},
    {"v", "3", "0", "0"},
    {"x", "0", "0", "0"},
    {"y", "0", "0", "0"},
}
save.num_col = 4
save.num_row = 7
save.output_str = [==[
local col = OutputColumns.AccBullet(master)
col.x = 0
col.y = 0
col.a = 0
col.v = 3
col.bullet_type_name = "ball"
col.color_index = COLOR_BLUE
col.blink_time = 12
col.inc_rot = 3
col.effect_size = 1
col.destroyable = true

function col:spark()
    self.angle = self.a
    self.controller = AccController.shortInit(6, 30, self.v)
    OutputColumns.AccBullet.spark(self)
end

return ParameterMatrix.ChainInit(master, n_row, n_col, matrix, col)
]==]
M.StandardAcc = save

---------------------------------------------------------------------------------------------------
---PolarAcc

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", "N/A", "nil", "PP,F"},
    {"s_n", "N/A", "INFINITE", "1"},
    {"s_t", "N/A", "0", "0"},
    {"s_dt", "N/A", "60", "0"},
    {"ra", "0", "0", "0"},
    {"r", "0", "0", "0"},
    {"a", "0", "0", "0"},
    {"v", "3", "0", "0"},
    {"x", "0", "0", "0"},
    {"y", "0", "0", "0"},
}
save.num_col = 4
save.num_row = 10
save.output_str = [==[
local col = OutputColumns.AccBullet(master)
col.x = 0
col.y = 0
col.a = 0
col.v = 3
col.ra = 0
col.r = 0
col.bullet_type_name = "ball"
col.color_index = COLOR_BLUE
col.blink_time = 12
col.inc_rot = 3
col.effect_size = 1
col.destroyable = true

function col:spark()
    self.angle = self.a
    self.controller = AccController.shortInit(6, 30, self.v)
    OutputColumns.AccBullet.spark(self)
end

return ParameterMatrix.ChainInit(master, n_row, n_col, matrix, col)
]==]
M.PolarAcc = save

---------------------------------------------------------------------------------------------------
---StandardEnemy

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", "N/A", "nil", "PV"},
    {"s_n", "N/A", "INFINITE", "1"},
    {"s_dt", "N/A", "60", "0"},
    {"a", "-90", "0", "0"},
    {"v", "1", "0", "0"},
    {"x", "0", "0", "0"},
    {"y", "234", "0", "0"},
}
save.num_col = 4
save.num_row = 7
save.output_str = [==[
local col = OutputColumns.Enemy(master)
col.x = 0
col.y = 0
col.a = 0
col.v = 2
col.hp = 5
col.type = EnemyTypes.bow_tie_fairy_red

function col:spark()
    local a, v = self.a, self.v

    OutputColumns.Enemy.spark(self)
end

return ParameterMatrix.ChainInit(master, n_row, n_col, matrix, col)
]==]
M.StandardEnemy = save

return M