---------------------------------------------------------------------------------------------------
---stage.lua
---author: Karl
---date: 2021.2.12
---references: -x/src/core/stage.lua, -x/src/core/corefunc.lua, -x/src/app/views/GameScene.lua
---desc: Defines the Stage class; every subclass of Stage represents a unique stage, and every
---     instance of them represent a playthrough
---------------------------------------------------------------------------------------------------

local GameScene = require("BHElib.scenes.game_scene")  -- superclass

---@class Stage
---@comment an instance of this class represents a shmup stage.
local Stage = LuaClass("scenes.Stage", GameScene)

---@comment an array of all stages created by Stage.new().
local _all_stages = {}

---------------------------------------------------------------------------------------------------
---virtual methods

---create a scene for replacing the currently running scene;
---the new scene should be scheduled for update before returning the scene
---@return cc.Scene Created new cocos scene on the entry of the game scene
---virtual Stage:createScene(...)

---cleanup before exiting the scene
---virtual Stage:cleanup()

---virtual Stage:getSceneType()

---return the stage id
---@return string unique string that identifies the stage
---virtual Stage:getSid()

---virtual Stage:getDisplayName()

---------------------------------------------------------------------------------------------------
---class method

---create and return a new stage instance, representing an actual playthrough
---@param sid string a string that should be unique to each stage
---@param display_name string for displaying the name of the stage
---@return Stage a stage object
function Stage.__create(game_init_params)
    local self = {}

    self.game_init_params = game_init_params
    self.timer = 0

    return self
end

---@return table an array of all stages created by Stage.new()
function Stage.getAll()
    return _all_stages
end

function Stage.addStageClass(stage)
    table.insert(_all_stages, stage)
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