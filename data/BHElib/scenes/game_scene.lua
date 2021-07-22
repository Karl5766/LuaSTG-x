---------------------------------------------------------------------------------------------------
---game_scene.lua
---author: Karl
---date: 2021.3.4
---references: -x/src/core/corefunc.lua, -x/src/app/views/GameScene.lua
---desc: Defines the GameScene class. A base class for all in-game scenes
---------------------------------------------------------------------------------------------------

---@class GameScene
local GameScene = LuaClass("scenes.GameScene")

local _raw_input = require("setting.key_mapping")
local _input = require("BHElib.input.input_and_recording")
local Prefab = require("core.prefab")
local Director = cc.Director:getInstance()

---------------------------------------------------------------------------------------------------
---cache variables and functions

local floor = math.floor

---------------------------------------------------------------------------------------------------

---GameScene object constructor
---@return GameScene a GameScene object
function GameScene.__create()
    local self = {
        timer = 0,
        -- for varying playback speed in replay mode
        playback_speed = 1,
        playback_timer = 0,
        continue_scene = true,
    }
    return self
end

local SceneTransition = require("BHElib.scenes.scene_transition")

---create a scene for replacing the currently running scene;
---the new scene should be scheduled for update before returning the scene;
---
---the idea is to reuse frameFunc and renderFunc for all game scenes, but allow update and render
---methods to be defined in the sub-classes
---@return cc.Scene a new cocos scene
function GameScene:createScene()
    local scene = display.newScene("Scene")

    -- create an object for rendering the stage
    local Renderer = require("BHElib.ui.renderer")
    New(Renderer, LAYER_HUD, self, "ui")

    self.cocos_scene = scene

    -- schedule update so this function is executed every frame after the scene is pushed to
    -- cc director
    local main_loop_function = function(dt)
        -- put this here so on the frame of transition
        -- 1) objects created in the next scene will not be rendered before they are updated at least once
        -- 2) objects in the previous scene will be rendered before GameScene:cleanup() is called (after which their states become not render-able)
        -- 3) somehow the engine breaks if ResetPool is followed by director:replaceScene in the same frame, so replacing scene has to be put here
        SceneTransition.update()

        if not SceneTransition.sceneReplacedInCurrentUpdate() then
            self:doUpdatesBetweenRender(dt)

            self:gameRender()
        end
    end

    scene:scheduleUpdateWithPriorityLua(main_loop_function, 0)

    return scene
end

---for game scene transition;
---cleanup before exiting the scene; overwritten in case anything is changed during the scene of
---subclasses
function GameScene:cleanup()
    -- at the end of menu or stages, clean all objects created by this scene
    ResetPool() -- clear all game objects

    self.continue_scene = false
end

---set the current replay playback speed
---@param speed_coeff number playback_speed multiplier; default as 1
function GameScene:setPlaybackSpeed(speed_coeff)
    self.playback_speed = speed_coeff
end

---add touch key to the current scene
function GameScene:addTouchKeyToScene()
    local scene = self.cocos_scene
    local ui_layer = cc.Layer:create()
    ui_layer:setAnchorPoint(0, 0)
    scene:addChild(ui_layer)
    require('platform.controller_ui')(ui_layer)
end

local profiler = profiler

---for cocos scheduler;
---can be overridden in subclasses
---@param dt number time step (currently not very useful)
function GameScene:update(dt)
    task.PropagateDo(self)

    self.timer = self.timer + dt
end

---for cocos scheduler;
---can be overridden in subclasses
---@param dt number time step (currently not very useful)
function GameScene:render()
end

---dispatch "onUserInputUpdate" event; overridden in Stage class for replay input update
function GameScene:updateUserInput()
    _input:updateInputSnapshot()  -- only update non-replay input
    lstg.eventDispatcher:dispatchEvent("onUserInputUpdate")
end

---------------------------------------------------------------------------------------------------
---frame update

---update objects and call the scene update() function;
---advance the time by 1 frame
---can be re-written in sub-classes
function GameScene:updateSceneAndObjects(dt)
    UpdateObjList()
    self:updateUserInput()

    profiler.tic('ObjFrame')
    ObjFrame()--LPOOL.DoFrame() 执行对象的Frame函数
    profiler.toc('ObjFrame')

    -- update current scene
    self:update(1)

    profiler.tic('UserSystemOperation')
    UserSystemOperation()  --用于lua层模拟内核级操作
    profiler.toc('UserSystemOperation')

    BoundCheck()--执行边界检查

    profiler.tic('CollisionCheck')
    --碰撞检查
    CollisionCheck(GROUP_PLAYER, GROUP_ENEMY_BULLET)
    CollisionCheck(GROUP_PLAYER, GROUP_ENEMY)
    CollisionCheck(GROUP_PLAYER, GROUP_INDES)
    CollisionCheck(GROUP_ENEMY, GROUP_PLAYER_BULLET)
    CollisionCheck(GROUP_ITEM, GROUP_PLAYER)
    profiler.toc('CollisionCheck')

    profiler.tic('UpdateXY')
    UpdateXY()--更新对象的XY坐标偏移量
    profiler.toc('UpdateXY')

    profiler.tic('AfterFrame')
    AfterFrame()--帧末更新函数
    profiler.toc('AfterFrame')
end

---update the game by one time step;
---advance the time by 1 frame
---@return boolean true if the current scene has ended
function GameScene:frameUpdate(dt)
    self:updateSceneAndObjects(dt)
end

local e = lstg.eventDispatcher
local _process_one_task = async.processOneTask

---@~chinese 将被每帧调用以执行帧逻辑。返回`true`时会使游戏退出。
---
---@~english Will be invoked every frame to process all frame logic. Game will exit if it returns `true`.
---
function GameScene:doUpdatesBetweenRender(dt)
    profiler.tic('FrameFunc')
    if _raw_input:isAnyDeviceKeyDown("snapshot") and setting.allowsnapshot then
        Screenshot()
    end
    _process_one_task()  -- async load of resources etc.

    e:dispatchEvent('onFrameFunc')  -- in case any event is registered

    -- update game state k times, k depending on the value given by
    -- (setting.render_skip + 1) * self.playback_speed
    local factor = self.playback_speed
    if setting.render_skip then
        factor = factor * (int(setting.render_skip) + 1)
    end
    local cur_playback_timer = self.playback_timer + factor
    for _ = 1, floor(cur_playback_timer) - floor(self.playback_timer) do
        -- currently multiple updates do not wait at all
        if self.continue_scene then
            self:frameUpdate(dt)
        end
    end
    self.playback_timer = cur_playback_timer

    if lstg.quit_flag then
        GameExit()
    end

    profiler.toc('FrameFunc')
end

---------------------------------------------------------------------------------------------------
---frame render

local coordinates = require("BHElib.coordinates_and_screen")

---@~chinese 将被每帧调用以执行渲染指令。
---
---@~english Will be invoked every frame to process all render instructions.
---
function GameScene:gameRender()
    -- begin scene
    profiler.tic('RenderFunc')

    -- all render should be done between BeginScene and EndScene
    BeginScene()

    -- before render calls
    coordinates.setRenderView("ui")
    e:dispatchEvent('onBeforeRender')

    coordinates.setRenderView("game")
    profiler.tic('ObjRender')
    ObjRender()
    profiler.toc('ObjRender')

    -- after render calls
    e:dispatchEvent('onAfterRender')

    -- end scene
    e:dispatchEvent('beforeEndScene')
    EndScene()
    e:dispatchEvent('afterEndScene')

    ProcessCapturedScreens()

    profiler.toc('RenderFunc')
end


return GameScene