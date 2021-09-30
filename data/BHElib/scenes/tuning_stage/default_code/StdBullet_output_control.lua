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
    self.controller = AccController.shortInit(6, 30, self.v)
    OutputColumns.AccBullet.spark(self)
end

return ParameterMatrix.ChainInit(master, n_row, n_col, matrix, col)