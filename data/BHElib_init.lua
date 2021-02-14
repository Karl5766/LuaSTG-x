local _include_list = {
    'BHElib/const.lua',  -- defines some constant values
    'BHElib/status.lua',

    'BHElib/screen.lua',
    'BHElib/view.lua',

    'BHElib/class.lua',
    'BHElib/task.lua',

    'BHElib/stage.lua',
    'BHElib/stage_group.lua',

    'BHElib/global.lua',  -- defines some in-game global variables
    'BHElib/corefunc.lua',
    'BHElib/after_load.lua',
}

for _, file_path in ipairs(_include_list) do
    DoFile(file_path)
end