---------------------------------------------------------------------------------------------------
---player_resource.lua
---author: Karl
---date: 2021.8.7
---desc: A PlayerResource object is a struct that contains the resources of one player
---------------------------------------------------------------------------------------------------

---@class gameplay_resources.Player
local M = LuaClass("PlayerResource")

function M.__create()
    return {
        num_life = 0,
        num_bomb = 0,
        num_graze = 0,
        num_power = 0,
    }
end

local _double_fields = {
    "num_life",
    "num_bomb",
    "num_graze",
    "num_power",
}
local _string_fields = {}

function M:copy()
    local copy = M()
    copy.num_life = self.num_life
    copy.num_bomb = self.num_bomb
    copy.num_graze = self.num_graze
    copy.num_power = self.num_power
    return copy
end

---------------------------------------------------------------------------------------------------
---save to/load from file

---manages saving the object to file at the current file cursor position
---@param file_writer SequentialFileWriter the object for writing to file
function M:writeToFile(file_writer)
    file_writer:writeFieldsOfTable(self, _double_fields, _string_fields)
end

---manages reading the object from file at the current file cursor position
---@param file_reader SequentialFileReader the object for reading from file
function M:readFromFile(file_reader)
    file_reader:readFieldsOfTable(self, _double_fields, _string_fields)
end

return M