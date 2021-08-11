---------------------------------------------------------------------------------------------------
---dialogue_session.lua
---author: Karl
---date created: 2021.7.23
---desc: Defines the in-game dialogue
---------------------------------------------------------------------------------------------------

local Session = require("BHElib.sessions.session")
local ScriptableSession = require("BHElib.sessions.scriptable_session")

---@class DialogueSession:ScriptableSession
local M = LuaClass("session.Dialogue", ScriptableSession)

local Renderer = require("BHElib.ui.renderer_prefab")

---------------------------------------------------------------------------------------------------

M.DEBUG_DISPLAY_NAME = "dialogue_session"

---@param stage Stage the stage this dialogue takes place
---@param player_input InputManager
---@param dialogue_text_object ui.TextObject
---@param script function a coroutine function that takes self as first parameter
function M.__create(stage, player_input, dialogue_text_object, script)
    local self = ScriptableSession.__create(stage, script)

    self.portraits = {}  -- a map from portrait id to portraits; includes all existing portrait
    self.portrait_renderers = {}  -- renderer for each portrait

    -- below attributes handles the control flow of the dialogue (when to advance etc.)
    self.player_input = player_input
    self.text_object = dialogue_text_object

    self.renderer = Renderer(LAYER_DIALOGUE_BOX, self, "game")

    return self
end

---------------------------------------------------------------------------------------------------
---modifiers and getters

---@param portrait DialoguePortrait
---@param pid string the id to refer to the portrait
function M:addPortrait(portrait, pid)
    local portraits = self.portraits
    assert(portraits[pid] == nil, "Error: Portrait id already exists!")
    portraits[pid] = portrait

    self.portrait_renderers[pid] = Renderer(LAYER_DIALOGUE_PORTRAIT, portrait, "game")
end

---@param pid string the id to refer to the portrait
---@return DialoguePortrait nil if the portrait does not exist
function M:getPortrait(pid)
    return self.portraits[pid]
end

---@return ui.TextObject
function M:getTextObject()
    return self.text_object
end

---@param pid string the id to refer to the portrait to be removed
function M:removePortrait(pid)
    local portraits = self.portraits
    assert(portraits[pid] ~= nil, "Error: Portrait does not exist!")
    portraits[pid] = nil

    local renderers = self.portrait_renderers
    Del(renderers[pid])
    renderers[pid] = nil
end

---------------------------------------------------------------------------------------------------

---@param text string the text to display
---@param speaker_pid string
function M:say(text, speaker_pid)
    self.text_object:setText(text)
    if speaker_pid then
        local speaker_portrait = self.portraits[speaker_pid]
        assert(speaker_portrait, "Error: Portrait with the given pid does not exist!")
        for id, portrait in pairs(self.portraits) do
            if portrait == speaker_portrait then
                portrait:setHighlight(true)
            else
                portrait:setHighlight(false)
            end
        end
    else
        for id, portrait in pairs(self.portraits) do
            portrait:setHighlight(false)
        end
    end
end

---------------------------------------------------------------------------------------------------

function M:endSession()
    Session.endSession(self)

    -- delete all renderers, so no dangling object remains
    Del(self.renderer)
    for pid, renderer in pairs(self.portrait_renderers) do
        Del(renderer)
    end
end

---------------------------------------------------------------------------------------------------
---update

function M:update(dt)
    Session.update(self, dt)

    local is_updated = self:updateChildren()  -- run children

    if coroutine.status(self.coroutine) == "dead" then
        self:endSession()
    else
        self:processInput()
    end

    for id, portrait in pairs(self.portraits) do
        portrait:update(dt)
    end
end

function M:processInput()
    -- resume the coroutine if player has pressed shoot key
    ---@type InputManager
    local input = self.player_input
    if input:isAnyDeviceKeyJustChanged("shoot", true, true) then
        self:resumeCoroutine()
    end
end

local Coordinates = require("BHElib.unclassified.coordinates_and_screen")
function M:render()
    local image = "image:white"
    SetImageState(image, "", Color(255, 255, 200, 200))
    Render(image, 0, -145, 0, 5, 2, 0)
    self.text_object:render(-160, -100)
end

return M