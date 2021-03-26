---------------------------------------------------------------------------------------------------
---replay_io_manager.lua
---desc: Manages replay information writing or reading
---modifier:
---------------------------------------------------------------------------------------------------
---replay file structure

---with touhou-style 6 stage game as an example; a replay file would contain the following sequence
---of data
---
---nScene (UInt): number of scenes in this replay, should be 6 in this case
---(the following 3 integers form an index of the scene 1 replay data)
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
---replay summaries

---see stage/group init states along with global states for items that need to be saved

---------------------------------------------------------------------------------------------------

---@class ReplayIOManager
---@brief An object of this class manages replay information read/write in one play-through
local ReplayIOManager = LuaClass("input.ReplayIOManager")

local _input = require("BHElib.input.input_and_replay")
local FileStream = require("util.file_stream")
local ReplayFileReader = require("BHElib.input.replay_file_reader")
local ReplayFileWriter = require("BHElib.input.replay_file_writer")

---------------------------------------------------------------------------------------------------
---init

---@param is_replay boolean whether the game starts in replay mode
---@param init_scene_num number the scene that this replay starts from
---@param replay_path_for_read string the path to read in replay information; can be nil if not in replay mode
---@param replay_path_for_write string the path to write in replay information
function ReplayIOManager.__create(is_replay, init_scene_num, replay_path_for_read, replay_path_for_write)
    local self = {}

    self.is_replay = is_replay
    self.init_scene_num = init_scene_num  -- TODO: can start at any scene
    self.replay_path_for_read = replay_path_for_read
    self.replay_path_for_write = replay_path_for_write

    if is_replay then  -- only read from replay if in replay mode
        local file_stream = FileStream(replay_path_for_read, "rb")
        self.replay_file_reader = ReplayFileReader(file_stream, 1)
    end
    do  -- always write to a replay file, recording the input states
        local file_stream = FileStream(replay_path_for_write, "wb")
        self.replay_file_writer = ReplayFileWriter(file_stream)
    end

    return self
end

---------------------------------------------------------------------------------------------------
---instance methods

---start a new scene
function ReplayIOManager:startNewScene()
    local is_replay = self.is_replay
    _input.resetRecording(is_replay)  -- clear the current input states

    if is_replay then
        self.replay_file_reader:startNewScene()
    end
    self.replay_file_writer:startNewScene()
end

---finish the current scene; called at the end of a scene
---@param stage Stage the current stage object
function ReplayIOManager:finishCurrentScene(stage)
    self.replay_file_writer:finishCurrentScene(stage)
end

---@return boolean true if the game is currently in replay mode
function ReplayIOManager:isReplay()
    return self.is_replay
end

---update the recorded input on the current frame
function ReplayIOManager:updateUserInput()
    -- update recorded input
    if self:isReplay() then
        _input.updateRecordedInputInReplayMode(
                self.replay_file_reader:getFileReader(),
                self.replay_file_writer:getFileWriter()
        )
    else
        _input.updateRecordedInputInNonReplayMode(
                self.replay_file_writer:getFileWriter()
        )
    end
end

---switch the game to non-replay mode
---this operation is irreversible, the game cannot be switched back to replay mode
function ReplayIOManager:changeToNonReplayMode()
    self.is_replay = false
    _input.changeToNonReplayMode()
    self.replay_file_reader:close()
end

---write the information of the entire replay to the replay file
---@param group_init_state SceneGroupInitState the initial state of the scene group to record
function ReplayIOManager:writeGeneralReplaySummary(group_init_state)

end

function ReplayIOManager:cleanup()
    if self:isReplay() then
        self.replay_file_reader:close()
    end
    self.replay_file_writer:close()
end

return ReplayIOManager