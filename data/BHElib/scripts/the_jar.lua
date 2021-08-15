---------------------------------------------------------------------------------------------------
---author: Karl
---date created: 2021.8.13
---desc: Defines some global variables for scripting; note since this file will modify functions of
---     other files, it needs to be required before those functions are executed; on the other
---     hand, avoid including this file except before you are scripting the levels, as these global
---     variables are not designed for good readability or easy modification, but fast scripting
---------------------------------------------------------------------------------------------------

local GameScene = require("BHElib.scenes.game_scene")
local Stage = require("BHElib.scenes.stage.stage")
local SingleBossSesssion = require("BHElib.sessions.boss.single_boss_session")

---------------------------------------------------------------------------------------------------
---in a game scene

---@type GameScene
stage = nil

local GameSceneCreateScene = GameScene.createScene
---create a scene for replacing the currently running scene;
---the new scene should be scheduled for update before returning the scene;
---
---the idea is to reuse frameFunc and renderFunc for all game scenes, but allow update and render
---methods to be defined in the sub-classes
---@return cc.Scene a new cocos scene
function GameScene:createScene()
    local cocos_scene = GameSceneCreateScene(self)
    stage = self
    return cocos_scene
end

---------------------------------------------------------------------------------------------------
---in a stage

---@type Prefab.Player
player = nil
---@type gameplay_resources.Player
player_resource = nil
---@type number
difficulty = nil

local StageSetPlayer = Stage.setPlayer
---@param player Prefab.Player the player of this stage
function Stage:setPlayer(player)
    StageSetPlayer(self, player)
    _G.player = player
    player_resource = player:getPlayerResource()  -- assuming this reference will be valid throughout the lifetime of player
end

local StageCreateScene = Stage.createScene
function Stage:createScene()
    local cocos_scene = StageCreateScene(self)
    difficulty = self:getDifficulty()  -- assume unchanged throughout stage
    return cocos_scene
end

---------------------------------------------------------------------------------------------------
---in a boss session

---@type Prefab.Animation
boss = nil

local SingleBossSesssionCtor = SingleBossSesssion.ctor
function SingleBossSesssion:ctor()
    boss = self.boss
    SingleBossSesssionCtor(self)
end