---------------------------------------------------------------------------------------------------
---replay_file_reader.lua
---author: Karl
---date: 2021.3.25
---desc: Manages replay reading
---modifier:
---------------------------------------------------------------------------------------------------

---@class ReplayFileReader
local ReplayFileReader = LuaClass("input.ReplayFileReader")

local SequentialFileReader = require("util.sequential_file_reader")  -- for read from replay

---------------------------------------------------------------------------------------------------
---init

---@param stream FileStream the file stream to read from; should be in "rb" mode
---@param init_scene_num number the initial stage
function ReplayFileReader.__create(stream, init_scene_num)
    local self = {
        stream = stream,
        file_reader = SequentialFileReader(stream),
        current_scene_num = init_scene_num - 1,  -- before the first scene

        -- an index of cursor positions
        replay_index = {
            scene_index_array = {}  -- an index of cursor positions for each scene
        },
    }
    ReplayFileReader.initReplayIndex(self)
    return self
end

---initialize an index of cursor position from reading the replay file
function ReplayFileReader:initReplayIndex()
    local file_reader = self.file_reader
    local stream = self.stream
    local replay_index = self.replay_index
    local scene_index_array = replay_index.scene_index_array

    replay_index.replay_start = stream:getCursorPosition()  -- record the starting position of the replay

    -- init scene index
    local scene_num = file_reader:readUInt()
    for i = 1, scene_num do
        local scene_index = {}
        scene_index.index_start = stream:getCursorPosition()
        scene_index.input_data_start = file_reader:readUInt()
        scene_index.summary_start = file_reader:readUInt()
        scene_index.next_index_start = file_reader:readUInt()

        scene_index_array[i] = scene_index
        stream:seek("set", scene_index.next_index_start)  -- move cursor to next stage
    end
end

---------------------------------------------------------------------------------------------------
---instance methods

---@return SequentialFileReader the replay file reader
function ReplayFileReader:getFileReader()
    return self.file_reader
end

---move file_reader to the start of input data;
---increment current scene number by one
function ReplayFileReader:startNewScene()
    local current_scene_num = self.current_scene_num + 1
    self.current_scene_num = current_scene_num

    local scene_index = self.replay_index.scene_index_array[current_scene_num]

    local input_data_start = scene_index.input_data_start
    self.stream:seek("set", input_data_start)
end

function ReplayFileReader:close()
    self.file_reader:close()
end

return ReplayFileReader