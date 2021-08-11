---reference:
---     cjson manual, https://www.kyne.com.au/~mark/software/lua-cjson-manual.html

local JsonFileMirror = require("file_system.json_file_mirror")
local FS = require("file_system.file_system")

local _setting_path = FS.getWritablePath() .. 'setting/setting.ini'  -- setting file is at the main directory

local args = {
    allow_empty_init_file = false,
    file_not_found_message = "Can't find setting file",
    encode_test_flag = true,
}
---@type JsonFileMirror
local M = JsonFileMirror(_setting_path, args)

return M, M:getContent()
