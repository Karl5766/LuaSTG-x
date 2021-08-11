---date created: 2021.8.9
---desc: a separate table from setting, used to save user-specific, gameplay-related information

local JsonFileMirror = require("file_system.json_file_mirror")
local FS = require("file_system.file_system")
---@type PlatformInfo
local PlatformInfo = assert(require("platform.platform_info"))

local setting_file_mirror = require("setting.setting_file_mirror")
local setting_content = setting_file_mirror:getContent()

local mod_name = setting_content.mod_info.name
local score_dir = 'score/' .. mod_name .. '/'  --path: score/mod_name
if PlatformInfo.getOSName() ~= 'windows' then
    score_dir = FS.getWritablePath() .. "score/" .. mod_name .. '/'
end

FS.createDirectory(score_dir:sub(1, -2))

local username = setting_content.username or "User"
local fpath = score_dir .. username .. ".dat"

local args = {
    allow_empty_init_file = true,
    file_not_found_message = i18n "Can't find player save file",
    encode_test_flag = false,
}

---@type JsonFileMirror
local M = JsonFileMirror(fpath, args)

return M, M:getContent()