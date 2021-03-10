---------------------------------------------------------------------------------------------------
---stage.lua
---author: Karl
---date: 2021.2.12
---references: -x/src/core/stage.lua, -x/src/core/corefunc.lua, -x/src/app/views/GameScene.lua
---desc: Defines the Stage class; every subclass of Stage represents a unique stage, and every
---     instance of them represent a playthrough
---------------------------------------------------------------------------------------------------

local GameScene = require("BHElib.scenes.game_scene")  -- superclass

---@class Stage:GameScene
---@comment an instance of this class represents a shmup stage.
local Stage = LuaClass("scenes.Stage", GameScene)

---@comment an array of all stages created by Stage.new().
local _all_stages = {}

---------------------------------------------------------------------------------------------------
---virtual methods

---for game scene transition;
---cleanup before exiting the scene; overwritten in case anything is changed during the scene of
---subclasses
---virtual Stage:cleanup()

---return the stage id
---@return string unique string that identifies the stage
---virtual Stage:getSid()

---virtual Stage:getDisplayName()

---------------------------------------------------------------------------------------------------
---class method

---create and return a new stage instance, representing an actual play-through;
---the init state parameters will be treated as immutable
---@param scene_init_state GameSceneInitState specifies the initial state of the scene
---@param scene_group_init_state table a table containing the global state of the play-through
---@param global_state table used to pass information among stages in a play-through
---@return Stage a stage object
function Stage.__create(scene_group_init_state, scene_init_state, global_state)
    local self = GameScene.__create()

    self.timer = 0

    self.scene_group_init_state = scene_group_init_state
    self.scene_init_state = scene_init_state
    self.global_state = global_state

    return self
end

---@return table an array of all stages created by Stage.new()
function Stage.getAll()
    return _all_stages
end

---register the stage for look up
---@param stage Stage a class derived from Stage to register
function Stage.registerStageClass(stage)
    table.insert(_all_stages, stage)
end

---@param id string the id to look for
---@return Stage a class derived from Stage with the given id; if not found, return nil
function Stage.findStageClassById(id)
    for i = 1, #_all_stages do
        if _all_stages[i]:getSid() == id then
            return _all_stages[i]
        end
    end
end

---@return string scene type
function Stage.getSceneType()
    return "stage"
end

---------------------------------------------------------------------------------------------------
---instance method

---@return cc.Scene a new cocos scene
function Stage.createScene(self)
    ---@type GameSceneInitState
    local scene_init_state = self.scene_init_state

    -- set random seed
    ran:Seed(scene_init_state.random_seed)

    -- init score
    self.score = scene_init_state.init_score

    ---TOBEADDED: initialize the player



    return GameScene.createScene(self)
end

---construct the initialization parameters for the next scene
---@return GameSceneInitState, SceneGroupInitState, table init parameters for Stage.__create
function Stage.constructNextSceneInitState(self)
    local GameSceneInitState = require("BHElib.scenes.stage.game_scene_init_state")
    local cur_init_state = self.scene_init_state
    local next_init_state = GameSceneInitState()

    next_init_state.random_seed = cur_init_state.random_seed
    next_init_state.score = self.score
    ---TOBEADDED: initialize player info as well

    -- update global state
    self.global_state:advanceScene(cur_init_state)

    return self.scene_group_init_state, next_init_state, self.global_state
end

function Stage.isInReplay(self)
    return self.global_state.is_replay
end

---ends the play-through and go back to menu
function Stage.completeSceneGroup(self)
    local Menu = require("BHElib.scenes.menu.menu_scene")
    local SceneTransition = require("BHElib.scenes.scene_transition")

    local task_spec = {"no_task"}

    SceneTransition.transitionTo(self, Menu(task_spec))
end

---update the stage itself
function Stage.update(self, dt)
    GameScene.update(self, dt)
    self.timer = self.timer + dt
end

local hud_painter = require("BHElib.ui.hud")
---render stage hud
function Stage.render(self)
    GameScene.render(self)
    hud_painter.draw(
            "image:menu_hud_background",
            1.3,
            "font:hud_default",
            "image:white"
    )
end

return Stage