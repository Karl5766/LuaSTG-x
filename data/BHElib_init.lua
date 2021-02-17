---------------------------------------------------------------------------------------------------
---BHElib_init.lua
---author: Karl
---date: 2021.2.14
---references: -x/src/core/__init__.lua
---desc: Includes files that implements the shmup game mechanics of luastg engine
-------------------------------------------------------------------------------------------------

local _include_list = {
    "BHElib/const.lua",  -- defines some constant values
    "BHElib/status.lua",

    "BHElib/input.lua",

    "BHElib/coordinates_and_screen.lua",
    "BHElib/view.lua",

    "BHElib/game_object.lua",
    "BHElib/task.lua",

    "BHElib/stage.lua",
    "BHElib/stage_group.lua",

    "BHElib/global.lua",  -- defines some in-game global variables
    "BHElib/corefunc.lua",
    "BHElib/after_load.lua",
}

for _, file_path in ipairs(_include_list) do
    DoFile(file_path)
end