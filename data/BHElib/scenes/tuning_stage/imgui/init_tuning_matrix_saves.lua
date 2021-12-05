
---@class InitTuningMatrixSaves
local M = {}

local TuningMatrixSave = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix_save")
local TuningMatrix = require("BHElib.scenes.tuning_stage.imgui.tuning_matrix")
local CodeSnapshotBufferSave = require("BHElib.scenes.tuning_stage.imgui.code_snapshot_buffer_save")

local NON_APPLICABLE_STR = TuningMatrix.NON_APPLICABLE_STR
local EPT = TuningMatrix.EMPTY_CELL_STR

---------------------------------------------------------------------------------------------------

local function GetDefaultSave(name)
    local base_path = "data/BHElib/scenes/tuning_stage/default_code/"
    local path = base_path..name.."_output_control.lua"
    return CodeSnapshotBufferSave.shortInit(path)
end
local save

---------------------------------------------------------------------------------------------------
---BossEffect

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", NON_APPLICABLE_STR, EPT},
    {"s_n", NON_APPLICABLE_STR, "INFINITE"},
    {"s_t", NON_APPLICABLE_STR, "-60"},
    {"s_dt", NON_APPLICABLE_STR, "240"},
}
save.num_col = #save.matrix[1]
save.num_row = #save.matrix
save.matrix_title = "BossEffect"
save.output_control_save = GetDefaultSave(save.matrix_title)
save.tail_script = EPT
M[save.matrix_title] = save

---------------------------------------------------------------------------------------------------
---StdBullet

--save = TuningMatrixSave(nil)
--save.matrix = {
--    {"s_script", NON_APPLICABLE_STR, EPT},
--    {"s_n", NON_APPLICABLE_STR, "INFINITE"},
--    {"s_t", NON_APPLICABLE_STR, EPT},
--    {"s_dt", NON_APPLICABLE_STR, "120"},
--    {"a", EPT, EPT},
--    {"v", "3", EPT},
--    {"x", EPT, EPT},
--    {"y", EPT, EPT},
--}
--save.num_col = #save.matrix[1]
--save.num_row = #save.matrix
--save.matrix_title = "StdBullet"
--save.output_control_save = GetDefaultSave(save.matrix_title)
--save.tail_script = EPT
--M[save.matrix_title] = save

---------------------------------------------------------------------------------------------------
---Bullet

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", NON_APPLICABLE_STR, EPT},
    {"s_n", NON_APPLICABLE_STR, "INFINITE"},
    {"s_t", NON_APPLICABLE_STR, EPT},
    {"s_dt", NON_APPLICABLE_STR, "120"},
    {"ra", EPT, EPT},
    {"r", EPT, EPT},
    {"a", EPT, EPT},
    {"v", "3", EPT},
}
save.num_col = #save.matrix[1]
save.num_row = #save.matrix
save.matrix_title = "Bullet"
save.output_control_save = GetDefaultSave(save.matrix_title)
save.tail_script = "F,PP"
M[save.matrix_title] = save

---------------------------------------------------------------------------------------------------
---Enemy

save = TuningMatrixSave(nil)
save.matrix = {
    {"s_script", NON_APPLICABLE_STR, EPT},
    {"s_n", NON_APPLICABLE_STR, "INFINITE"},
    {"s_dt", NON_APPLICABLE_STR, "120"},
    {"a", "-90", EPT},
    {"v", "1", EPT},
    {"x", EPT, EPT},
    {"y", "234", EPT},
}
save.num_col = #save.matrix[1]
save.num_row = #save.matrix
save.matrix_title = "Enemy"
save.output_control_save = GetDefaultSave(save.matrix_title)
save.tail_script = "PV"
M[save.matrix_title] = save

return M