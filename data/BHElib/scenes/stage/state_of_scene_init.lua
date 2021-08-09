---------------------------------------------------------------------------------------------------
---state_of_scene_init.lua
---author: Karl
---date: 2021.3.10
---desc: Defines the GameSceneInitState object, which is created and used for initialization of
---     the initial state of a level.
---------------------------------------------------------------------------------------------------

---@class GameSceneInitState
local M = LuaClass("scenes.GameSceneInitState")

local PlayerResource = require("BHElib.units.player.player_resource")
local PlayerBase = require("BHElib.units.player.player_prefab")
local _player_global = PlayerBase.global

---create and return a default init state
---the attributes of an object of this class should not be modified more than once,
---except for initialization immediately following creating the object
function M.__create()
    local self = {}
    self.random_seed = 0
    self.player_pos = {
        x = _player_global.spawn_x,
        y = _player_global.spawn_y,
    }
    self.player_resource = PlayerResource()
    self.score = 0

    return self
end

---------------------------------------------------------------------------------------------------
---save to/load from file

---manages saving the object to file at the current file cursor position
---@param file_writer SequentialFileWriter the object for writing to file
function M:writeToFile(file_writer)
    file_writer:writeUInt(self.random_seed)
    file_writer:writeUInt(self.score)

    file_writer:writeDouble(self.player_pos.x)
    file_writer:writeDouble(self.player_pos.y)

    self.player_resource:writeToFile(file_writer)
end

---manages reading the object from file at the current file cursor position
---@param file_reader SequentialFileReader the object for reading from file
function M:readFromFile(file_reader)
    self.random_seed = file_reader:readUInt()
    self.score = file_reader:readUInt()

    self.player_pos.x = file_reader:readDouble()
    self.player_pos.y = file_reader:readDouble()

    self.player_resource:readFromFile(file_reader)
end

return M