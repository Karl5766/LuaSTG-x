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