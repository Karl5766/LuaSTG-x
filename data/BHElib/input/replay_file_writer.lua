---------------------------------------------------------------------------------------------------
---replay_file_writer.lua
---author: Karl
---date: 2021.3.25
---desc: Manages replay writing
---modifier:
---------------------------------------------------------------------------------------------------

---@class ReplayFileWriter
local ReplayFileWriter = LuaClass("input.ReplayFileWriter")

local SequentialFileWriter = require("util.sequential_file_writer")  -- for write to replay

---------------------------------------------------------------------------------------------------
---init

---@param stream FileStream the file stream to write to; should be in "wb" mode
function ReplayFileWriter.__create(stream)
    local self = {
        stream = stream,
        file_writer = SequentialFileWriter(stream),
        current_scene_num = 0,  -- before the first scene

        -- an index of cursor positions
        replay_index = {
            scene_index_array = {}  -- an index of cursor positions for each scene
        },
    }
    ReplayFileWriter.initReplayIndex(self)
    return self
end

---initialize an index of cursor position
---skip the writer to the position of the start of replay for the first scene
function ReplayFileWriter:initReplayIndex()
    local file_writer = self.file_writer
    local stream = self.stream

    self.replay_index.replay_start = stream:getCursorPosition()  -- record the starting position of the replay
    file_writer:writeUInt(0)  -- leave room for an integer stage_num
end

---------------------------------------------------------------------------------------------------
---getter

---@return SequentialFileWriter the replay file writer
function ReplayFileWriter:getFileWriter()
    return self.file_writer
end

---------------------------------------------------------------------------------------------------
---file write

---write the information of the current scene to the replay file
---@param stage Stage the current stage object
function ReplayFileWriter:writeSceneSummary(stage)
    local file_writer = self.file_writer
    stage.scene_init_state:writeToFile(file_writer)  -- record the initial state of the stage
    file_writer:writeUInt(stage:getScore())  -- record the finish score
end

---write the information of the current scene to the replay file
---@param stage Stage the current stage object
function ReplayFileWriter:writeSceneGroupSummary(stage)
    local file_writer = self.file_writer
    stage.scene_group:getSceneGroupInitState():writeToFile(file_writer)  -- record the initial state of the scene group
end

---------------------------------------------------------------------------------------------------
---for transition

---write the recorded file cursor positions to file, along with the number of scenes in total
function ReplayFileWriter:writeReplayIndexToFile()
    local file_writer = self.file_writer
    local stream = self.stream
    local replay_index = self.replay_index
    local scene_index_array = replay_index.scene_index_array
    local scene_num = #scene_index_array

    -- write number of scenes in total
    stream:seek("set", replay_index.replay_start)
    file_writer:writeUInt(scene_num)

    -- write index for each scene
    for i = 1, scene_num do
        local scene_index = scene_index_array[i]
        stream:seek("set", scene_index.index_start)
        file_writer:writeUInt(scene_index.input_data_start)
        file_writer:writeUInt(scene_index.summary_start)
        file_writer:writeUInt(scene_index.next_index_start)
    end
end

---increment current scene number by one;
---move cursor to the start of input data;
---and record the cursor positions for index_start and input_data_start in
---the scene_index_array
function ReplayFileWriter:startNewScene()
    local current_scene_num = self.current_scene_num + 1
    self.current_scene_num = current_scene_num

    local scene_index_array = self.replay_index.scene_index_array

    local file_writer = self.file_writer
    local stream = self.stream

    local index_start = stream:getCursorPosition()
    for i = 1, 3 do
        file_writer:writeUInt(0)
    end
    local input_data_start = stream:getCursorPosition()
    local scene_index = {
        index_start = index_start,
        input_data_start = input_data_start,
    }
    scene_index_array[current_scene_num] = scene_index
end

---record the cursor position, and write the scene summary
---@param stage Stage the current stage object
function ReplayFileWriter:finishCurrentScene(stage)
    local stream = self.stream
    local scene_index_array = self.replay_index.scene_index_array
    local current_scene_num = self.current_scene_num
    local scene_index = scene_index_array[current_scene_num]

    scene_index.summary_start = stream:getCursorPosition()

    -- write the stage summary
    self:writeSceneSummary(stage)

    scene_index.next_index_start = stream:getCursorPosition()
end

---write the scene group summary
---@param stage Stage the current stage object
function ReplayFileWriter:finishCurrentSceneGroup(stage)
    self:writeSceneGroupSummary(stage)
end

function ReplayFileWriter:close()
    self:writeReplayIndexToFile()
    self.file_writer:close()
end

return ReplayFileWriter