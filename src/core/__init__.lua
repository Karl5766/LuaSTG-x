local _include_list = {
    'core/include.lua',
    'core_x/__init__.lua',

    'core/math.lua',
    'core/resources.lua',
    'core/screen.lua',
    'core/file.lua',
    'core/loading.lua',
    'core/async.lua',
    'core/score.lua',
}

for _, f in ipairs(_include_list) do
    DoFile(f)
end

lstg.AddDirectoryToDefaultPaths('data')
lstg.AddDirectoryToDefaultPaths('data_assets')
lstg.AddDirectoryToDefaultPaths('background')

require('platform.ControllerHelper').init()
lstg.ResourceMgr:getInstance():clearLocalFileCache()
