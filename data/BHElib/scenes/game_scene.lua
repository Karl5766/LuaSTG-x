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

---create a scene for replacing the currently running scene;
---the new scene should be scheduled for update before returning the scene
---@return cc.Scene Created new cocos scene
---virtual GameScene:createScene(...)

---cleanup before exiting the scene
---virtual GameScene:cleanup()

---virtual GameScene:getSceneType()

---------------------------------------------------------------------------------------------------

---add touch key to the given scene
---@param scene cc.Scene the scene to add touch screen onto
function GameScene:addTouchKeyToScene(scene)
    local ui_layer = cc.Layer:create()
    ui_layer:setAnchorPoint(0, 0)
    scene:addChild(ui_layer)
    require('platform.controller_ui')(ui_layer)
end

local profiler = profiler

---for cocos scheduler;
---can be overwrite in subclasses
---@param dt number time step (currently not very useful)
function GameScene:update(dt)
end

---for cocos scheduler;
---can be overwrite in subclasses
---@param dt number time step (currently not very useful)
function GameScene:render()
end

---------------------------------------------------------------------------------------------------
---frame update

---update game state 1 time
function GameScene:doOneFrame()
    UpdateObjList()
    GetInput()

    profiler.tic('ObjFrame')
    ObjFrame()--LPOOL.DoFrame() 执行对象的Frame函数
    profiler.toc('ObjFrame')

    -- update current stage
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