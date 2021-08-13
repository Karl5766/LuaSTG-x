---------------------------------------------------------------------------------------------------
---game_scene_transition.lua
---author: Karl
---date: 2021.3.27
---desc: implements scene transition; coordinates cocos scene creation and visual effects that comes
---     before or after a scene transition
---------------------------------------------------------------------------------------------------

---@class SceneTransition
local M = {
    task = {},  -- use task to
}

local _scene = nil  -- the scene to transition from
local _replace_flag = false  -- set to true on the frame the next scene starts

---------------------------------------------------------------------------------------------------
---go to next scene

local director = cc.Director:getInstance()

---cleanup the current scene;
---let the current scene create the next scene;
---and call cocos director's replaceScene() to replace the next scene with the current scene
---@return GameScene a new game scene created by scene from
local function GoToNextScene()
    SystemLog("GoToNextScene called!!!!!!!!!!!!!!!!!!!!!")
    -- start the next scene

    local scene_to = _scene:createNextAndCleanupCurrentScene()

    if scene_to == nil then -- no scene to go to; end the current scene and quit the game in this case
        -- create an empty scene as dummy scene
        local GameScene = require("BHElib.scenes.game_scene")
        scene_to = GameScene()

        -- set quit flag as true
        lstg.quit_flag = true
    end
    local cocos_scene = scene_to:createScene()
    assert(cocos_scene, "Error: Cocos scene expected, got nil!")
    director:replaceScene(cocos_scene)
end

---------------------------------------------------------------------------------------------------

---setup scene transition to be executed at the start of the next frame;
---@param scene_from GameScene the current game scene
function M.transitionAtStartOfNextFrame(scene_from)
    assert(scene_from, "Error: Invalid transition parameter, the given current scene is nil!")
    _scene = scene_from
end

---@return boolean true if the transition is ready to be carried out at the start of next frame
function M.isTransitionReady()
    return _scene ~= nil
end

function M.updateAtStartOfFrame()
    if _scene ~= nil then
        GoToNextScene()
        _scene = nil
        _replace_flag = true
    else
        _replace_flag = false
    end
end

function M.sceneReplacedInPreviousUpdate()
    return _replace_flag
end

return M