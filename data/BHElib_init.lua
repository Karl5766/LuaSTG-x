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

    -- input
    "BHElib.input.input_and_replay",

    "BHElib.screen_capture",
    "BHElib.coordinates_and_screen",

    "BHElib.global_assets",  -- loads some assets globally

    "BHElib.game_object",
    "BHElib.task",

    "BHElib.global",  -- defines some in-game global variables
    "BHElib.corefunc",
    "BHElib.after_load",
}

local function BHElibInit()

    -- zip replay test
    --local FU = cc.FileUtils:getInstance()
    ----local zip_path = FU:getFullPathForFileName("replay/read.zip")
    --local zip_path = "replay/read"
    --local zip = lstg.ZipArchive:create(zip_path)
    --if not zip then
    --    error(('failed to create zip file %q'):format(zip_path))
    --end
    --if not zip:open(lstg.ZipArchive.OpenMode.NEW) then
    --    zip:unlink()
    --    error(('failed to open zip file %q'):format(zip_path))
    --end
    --local entries = {{"read.rep", "replay/read.rep"}}
    --for i, v in ipairs(entries) do
    --    if not zip:addFile(v[1], v[2]) then
    --        zip:unlink()
    --        error(('failed add entry %q to zip file'):format(v[1]))
    --    end
    --end
    --zip:close()

    for _, file_path in ipairs(_include_list) do
        require(file_path)
    end

    require("BHElib.coordinates_and_screen").initGameCoordinates()  -- setup the coordinates
    require("BHElib.input.input_and_replay").init()  -- initialize player input

    -- create menu and return its cocos scene
    local MenuClass = require("BHElib.scenes.menu.menu_scene")
    local menu = MenuClass({"no_task"})
    return menu:createScene()
end

return BHElibInit()