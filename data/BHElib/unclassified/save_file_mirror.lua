---date created: 2021.8.9
---desc: a separate table from setting, used to save user-specific, gameplay-related information

local JsonFileMirror = require("core.json_file_mirror")
local FS = require("file_system")
---@type PlatformInfo
local PlatformInfo = assert(require("platform.platform_info"))

local score_dir = 'score/' .. setting.mod .. '/'  --path: score/mod_name
if PlatformInfo.getOSName() ~= 'windows' then
    score_dir = FS.getWritablePath() .. "score/" .. setting.mod .. '/'
end

FS.createDirectory(score_dir:sub(1, -2))

local username = setting.username or "User"
local fpath = score_dir .. username .. ".dat"

---@type JsonFileMirror
local M = JsonFileMirror(fpath)

return M