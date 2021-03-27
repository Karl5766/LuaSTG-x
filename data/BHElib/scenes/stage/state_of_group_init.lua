---------------------------------------------------------------------------------------------------
---state_of_group_init.lua
---author: Karl
---date: 2021.3.10
---desc: Defines the SceneGroupInitState object, which is created and used for initialization of
---     the initial state of an entire play-through, which may contain several levels.
---modifier:
---------------------------------------------------------------------------------------------------

---@class SceneGroupInitState
local InitState = LuaClass("scenes.SceneGroupInitState")

---create and return a default init state;
---the attributes of an object of this class should not be modified more than once,
---except for initialization immediately following creating the object
function InitState.__create()
    local self = {}

    self.player_class_id = nil
    self.scene_id_array = nil  -- an array of string ids of all the stages in the scene group

    self.is_replay = nil
    self.replay_path_for_write = nil
    self.replay_path_for_read = nil  -- can be kept as nil if in replay mode
    self.start_stage_in_replay = nil

    return self
end

---manages saving the object to file at the current file cursor position
---@param file_writer SequentialFileWriter the object for writing to file
function InitState:writeToFile(file_writer)
    file_writer:writeVarLengthStringArray(self.scene_id_array)
end

---manages reading the object from file at the current file cursor position
---@param file_reader SequentialFileReader the object for reading from file
function InitState:readFromFile(file_reader)
    self.scene_id_array = file_reader:readVarLengthStringArray()
end

return InitState