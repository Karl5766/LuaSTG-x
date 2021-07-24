---------------------------------------------------------------------------------------------------
---dialogue_session.lua
---author: Karl
---date created: 2021.7.23
---desc: Defines the in-game dialogue
---------------------------------------------------------------------------------------------------

---@class DialogueSession
local M = LuaClass("session.Dialogue")

local Renderer = require("BHElib.ui.renderer_prefab")

---------------------------------------------------------------------------------------------------

---@param player_input InputManager
---@param dialogue_text_object ui.TextObject
---@param callback function receives first parameter the dialogue session object and handles the dialogue
function M.__create(player_input, dialogue_text_object, callback)
    local self = {}

    self.portraits = {}  -- a map from portrait id to portraits; includes all existing portrait
    self.portrait_renderers = {}  -- renderer for each portrait

    -- below attributes handles the control flow of the dialogue (when to advance etc.)
    self.player_input = player_input
    self.proceed_flag = true
    self.text_object = dialogue_text_object
    local function StartDialogue()
        callback(self)
    end
    self.script = coroutine.create(StartDialogue)

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
    -- delete all renderers, so no dangling object remains
    Del(self.renderer)
    for pid, renderer in pairs(self.portrait_renderers) do
        Del(renderer)
    end
end

---@return boolean whether the session is to be continued in the next frame
function M:continueSession()
    return IsValid(self.renderer)
end

---------------------------------------------------------------------------------------------------
---update

function M:update(dt)
    if self.proceed_flag then
        -- run the task

        if coroutine.status(self.script) == "dead" then
            self:endSession()
        else
            local success, errmsg = coroutine.resume(self.script)
            if errmsg then
                error(errmsg)
            end
            self.proceed_flag = false
        end
    end

    self:processInput()

    for id, portrait in pairs(self.portraits) do
        portrait:update(dt)
    end
end

function M:processInput()
    ---@type InputManager
    local input = self.player_input
    if not self.proceed_flag then
        if input:isAnyDeviceKeyJustChanged("shoot", true, true) then
            self.proceed_flag = true
        end
    end
end

local Coordinates = require("BHElib.coordinates_and_screen")
function M:render()
    local image = "image:white"
    SetImageState(image, "", Color(255, 255, 200, 200))
    Render(image, 0, -145, 0, 5, 2, 0)
    self.text_object:render(-160, -100)
end

return M