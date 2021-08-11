---------------------------------------------------------------------------------------------------
---replay_file_reader.lua
---author: Karl
---date: 2021.3.25
---desc: Manages replay reading
---modifier:
---------------------------------------------------------------------------------------------------

---@class ReplayFileReader
local ReplayFileReader = LuaClass("input.ReplayFileReader")

local SequentialFileReader = require("file_system.sequential_file_reader")  -- for read from replay

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

---initialize an index of cursor positions from reading the replay file
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
---getter

---@return SequentialFileReader the replay file reader
function ReplayFileReader:getFileReader()
    return self.file_reader
end

---return if the input of current stage from the replay file has all been read
---@return boolean true if the file reader has finished reading the final input of the current stage
function ReplayFileReader:isStageEndReached()
    local stream = self.stream
    local replay_index = self.replay_index
    local scene_index_array = replay_index.scene_index_array
    local scene_index = scene_index_array[self.current_scene_num]

    -- compare the file cursor position to the end of stage input
    local current_cursor_position = stream:getCursorPosition()
    assert(
            current_cursor_position >= scene_index.input_data_start,
            "Error: Unexpected replay cursor position!"
    )
    return current_cursor_position >= scene_index.summary_start
end

---------------------------------------------------------------------------------------------------
---file read

local SceneInitState = require("BHElib.scenes.stage.state_of_scene_init")
---@return table the scene summary read from file
function ReplayFileReader:readSceneSummary()
    local file_reader = self.file_reader

    local scene_init_state = SceneInitState()
    scene_init_state:readFromFile(file_reader)

    local score = file_reader:readUInt()

    local summary = {
        scene_init_state = scene_init_state,
        score = score,
    }

    return summary
end

local SceneGroupInitState = require("BHElib.scenes.stage.state_of_group_init")
---@return table the scene group summary read from file
function ReplayFileReader:readSceneGroupSummary()
    local file_reader = self.file_reader

    local group_init_state = SceneGroupInitState()
    group_init_state:readFromFile(file_reader)

    local summary = {
        group_init_state = group_init_state,
    }

    return summary
end

---------------------------------------------------------------------------------------------------
---instance methods

---read stages and scene group summaries from the file
---@return table a table of the form {scene_summary_array, scene_group_summary}
function ReplayFileReader:readSummariesFromFile()
    local stream = self.stream
    local replay_index = self.replay_index
    local scene_index_array = replay_index.scene_index_array

    local scene_summary_array = {}

    for i = 1, #scene_index_array do
        local scene_index = scene_index_array[i]
        stream:seek("set", scene_index.summary_start)  -- start of stage summary

        local summary = self:readSceneSummary()
        scene_summary_array[i] = summary
    end

    stream:seek("set", scene_index_array[#scene_index_array].next_index_start)  -- start of scene group summary
    local scene_group_summary = self:readSceneGroupSummary()

    local ret = {
        scene_summary_array = scene_summary_array,
        scene_group_summary = scene_group_summary,
    }
    return ret
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