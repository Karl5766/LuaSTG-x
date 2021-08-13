---------------------------------------------------------------------------------------------------
---bhelib_init.lua
---author: Karl
---date: 2021.2.14
---references: -x/src/core/__init__.lua
---desc: Includes files that implements the shmup game mechanics of luastg engine
---------------------------------------------------------------------------------------------------

local _include_list = {
    "BHElib.unclassified.const",  -- defines some constant values
    "BHElib.unclassified.object_status",

    -- input
    "BHElib.input.input_and_recording",

    "BHElib.unclassified.screen_effect",
    "BHElib.unclassified.coordinates_and_screen",

    "BHElib.unclassified.global_assets",  -- loads some assets globally

    "BHElib.unclassified.task",

    "BHElib.unclassified.corefunc",
}

for _, file_path in ipairs(_include_list) do
    require(file_path)
end