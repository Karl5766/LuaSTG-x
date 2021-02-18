---------------------------------------------------------------------------------------------------
---BHElib_init.lua
---author: Karl
---date: 2021.2.14
---references: -x/src/core/__init__.lua
---desc: Includes files that implements the shmup game mechanics of luastg engine
-------------------------------------------------------------------------------------------------

local _include_list = {
    "BHElib.const",  -- defines some constant values
    "BHElib.status",

    "BHElib.screen_capture",
    "BHElib.input",
    "BHElib.coordinates_and_screen",

    "BHElib.global_assets",  -- loads some assets globally

    "BHElib.game_object",
    "BHElib.task",

    "BHElib.stage",
    "BHElib.stage_group",

    "BHElib.global",  -- defines some in-game global variables
    "BHElib.corefunc",
    "BHElib.after_load",
}

local function BHElibInit()
    for _, file_path in ipairs(_include_list) do
        require(file_path)
    end

    require("BHElib.coordinates_and_screen").initGameCoordinates()  -- setup the render coordinates
end
BHElibInit()