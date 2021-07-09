---------------------------------------------------------------------------------------------------
---temporary use

---setup the default scene group init state to run the scene group with when the player select start game
local function SetupGroupInitState()
    local Menu = require("BHElib.scenes.main_menu.main_menu_scene")
    local SceneGroupInitState = require("BHElib.scenes.stage.state_of_group_init")

    local is_replay = false

    -- create init states for stage and the scene group
    local group_init_state = SceneGroupInitState()
    group_init_state.player_class_id = "units.player.reimu"

    group_init_state.scene_id_array = {
        "stage.StageLab"
        --"stage.SampleStage",
        --"stage.SecondSampleStage"
    }
    group_init_state.is_replay = is_replay

    Menu.setStartGameInitState(group_init_state)
end

---------------------------------------------------------------------------------------------------
---init

local function CreateMenu()
    -- create menu and return it
    local Menu = require("BHElib.scenes.main_menu.main_menu_scene")
    return Menu.shortInit({"no_task"})
end

local function Init()
    ---zip replay test
    --local FU = cc.FileUtils:getInstance()
    ---local zip_path = FU:getFullPathForFileName("replay/read.zip")
    --local zip_path = "replay/read"
    --local zip = lstg.ZipArchive:create(zip_path)
    --if not zipW then
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
    require("BHElib.coordinates_and_screen").initGameCoordinates()  -- setup the coordinates
    require("BHElib.input.input_and_recording"):init()  -- initialize player input

    -- initialize the entire library
    require("BHElib_init")

    -- initialize units
    require("BHElib.units.enemy_bullet.bullet_types"):init()  -- load resources & init local variables

    -- initialize all stage classes
    require("scenes.game_stage_sample")
    require("scenes.game_stage_second_sample")
    require("scenes.stage_lab")

    -- initialize all player classes
    require("player.reimu.reimu")

    local Prefab = require("BHElib.prefab")
    local SceneTransition = require("BHElib.scenes.scene_transition")

    require("BHElib.coordinates_and_screen").setResolution(1600, 900)

    -- register object classes
    Prefab.RegisterAllDefinedPrefabs()

    -- create the menu
    SetupGroupInitState()
    local menu = CreateMenu()
    SceneTransition.init(menu)  -- initialize scene transition
    return menu:createScene()
end

return Init()