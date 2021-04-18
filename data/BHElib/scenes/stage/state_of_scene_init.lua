---------------------------------------------------------------------------------------------------
---state_of_scene_init.lua
---author: Karl
---date: 2021.3.10
---desc: Defines the GameSceneInitState object, which is created and used for initialization of
---     the initial state of a level.
---modifier:
---------------------------------------------------------------------------------------------------

---@class GameSceneInitState
local InitState = LuaClass("scenes.GameSceneInitState")

local PlayerClass = require("BHElib.units.player.player_class")
local _player_const = PlayerClass.const

---create and return a default init state
---the attributes of an object of this class should not be modified more than once,
---except for initialization immediately following creating the object
function InitState.__create()
    local self = {}
    self.random_seed = 0
    self.player_init_state = {
        x = _player_const.spawn_x,
        y = _player_const.spawn_y,
        num_life = 1,
        num_bomb = 1,
    }
    self.init_score = 0

    return self
end

---------------------------------------------------------------------------------------------------
---save to/load from file

local _player_init_state_float_fields = {
    "x",
    "y",
    "num_life",
    "num_bomb",
}
local _player_init_state_string_fields = {}

---manages saving the object to file at the current file cursor position
---@param file_writer SequentialFileWriter the object for writing to file
function InitState:writeToFile(file_writer)
    file_writer:writeUInt(self.random_seed)
    file_writer:writeUInt(self.init_score)

    file_writer:writeFieldsOfTable(self.player_init_state, _player_init_state_float_fields, _player_init_state_string_fields)
end

---manages reading the object from file at the current file cursor position
---@param file_reader SequentialFileReader the object for reading from file
function InitState:readFromFile(file_reader)
    self.random_seed = file_reader:readUInt()
    self.init_score = file_reader:readUInt()

    file_reader:readFieldsOfTable(self.player_init_state, _player_init_state_float_fields, _player_init_state_string_fields)
end

return InitState