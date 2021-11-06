local col = OutputColumns.AccBullet(master)
col.x = 0
col.y = 0
col.a = 0
col.v = 3
col.ra = 0
col.r = 0
col.bullet_type_name = "square"
col.color_index = COLOR_BLUE
col.blink_time = 12
col.inc_rot = 0
col.effect_size = 1
col.destroyable = true
col.sound = {"se:tan00", 0.06}

function col:spark()
    self.controller = AccController.shortInit(self.v, 10, self.v2)
    OutputColumns.AccBullet.spark(self)
end

return ParameterMatrix.ChainInit(master, n_row, n_col, matrix, col)