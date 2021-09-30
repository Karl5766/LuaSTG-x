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
    require("BHElib.units.effects.boss_fight_effects").CreateBossCastEffect(boss.x, boss.y, 255, 0, 0)
    task.New(boss, function()
        task.Wait(180)
        require("BHElib.scripts.units.unit_motion").RandomBossMove(
                boss, self.l, self.r, self.b, self.t,
                self.dxmin, self.dxmax, self.dymin, self.dymax, self.mt)
    end)
end

return ParameterMatrix.ChainInit(master, n_row, n_col, matrix, col)