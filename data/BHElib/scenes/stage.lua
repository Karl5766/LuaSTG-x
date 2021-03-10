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

---create and return a new stage instance, representing an actual playthrough
---@param game_init_state table specifies the initial state of the next scene
---@return Stage a stage object
function Stage.__create(game_init_state)
    local self = GameScene.__create()

    self.game_init_state = game_init_state
    self.timer = 0

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
---@return Stage a class derived from Stage with the given id
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

function Stage.update(self, dt)
    GameScene.update(self, dt)
    self.timer = self.timer + dt
end

local hud_painter = require("BHElib.ui.hud")
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