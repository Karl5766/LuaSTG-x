---------------------------------------------------------------------------------------------------
---stage.lua
---author: Karl
---date: 2021.2.12
---references: -x/src/core/stage.lua, -x/src/core/corefunc.lua
---desc: Defines the Stage class.
---------------------------------------------------------------------------------------------------

---@class Stage
---@comment an instance of this class represents a shmup stage.
Stage = {
    init = function(self) end
}

---@comment an array of all stages created by Stage.new().
Stage.all_stages = {}

---metatable for Stage.new
Stage.mt = { __index = Stage }

---------------------------------------------------------------------------------------------------

---create and return a new stage object
---@param sid string a string that should be unique to each stage
---@param display_name string for displaying the name of the stage
---@param init function function called at the start of the stage
---@return Stage a stage object
function Stage.new(sid, display_name, init)
    local self = {}
    setmetatable(self, Stage.mt)

    self.sid = sid
    self.display_name = display_name
    self.init = init

    return self
end

---@return table an array of all stages created by Stage.new()
function Stage.getAll()
    return Stage.all_stages
end

---------------------------------------------------------------------------------------------------

---Initialize the stage each playthrough
function Stage.enter(self)
    self.timer = 0
    self:init()
end

local TestClass = Class(Object, Object)
TestClass.frame = task.Do

local _glv = cc.Director:getInstance():getOpenGLView()
local _scr_metrics = require("setting.screen_metrics")
local input = require("BHElib.input.input_and_replay")

function TestClass:init()
    local scr = require("BHElib.coordinates_and_screen")
    task.New(self, function()
        task.Wait(60)
        for i = 1, 10000000 do
            local w, h = 192 + 96 * sin(i), 224 + 112 * cos(i)
            scr.setPlayFieldBoundary(-w, w, -h, h)
            scr.setOutOfBoundDeletionBoundary(-w - 30, w + 30, -h - 30, h + 30)
            task.Wait(1)
        end
    end)
end
RegisterGameClass(TestClass)

function Stage.update(self, dt)
    self.timer = self.timer + dt

    if self.timer > 1.5 and self.timer < 2.5 then
        local obj = New(TestClass)
        obj.img = "test:image"
    end

    input.refreshDevices(2)
    if input.isAnyDeviceKeyDown("down") then
        for _=1, 9 do
            if ran:Float(0, 1) > 0 then
                local obj = New(Object)
                obj.img = "test:image"
                obj.vx = ran:Float(-4, 4)
                obj.vy = ran:Float(-4, 4)
            end
        end
    end
end

local hud_painter = require("BHElib.ui.hud")
function Stage.render(self)
    hud_painter.draw(
            "image:menu_hud_background",
            1.3,
            "font:hud_default",
            "image:white"
    )
end