---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Karl2.
--- DateTime: 2021/7/24 0:13
---

local Dialogue = require("BHElib.units.boss.dialogue_session")
local TextObject = require("BHElib.ui.text_object")
local Portrait = require("BHElib.units.boss.dialogue_portrait")
local Vec2 = math.vec2

local M = LuaClass("Nue.dialogue", Dialogue)

---@param dialogue DialogueSession
local function MainScript(dialogue)
    local Nue = Portrait(
            "image:nue_ball",
            Color(255, 255, 255, 255),
            Vec2(0, 0),
            Color(150, 255, 255, 255),
            Vec2(-100, -30),
            true)
    local Nue2 = Portrait(
            "image:nue_ball",
            Color(255, 255, 100, 100),
            Vec2(100, 0),
            Color(255, 255, 100, 100),
            Vec2(100, -30),
            true)
    dialogue:addPortrait(Nue, "Nue")
    dialogue:say("hello?", "Nue")
    coroutine.yield()
    dialogue:say("I am nue ball # 1", nil)
    coroutine.yield()
    dialogue:say("reappear", "Nue")
    coroutine.yield()
    dialogue:say("change to same state", "Nue")
    coroutine.yield()
    --dialogue:addPortrait(Nue2, "Nue2")
    --coroutine.yield()
    --for i = 1, 30 do
    --    dialogue:say(
    --            "multiple lines:"..i,
    --            ({"Nue", "Nue2"})[ran:Int(1, 2)])
    --    coroutine.yield()
    --end
end

function M.__create()
    return Dialogue.__create(
            require("BHElib.input.input_and_recording"),
            TextObject("", Color(255, 255, 255, 255), "font:test", 40, {"left", "top"}),
            MainScript
    )
end

return M