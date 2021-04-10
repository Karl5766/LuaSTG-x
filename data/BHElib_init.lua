---------------------------------------------------------------------------------------------------
---BHElib_init.lua
---author: Karl
---date: 2021.2.14
---references: -x/src/core/__init__.lua
---desc: Includes files that implements the shmup game mechanics of luastg engine
---------------------------------------------------------------------------------------------------

local _include_list = {
    "BHElib.const",  -- defines some constant values
    "BHElib.status",

    -- input
    "BHElib.input.input_and_replay",

    "BHElib.screen_capture",
    "BHElib.coordinates_and_screen",

    "BHElib.global_assets",  -- loads some assets globally

    "BHElib.prefab",  -- game objects
    "BHElib.task",

    "BHElib.global",  -- defines some in-game global variables
    "BHElib.corefunc",
    "BHElib.after_load",
}

for _, file_path in ipairs(_include_list) do
    require(file_path)
end