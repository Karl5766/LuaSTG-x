---------------------------------------------------------------------------------------------------
---file_system.lua
---date: 2021.2.15
---desc: Defines x.FileSystem class, which provides functions for accessing files and directories
---     in local computer, as well as other file-related functions
---modifier:
---     Karl, 2021.2.15, split the file from NativeAPI.lua; merged into fs.lua and renamed result
---     as file_system.lua
---------------------------------------------------------------------------------------------------

---@class x.FileSystem
local M = {}

local FU = cc.FileUtils:getInstance()
---@type PlatformInfo
local _platform_info = require("platform.platform_info")

---判断文件是否存在，路径中所有'\\''//'当作'/'处理
---@param path string 路径
---@return boolean
function M.isFileExist(path)
    path = string.gsub(path, '\\', '/')
    path = string.gsub(path, '//', '/')
    local ret = FU:isFileExist(path)
    return ret
end

---创建目录
---@param path string 路径
function M.createDirectory(path)
    SystemLog(string.format(i18n 'try to create directory %q', path))
    if FU:isDirectoryExist(path) then
        return
    end
    if not FU:createDirectory(path) or not FU:isDirectoryExist(path) then
        error(i18n "create directory failed")
    end
end

---copy file; overwrite if exists
---@param path_from string 原文件路径
---@param path_to string 副本的完整路径
function M.copyFile(path_from, path_to)
    local FileStream = require("util.file_stream")
    local file_from = FileStream(path_from, "rb")
    local file_to = FileStream(path_to, "wb")
    while true do
        local b = file_from:readByte()
        if b then
            file_to:writeByte(b)
        else
            break
        end
    end
    file_from:close()
    file_to:close()
    print("finished copying file")
end


---default writable path
local _writable_path

---get a writable directory path in the device
---@return string a writable path
function M.getWritablePath()
    if _writable_path then
        return _writable_path
    end
    local wp = FU:getWritablePath()
    if _platform_info.isDesktop() and wp == './' then
        return FU:fullPathForFilename(wp):sub(1, -3)
    else
        return wp
    end
end

local function Setup()
    local newWritablePath = require('platform.util').changeWritablePath()
    if newWritablePath then
        _writable_path = newWritablePath
    end
end
Setup()

-------------------------------------------------------------------------------------------------
---directory traverse

---获取目录中所有文件或文件夹的缩略信息的列表
---结果的格式为：（如有一个文件和一个文件夹）
--- { { isDirectory = false, name = "abc.txt", lastAccessTime = 0, size = 0 },
---   { isDirectory = true, name = "test" } }
---@param dir_path string 目录
---@return table an array of brief information about each file in a directory
function M.getBriefOfFilesInDirectory(dir_path)
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
function M.enumFilesByType(dir_pah, suffix)
    local ret = {}
    suffix = string.lower(suffix)
    local l = -1 - #suffix
    local files = M.getBriefOfFilesInDirectory(dir_pah)
    for _, v in ipairs(files) do
        if not v.isDirectory then
            if string.lower(v.name:match(".+%.(%w+)$") or '') == suffix then
                v.name = v.name:sub(1, l)
                assert(v.name ~= '')
                table.insert(ret, v)
            end
        end
    end
    return ret
end

---@param script_names table
---@param root_path string path to the directory that contains all scripts, with "." as separator
---@return table an array of return value of the requires
function M.requireScriptsInDirectory(script_names, root_path)
    local ret = {}
    for i, script_name in ipairs(script_names) do
        ret[i] = require(root_path.."."..script_name)
    end
    return ret
end

---------------------------------------------------------------------------------------------------

---@param rootpath string the root path to search on
---@param paths table if specified, the function will append to this table and return it
---@return table an array of full path of files in the directory
function M.listFiles(rootpath, paths)
    paths = paths or {}
    assert(rootpath)
    local files = M.getBriefOfFilesInDirectory(rootpath)
    for i, v in ipairs(files) do
        if not v.isDirectory then
            table.insert(paths, v.fullPath)
        end
    end
    return paths
end

---@param rootpath string the root path to search on
---@return table an array of full path of files in the directory
function M.listFilenames(rootpath)
    local ret = {}
    assert(rootpath)
    local files = M.getBriefOfFilesInDirectory(rootpath)
    for i, v in ipairs(files) do
        if not v.isDirectory then
            table.insert(ret, v.name)
        end
    end
    return ret
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
    p = FU:fullPathForFilename(p)
    return p
end

function M.getScriptFolder()
    local p = debug.getinfo(2, "S").source
    p = FU:fullPathForFilename(p)
    return M.getFolder(p)
end

function M.enumMods(path, root_name)
    local ret = {}
    root_name = root_name or 'root.lua'
    local files = M.getBriefOfFilesInDirectory(path)
    for i, v in ipairs(files) do
        if v.isDirectory then
            if M.isFileExist(path .. v.name .. '/' .. root_name) then
                table.insert(ret, v)
            end
        else
            if string.lower(v.name:match(".+%.(%w+)$") or '') == 'zip' then
                v.name = v.name:sub(1, -5)
                assert(v.name ~= '')
                table.insert(ret, v)
            end
        end
    end
    table.sort(ret, function(a, b)
        if a.isDirectory ~= b.isDirectory then
            return a.isDirectory
        end
        return a.name < b.name
    end)
    return ret
end

return M
