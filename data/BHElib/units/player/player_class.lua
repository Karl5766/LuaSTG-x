---------------------------------------------------------------------------------------------------
---player_class.lua
---date: 2021.4.12
---desc: This file defines the player class, from which all player sub-classes derive from
---------------------------------------------------------------------------------------------------

local Prefab = require("prefab")

local PlayerClass = Prefab.NewX(Prefab.Object)

local Input = require("BHElib.input.input_and_recording")

---------------------------------------------------------------------------------------------------
---cache variables and functions

---------------------------------------------------------------------------------------------------
---input

---@param PlayerInput InputManager
function PlayerClass:processUserInput(PlayerInput)
    self:processMovementInput(PlayerInput)
end

---@param PlayerInput InputManager
function PlayerClass:processMovementInput(PlayerInput)
    -- 2d movement limited in 8 directions

    local dx = 0
    local dy = 0
    if PlayerInput:isAnyRecordedKeyDown("down") then
        dy = -1
    elseif PlayerInput:isAnyRecordedKeyDown("up") then
        dy = 1
    end
    if PlayerInput:isAnyRecordedKeyDown("left") then
        dx = -1
    elseif PlayerInput:isAnyRecordedKeyDown("right") then
        dx = 1
    end

end

Prefab.Register(PlayerClass)

return PlayerClass