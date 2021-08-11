--------------------------------------------------------------------------
---loading.lua
---deals with the loading of mods, directories, and plugins into the game
---modifier:
---     Karl, 2021.2.2 renamed some functions and added function docs.
--------------------------------------------------------------------------

local FU = cc.FileUtils:getInstance()
local FS = require("file_system.file_system")

---If the directory exists, add directory path to the default paths;
---otherwise the function will load the zip files with LoadPack() function.
---@param directory_path string the directory path to add
function lstg.AddDirectoryToDefaultPaths(directory_path)
    local writable_path = FS.getWritablePath()

    -- look for directories or zip files
    local possible_dir = { directory_path .. '/', writable_path .. directory_path .. '/' }
    local possible_zip = { directory_path .. '.zip', writable_path .. directory_path .. '.zip' }
    local file_is_found = false
    for _, dir in ipairs(possible_dir) do
        if FU:isDirectoryExist(dir) then
            local fp = FU:fullPathForFilename(dir)
            FU:addSearchPath(fp)
            SystemLog(string.format(i18n "load %s from local path %q", v, fp))
            file_is_found = true
            break
        end
    end
    -- if directory is not found, look for zip files
    if not file_is_found then
        for _, zip_file in ipairs(possible_zip) do
            if FS.isFileExist(zip_file) then
                local zip_path = FU:fullPathForFilename(zip_file)
                SystemLog(string.format(i18n "load %s from %q", v, zip_path))
                LoadPack(zip_path)
                file_is_found = true
                break
            end
        end
    end
    if not file_is_found then
        -- print a message indicating directory is not found
        Print(string.format('%s %q %s', "ERROR:"..i18n "can't find", dir_name, i18n "file"))
        --Print(stringify(possible_dir), stringify(possible_zip))
    end
end

--

local _setting_util = require("setting.setting_util")

---add mod directory given in the path "mod/"..setting.mod;
---look for either directory or .zip file;
---calls lstg.loadPlugin();
---run root.lua file;
---call lstg.loadSetting();
---call SetTitle() and
---set the resource pool to stage afterwards
---@param mod_name string
---@param sevolume number
---@param bgmvolume number
function lstg.loadMod(mod_name, sevolume, bgmvolume)
    local writable_path = FS.getWritablePath()
    local mod_path = string.format('%s/mod/%s', writable_path, mod_name)
    mod_path = mod_path:gsub('//', '/')  -- replace '//' with '/'

    local dir, zip = true, true  -- whether or not try to load directory and zip

    -- look for /root.lua or .zip
    if dir and FS.isFileExist(mod_path .. '/root.lua') then
        FU:addSearchPath(mod_path)
        SystemLog(string.format(i18n 'load mod %q from local path', mod_name))
    elseif zip and FS.isFileExists(mod_path .. '.zip') then
        SystemLog(string.format(i18n 'load mod %q from zip file', mod_name))
        LoadPack(mod_path .. '.zip')
    else
        SystemLog(string.format('%s: %s', "ERROR"..i18n "can't find mod", path))
    end
    SetResourceStatus('global')
    lstg.loadPlugins()

    local scene = require('root')

    ---update the screen and sound settings according to the values set in global setting table
    local _scr_metrics = require("setting.screen_metrics")

    local setting_file_mirror = require("setting.setting_file_mirror")
    local setting_content = setting_file_mirror:getContent()
    _scr_metrics.setWindowTitle(setting_content.mod)
    SetSEVolume(sevolume / 100)
    SetBGMVolume(bgmvolume / 100)

    SetResourceStatus('stage')
    return scene
end

function lstg.enumPlugins()
    local p = 'plugin/'
    if not FU:isDirectoryExist(p) then
        SystemLog('no direcory for plugin')
        return {}
    end
    local path = FU:fullPathForFilename(p)
    FU:addSearchPath(path)
    SystemLog(string.format('enum plugins in %q', path))
    local ret = {}
    local files = FS.getBriefOfFilesInDirectory(path)
    for i, v in ipairs(files) do
        -- skip name start with dot
        if v.name:sub(1, 1) ~= '.' then
            if v.isDirectory then
                if FS.isFileExist(path .. v.name .. '/__init__.lua') then
                    table.insert(ret, v)
                end
            else
                if string.lower(string.fileext(v.name)) == 'zip' then
                    v.name = v.name:sub(1, -5)
                    assert(v.name ~= '')
                    table.insert(ret, v)
                end
            end
        end
    end
    return ret
end

plugin = {}
local plugin_list = {}

function lstg.loadPlugins()
    local files = lstg.enumPlugins()
    for i, v in ipairs(files) do
        local name = v.name
        if v.isDirectory then
            local fp = FU:fullPathForFilename(string.format('plugin/%s/__init__.lua', name))
            if fp ~= '' then
                SystemLog(string.format(i18n 'load plugin %q from local path', name))
                Include(fp)
            end
        else
            local fp = FU:fullPathForFilename('plugin/' .. name .. '.zip')
            if fp ~= '' then
                SystemLog(string.format(i18n 'load plugin %q from zip file', name))
                LoadPack(fp)
                Include(name .. '/__init__.lua')
            end
        end
        table.insert(plugin_list, v)
    end
end

function lstg.getPluginList()
    return plugin_list
end
