---------------------------------------------------------------------------------------------------
---file_system.lua
---date: 2021.2.15
---desc: Defines functions for accessing files and directories in local computer, as well as
---     creating directories. Defines x.FileSystem class
---modifier:
---     Karl, 2021.2.15, split the file from NativeAPI.lua; merged into fs.lua and renamed result
---     as file_system.lua
---------------------------------------------------------------------------------------------------

local FU = cc.FileUtils:getInstance()
plus = plus or {}

---判断文件是否存在，路径中所有'\\''//'当作'/'处理
---@param path string 路径
---@return boolean
function IsFileExist(path)
    path = string.gsub(path, '\\', '/')
    path = string.gsub(path, '//', '/')
    local ret = FU:isFileExist(path)
    return ret
end

---创建目录
---@param path string 路径
function CreateDirectory(path)
    SystemLog(string.format(i18n 'try to create directory %q', path))
    if FU:isDirectoryExist(path) then
        return
    end
    if not FU:createDirectory(path) or not FU:isDirectoryExist(path) then
        error(i18n "create directory failed")
    end
end


---default writable path
local _writable_path

---get a writable directory path in the device
---@return string a writable path
function plus.getWritablePath()
    if _writable_path then
        return _writable_path
    end
    local wp = FU:getWritablePath()
    if plus.isDesktop() and wp == './' then
        return FU:fullPathForFilename(wp):sub(1, -3)
    else
        return wp
    end
end

-------------------------------------------------------------------------------------------------
---directory traverse

---获取目录中所有文件或文件夹的缩略信息的列表
---结果的格式为：（如有一个文件和一个文件夹）
--- { { isDirectory = false, name = "abc.txt", lastAccessTime = 0, size = 0 },
---   { isDirectory = true, name = "test" } }
---@param dir_path string 目录
---@return table an array of brief information about each file in a directory
function GetBriefOfFilesInDirectory(dir_path)
    dir_path = string.gsub(dir_path, '\\', '/')
    if dir_path:sub(-1) ~= '/' then
        dir_path = dir_path .. '/'
    end
    if not FU:isDirectoryExist(dir_path) then
        SystemLog(string.format(i18n 'dir_path %q dose not exist', dir_path))
        return {}
    end
    local pp = FU:fullPathForFilename(dir_path)
    assert(pp ~= '', 'can not find ' .. dir_path)
    local files = FU:listFiles(dir_path)
    local ret = {}
    ---@param f string
    for _, f in ipairs(files) do
        local fullpath = f
        if f:sub(-1) == '/' then
            f = f:sub(1, -2)
            -- find may return nil
            local _pos = f:reverse():find('/')
            if _pos then
                local pos = 1 - _pos
                f = f:sub(pos)
            end
            if f ~= '.' and f ~= '..' then
                table.insert(ret, {
                    isDirectory = true, name = f, fullPath = fullpath })
            end
        else
            local access = lfs.attributes(FU:getSuitableFOpen(f), 'access') or 'UNKNOEN'
            local size = FU:getFileSize(f) or 'UNKNOEN'
            local pos = 1 - f:reverse():find('/')
            f = f:sub(pos)
            table.insert(ret, {
                isDirectory = false, name = f, size = size, lastAccessTime = access, fullPath = fullpath })
        end
    end
    return ret
end


---获取目录中所有以给定suffix为后缀的文件的缩略信息列表
---结果的格式为：
--- { { isDirectory = false, name = "abc.txt", lastAccessTime = 0, size = 0 }, ...}
---@param dir_pah string path of the directory
---@param suffix string suffix of the file to look for
---@return table an array of brief information about each file in a directory
function EnumFilesByType(dir_pah, suffix)
    local ret = {}
    suffix = string.lower(suffix)
    local l = -1 - #suffix
    local files = GetBriefOfFilesInDirectory(dir_pah)
    for _, v in ipairs(files) do
        if not v.isDirectory then
            if string.lower(v.name:match(".+%.(%w+)$") or '') == suffix then
                v.name = v.name:sub(1, l)
                assert(v.name ~= '')
                table.insert(ret, v)
            end
        end
    end
end

---------------------------------------------------------------------------------------------------

---@class x.FileSystem
local M = {}
local fu = cc.FileUtils:getInstance()

function M.listFiles(rootpath, pathes)
    pathes = pathes or {}
    assert(rootpath)
    local files = GetBriefOfFilesInDirectory(rootpath)
    for i, v in ipairs(files) do
        if not v.isDirectory then
            table.insert(pathes, v.fullPath)
        end
    end
    return pathes
end

---getExtension
---@param str string
---@return string
function M.getExtension(str)
    return str:match(".+%.(%w+)$")
end

function M.listScripts(rootpath)
    local fs = M.listFiles(rootpath)
    local ret = {}
    for i, v in pairs(fs) do
        local ext = M.getExtension(v)
        if ext == 'lua' or ext == 'luac' then
            table.insert(ret, string.sub(v, 1))
        end
    end
    return ret
end

---getFolder
---@param filePath string
---@return string
function M.getFolder(filePath)
    local p1 = string.match(filePath, "^(.*)\\")
    local p2 = string.match(filePath, "^(.*)/")
    local ret
    if p1 and p2 then
        ret = (#p1 > #p2) and p1 or p2
    else
        ret = p1 or p2
    end
    if ret and ret:sub(-1) ~= '/' then
        ret = ret .. '/'
    end
    return ret
end

---getScriptPath
---@return string
function M.getScriptPath()
    local p = debug.getinfo(2, "S").source
    p = fu:fullPathForFilename(p)
    return p
end

function M.getScriptFolder()
    local p = debug.getinfo(2, "S").source
    p = fu:fullPathForFilename(p)
    return M.getFolder(p)
end

return M
