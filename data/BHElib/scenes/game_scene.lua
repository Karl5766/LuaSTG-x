---------------------------------------------------------------------------------------------------
---game_scene.lua
---author: Karl
---date: 2021.3.4
---references: -x/src/core/corefunc.lua, -x/src/app/views/GameScene.lua
---desc: Defines the GameScene class. A base class for all in-game scenes
---------------------------------------------------------------------------------------------------

---@class GameScene
local GameScene = LuaClass("scenes.GameScene")

---------------------------------------------------------------------------------------------------
---virtual methods

---for game scene transition;
---cleanup before exiting the scene; overwritten in case anything is changed during the scene of
---subclasses
---virtual Stage:cleanup()

---virtual GameScene:getSceneType()

---------------------------------------------------------------------------------------------------

---GameScene object constructor
---@return GameScene a GameScene object
function GameScene.__create()
    return {}
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

    -- schedule update so this function is executed every frame after the scene is pushed to
    -- cc director
    scene:scheduleUpdateWithPriorityLua(function(dt)
        self:frameFunc(dt)

        self:renderFunc()
    end, 0)

    self.cocos_scene = scene

    return scene
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
end

---for cocos scheduler;
---can be overridden in subclasses
---@param dt number time step (currently not very useful)
function GameScene:render()
end

---dispatch "onUserInputUpdate" event; overridden in Stage class for replay input update
function GameScene:updateUserInput()
    lstg.eventDispatcher:dispatchEvent("onUserInputUpdate")
end

---------------------------------------------------------------------------------------------------
---frame update

---update game state 1 time
function GameScene:doOneFrame()
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
    CollisionCheck(GROUP_NONTJT, GROUP_PLAYER_BULLET)
    CollisionCheck(GROUP_ITEM, GROUP_PLAYER)
    profiler.toc('CollisionCheck')

    profiler.tic('UpdateXY')
    UpdateXY()--更新对象的XY坐标偏移量
    profiler.toc('UpdateXY')

    profiler.tic('AfterFrame')
    AfterFrame()--帧末更新函数
    profiler.toc('AfterFrame')

    -- it is possible that after transition is set, some new objects are created before the update completes
    -- so wait until the end of loop to replace the current scene with the next scene
    -- also for some reasons the game crashes if ResetPool is put *after* ObjRender in the current frame
    if SceneTransition.isNextScenePrepared() then
        SceneTransition.goToNextScene()
    end
end

---update game state k times, k depending on the value given by
---setting.render_skip + 1
function GameScene:doFrames()
    local factor = 1
    if setting.render_skip then
        factor = int(setting.render_skip) + 1
    end
    for _ = 1, factor do
        self:doOneFrame()
    end
end

local e = lstg.eventDispatcher
local _input = require("BHElib.input.input_and_replay")
local _process_one_task = async.processOneTask

---@~chinese 将被每帧调用以执行帧逻辑。返回`true`时会使游戏退出。
---
---@~english Will be invoked every frame to process all frame logic. Game will exit if it returns `true`.
---
function GameScene:frameFunc()
    profiler.tic('FrameFunc')
    -- -1
    if _input.isAnyDeviceKeyDown("snapshot") and setting.allowsnapshot then
        Screenshot()
    end
    _process_one_task()

    -- 0
    e:dispatchEvent('onFrameFunc')  -- in case any event is registered
    self:doFrames()  -- update the game

    -- 9
    if lstg.quit_flag then
        GameExit()
    end
    profiler.toc('FrameFunc')
    return lstg.quit_flag
end

---------------------------------------------------------------------------------------------------
---frame render

local coordinates = require("BHElib.coordinates_and_screen")

---@~chinese 将被每帧调用以执行渲染指令。
---
---@~english Will be invoked every frame to process all render instructions.
---
function GameScene:renderFunc()
    -- begin scene
    profiler.tic('RenderFunc')

    -- all render should be done between BeginScene and EndScene
    BeginScene()

    -- before render calls
    coordinates.setRenderView("ui")
    e:dispatchEvent('onBeforeRender')

    -- render calls
    self:render()

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