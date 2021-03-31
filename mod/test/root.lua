---------------------------------------------------------------------------------------------------
---temporary use

local _replay_path_for_write = "replay/current"
local _replay_path_for_read = "replay/read"

---setup the default scene group init state to run the scene group with when the player select start game
local function SetupStartGameInitState()
    local Menu = require("BHElib.scenes.menu.menu_scene")
    local SceneGroupInitState = require("BHElib.scenes.stage.state_of_group_init")

    local is_replay = false

    -- create init states for stage and the scene group
    local group_init_state = SceneGroupInitState()
    group_init_state.scene_id_array = {"sample_stage"}  -- start at sample_stage
    group_init_state.is_replay = is_replay

    Menu.setStartGameInitState(group_init_state)
end

local function SetupReplayFilePath()
    local Menu = require("BHElib.scenes.menu.menu_scene")

    Menu.setReplayFilePath(_replay_path_for_read, _replay_path_for_write)
end

---------------------------------------------------------------------------------------------------
---init

local function Init()
    -- initialize the entire library, which will return the starting menu
    local menu = require("BHElib_init")

    SetupStartGameInitState()
    SetupReplayFilePath()

    return menu
end

return Init()