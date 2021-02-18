local FU = cc.FileUtils:getInstance()
local FS = require("file_system")

---已包含的脚本
local _all_included_files = {}

---脚本搜索路径
local _current_script_path = { '' }

---
--- DoFile; but the given file can be reset with IncludeFileReset
---@param filename string
---@return any 脚本返回值
function Include(filename)
    filename = tostring(filename)
    filename = string.gsub(filename, '\\', '/')
    filename = string.gsub(filename, '//', '/')
    local f = filename
    filename = FU:fullPathForFilename(f)
    if not FS.isFileExist(filename) then
        error(string.format('%s: %s', i18n "can't find script", f))
    end

    if string.sub(filename, 1, 1) == '~' then
        filename = _current_script_path[#_current_script_path] .. string.sub(filename, 2)
    end
    if not _all_included_files[filename] then
        local i, j = string.find(filename, '^.+[\\/]+')
        if i then
            table.insert(_current_script_path, string.sub(filename, i, j))
        else
            table.insert(_current_script_path, '')
        end
        _all_included_files[filename] = true
        local ret = DoFile(filename)
        _current_script_path[#_current_script_path] = nil
        return ret
    end
end

---Used for live reset
function IncludeFileReset()
    _all_included_files = {}
    lstg.current_script_path = { '' }
end