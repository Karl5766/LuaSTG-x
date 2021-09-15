
---@class InitTuningMatrixSaves
local M = {}

local TuningMatrixSave = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix_save")

local NON_APPLICABLE_STR = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix").NON_APPLICABLE_STR

---------------------------------------------------------------------------------------------------

local save

---------------------------------------------------------------------------------------------------
---BossMove

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", NON_APPLICABLE_STR, "", ""},
    {"s_n", NON_APPLICABLE_STR, "INFINITE", "2"},
    {"s_t", NON_APPLICABLE_STR, "-60", ""},
    {"s_dt", NON_APPLICABLE_STR, "240", "180"},
    {"i", "", "", "1"}
}
save.num_col = 4
save.num_row = 5
save.output_str = [==[
local col = OutputColumns.Empty(master)
col.l = -60
col.r = 60
col.b = 96
col.t = 114
col.mt = 60
col.dxmin = 32
col.dxmax = 48
col.dymin = 16
col.dymax = 32

function col:spark()
    local boss = self.s_master
    local i = self.i
    if i == 1 then
        require("BHElib.scripts.units.unit_motion").RandomBossMove(
            boss, self.l, self.r, self.b, self.t,
            self.dxmin, self.dxmax, self.dymin, self.dymax, self.mt)
    elseif i == 0 then
        require("BHElib.units.effects.boss_fight_effects").CreateBossCastEffect(boss.x, boss.y, 255, 0, 0)
    end
end

return ParameterMatrix.ChainInit(master, n_row, n_col, matrix, col)
]==]
M.BossMove = save

---------------------------------------------------------------------------------------------------
---StandardAcc

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", NON_APPLICABLE_STR, "", ""},
    {"s_n", NON_APPLICABLE_STR, "INFINITE", "1"},
    {"s_t", NON_APPLICABLE_STR, "", ""},
    {"s_dt", NON_APPLICABLE_STR, "120", ""},
    {"a", "", "", ""},
    {"v", "3", "", ""},
    {"x", "", "", ""},
    {"y", "", "", ""},
}
save.num_col = 4
save.num_row = 8
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
col.sound = {"se:tan00", 0.06}

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
    {"s_script", NON_APPLICABLE_STR, "", "PP,F,ADD(\"a\",\"ra\")"},
    {"s_n", NON_APPLICABLE_STR, "INFINITE", "1"},
    {"s_t", NON_APPLICABLE_STR, "", ""},
    {"s_dt", NON_APPLICABLE_STR, "120", ""},
    {"ra", "", "", ""},
    {"r", "", "", ""},
    {"a", "", "", ""},
    {"v", "3", "", ""},
    {"x", "", "", ""},
    {"y", "", "", ""},
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
col.bullet_type_name = "arrowhead"
col.color_index = COLOR_BLUE
col.blink_time = 12
col.inc_rot = 0
col.effect_size = 1
col.destroyable = true
col.sound = {"se:tan00", 0.06}

function col:spark()
    self.angle = self.a
    self.controller = AccController.shortInit(6, 20, self.v)
    OutputColumns.AccBullet.spark(self)
end

return ParameterMatrix.ChainInit(master, n_row, n_col, matrix, col)
]==]
M.PolarAcc = save

---------------------------------------------------------------------------------------------------
---StandardEnemy

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", NON_APPLICABLE_STR, "", "PV"},
    {"s_n", NON_APPLICABLE_STR, "INFINITE", "1"},
    {"s_dt", NON_APPLICABLE_STR, "120", ""},
    {"a", "-90", "", ""},
    {"v", "1", "", ""},
    {"x", "", "", ""},
    {"y", "234", "", ""},
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
col.del_out_of_after_coming_in = {-192, 192, -224, 224}

function col:spark()
    OutputColumns.Enemy.spark(self)
end

return ParameterMatrix.ChainInit(master, n_row, n_col, matrix, col)
]==]
M.StandardEnemy = save

return M