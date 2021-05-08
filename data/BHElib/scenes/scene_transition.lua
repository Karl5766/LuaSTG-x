---------------------------------------------------------------------------------------------------
---scene_transition.lua
---author: Karl
---date: 2021.3.27
---desc: implements scene transition; coordinates cocos scene creation and visual effects that comes
---     before or after a scene transition
---------------------------------------------------------------------------------------------------

---@class SceneTransition
local M = {
    task = {},  -- use task to
}

---set to true on the frame the next scene starts
local _scene_from

---------------------------------------------------------------------------------------------------
---cache variables and functions

local TaskNew = task.New
local TaskDo = task.Do

---------------------------------------------------------------------------------------------------
---init

---set the current scene as the given scene;
---should only be called for the first scene
---@param scene GameScene the scene to be set as the current scene
function M.init(scene)
    _scene_from = scene
end

---------------------------------------------------------------------------------------------------

---setup scene transition to be executed at the end of the frame;
---the transition may not be executed in this frame, depending on whether or not transition_callback wait
---@param scene_from GameScene
---@param transition_callback function(self, scene_from) create task under self that manages transition effect and waiting
function M.transitionFrom(scene_from, transition_callback)
    _scene_from = scene_from

    assert(_scene_from, "ERROR: scene transition, current scene not set!")

    transition_callback(M, scene_from)  -- create the task under M
end

---------------------------------------------------------------------------------------------------
---go to next scene

local director = cc.Director:getInstance()
---cleanup the current scene;
---let the current scene create the next scene;
---and call cocos director's replaceScene() to replace the next scene with the current scene
---@param scene_from GameScene the current game scene
---@return GameScene a new game scene created by scene from
local function GoToNextScene(scene_from)
    -- start the next scene
    local scene_to = _scene_from:createNextGameScene()

    scene_from:cleanup()  -- cleanup the scene

    if scene_to == nil then -- no scene to go to; end the current scene and quit the game in this case
        -- create an empty scene as dummy scene
        local GameScene = require("BHElib.scenes.game_scene")
        scene_to = GameScene()

        -- set quit flag as true
        lstg.quit_flag = true
    end
    local cocos_scene = scene_to:createScene()
    director:replaceScene(cocos_scene)

    _scene_from = nil
end

---------------------------------------------------------------------------------------------------

---@param self SceneTransition
---@param scene_from GameScene the current game scene
function M.instantTransition(self, scene_from)
    TaskNew(self, function()
        GoToNextScene(scene_from)
    end)
end

---------------------------------------------------------------------------------------------------
---update

---do M's tasks;
---in general, the tasks handle transition at the frame of transition, and is responsible for
---handling transition visual effect at other frames
function M.update()
    TaskDo(M)
end

return M