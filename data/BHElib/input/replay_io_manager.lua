---------------------------------------------------------------------------------------------------
---replay_io_manager.lua
---desc: Manages replay information writing or reading; this class is responsible for updating the
---     input every frame in input_and_recording.lua
---modifier:
---------------------------------------------------------------------------------------------------
---replay file structure

---with touhou-style 6 stage game as an example; a replay file would contain the following sequence
---of data
---
---nScene (UInt): number of scenes in this replay, should be 6 in this case
---(the following 3 integers form an INDEX of the scene 1 replay data)
---initDataStart 1(UInt): cursor position after writing scene 1 index
---summaryStart 1(UInt): cursor position after writing scene 1 replay input data
---nextIndexStart 1(UInt): cursor position after writing scene 1 summary
---scene 1 replay input data
---scene 1 replay summary
---initDataStart 2(UInt): cursor position after writing scene 2 index
---...
---initDataEnd 6(UInt): cursor position after writing scene 6 replay input data
---summaryEnd 6(UInt): cursor position after writing scene 6 summary
---initDataStart 6(UInt): cursor position after writing scene 6 index
---scene 6 replay input data
---scene 6 replay summary
---general replay summary (player signature etc.)

---------------------------------------------------------------------------------------------------
---replay scene/scene group summaries

---see stage/group init states along with global states for items that need to be saved

---------------------------------------------------------------------------------------------------
---you can use the following pattern of function calls for this object (does not include update in
---each frame)

---ReplayIOManager() creates the object
---...
---readSummariesFromFile() in replay mode to get stages or scene group information about the replay
---...
---startNewScene() at the start of first scene
---...
---finishCurrentScene() at the end of the first scene
---...repeat once for each scene
---finishCurrentScene() at the end of the final scene
---finishCurrentSceneGroup() immediately follows

---------------------------------------------------------------------------------------------------

---@class ReplayIOManager
---@brief An object of this class manages replay information read/write in one play-through
local M = LuaClass("input.ReplayIOManager")

local _input = require("BHElib.input.input_and_recording")
local FileStream = require("file_system.file_stream")
local ReplayFileReader = require("BHElib.input.replay_file_reader")
local ReplayFileWriter = require("BHElib.input.replay_file_writer")

---------------------------------------------------------------------------------------------------
---init

---@param is_replay boolean whether the game starts in replay mode
---@param replay_path_for_read string the path to read in replay information; can be nil if not in replay mode
---@param replay_path_for_write string the path to write in replay information
---@param start_stage_for_replay number the starting stage in the replay; can be nil if not in replay mode
function M.__create(is_replay, replay_path_for_read, replay_path_for_write, start_stage_for_replay)
    local self = {}

    self.is_replay = is_replay
    self.replay_path_for_read = replay_path_for_read
    self.replay_path_for_write = replay_path_for_write

    if is_replay then  -- only read from replay if in replay mode
        local file_stream = FileStream(replay_path_for_read, "rb")
        self.replay_file_reader = ReplayFileReader(file_stream, start_stage_for_replay)
    end
    do  -- always write to a replay file, recording the input states
        local file_stream = FileStream(replay_path_for_write, "wb")
        self.replay_file_writer = ReplayFileWriter(file_stream)
    end

    return self
end

---------------------------------------------------------------------------------------------------
---getter

---@return boolean true if the game is currently in replay mode
function M:isReplay()
    return self.is_replay
end

---@return ReplayFileReader
function M:getReplayFileReader()
    return self.replay_file_reader
end

---@return ReplayFileWriter
function M:getReplayFileWriter()
    return self.replay_file_writer
end

---------------------------------------------------------------------------------------------------
---update

---update the recorded input on the current frame
function M:updateUserInput()
    -- update recorded input
    if self:isReplay() then
        -- may be better to separate read and write in two function calls
        -- so this can be written in a more flexible way
        _input:updateRecordedInputInReplayMode(
                self.replay_file_reader:getFileReader(),
                self.replay_file_writer:getFileWriter())
    else
        _input:updateRecordedInputInNonReplayMode(
                self.replay_file_writer:getFileWriter())
    end
end

---------------------------------------------------------------------------------------------------
---for transition

---start a new scene
function M:startNewScene()
    local is_replay = self:isReplay()
    _input:resetRecording(is_replay)  -- clear the current input states

    if is_replay then
        self.replay_file_reader:startNewScene()
    end
    self.replay_file_writer:startNewScene()
end

---finish the current scene; called at the end of a scene
---@param stage Stage the current stage object
function M:finishCurrentScene(stage)
    self.replay_file_writer:finishCurrentScene(stage)
end

---finish writing the entire replay to the replay file
---@param stage Stage the current stage object
function M:finishCurrentSceneGroup(stage)
    self.replay_file_writer:finishCurrentSceneGroup(stage)
end

function M:cleanup()
    print("replay cleaning up")
    if self:isReplay() then
        print("closing replay file reader")
        self.replay_file_reader:close()
    end
    print("closing replay file writer")
    self.replay_file_writer:close()
end

---------------------------------------------------------------------------------------------------
---for replay mode only

---@return table summaries read from replay file
function M:readSummariesFromFile()
    return self.replay_file_reader:readSummariesFromFile()
end

---switch the game to non-replay mode
---this operation is irreversible, the game cannot be switched back to replay mode
function M:changeToNonReplayMode()
    self.is_replay = false
    _input:changeToNonReplayMode()
    print("changing to non-replay mode and closing replay file reader")
    self.replay_file_reader:close()
end

---return if the input of current stage from the replay file has all been read;
---this function should only be called when the cursor is within replay input or immediately after that
---@return boolean true if the file reader has finished reading the final input of the current stage
function M:isStageEndReached()
    return self.replay_file_reader:isStageEndReached()
end

return M