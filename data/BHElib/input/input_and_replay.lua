---------------------------------------------------------------------------------------------------
---input_and_replay.lua
---author: Karl
---date created: 2021.3.3
---desc: Manages input devices, input apis and interactions between input and replay; because the
---     differences in the in-game replay input and normal system input, many apis have two versions
---     for each type of need. One I use the phrase "recorded", and the other "active" or with no
---     special descriptions;
---     Implementation of this file uses snapshot; all input states in a frame are updated together
---     in one function call
---     One more note, in order to avoid problems of device input and recorded devices input differ,
---     the implementation some apis of setting/key_mapping.lua are re-written here (with the same
---     function name)
---------------------------------------------------------------------------------------------------

---@class InputDeviceManager
local M = {}

local _raw_input = require("setting.key_mapping")

---maps from device id to input key states;
local _device_states
---records input of devices in the last frame; the content of the table should not be modified, but
---the table this variable points to should be updated each frame;
---is nil for the first few frames of a game;
local _prev_device_states

---in normal play-through, this records the same states as _device_states, but only for GAME_KEYS;
---in replay mode, this contains device states read from the replay file
local _recorded_device_states
local _prev_recorded_device_states

---mouse input include floating point position, process them separately
---mouse states is an array of five elements; first three are boolean for three mouse buttons
---last two are mouse position x, y
local _mouse_states
local _prev_mouse_states
local _recorded_mouse_states
local _prev_recorded_mouse_states

---indicates if the input device manager is in replay mode;
---this will influence the update of recorded device tables
local _is_replay_mode

---------------------------------------------------------------------------------------------------
---cache variables and functions

local pairs = pairs
local _IsDeviceKeyDown
local _IsAnyDeviceKeyDown
local _IsRecordedKeyDown
local _IsAnyRecordedKeyDown

---------------------------------------------------------------------------------------------------
---categorize function keys into game keys and system keys
---game keys are the ones that will be saved by the replays;
---system keys are for general input keys that apply not only to the gameplay;
---game keys can overlap with system keys, but the function key names can not overlap with each other
---
---for each device, the mapping to device keys need to be specified in setting.ini

local GAME_KEYS = {
    "right",  -- arrow keys; player movement keys
    "left",
    "up",
    "down",

    "slow",  -- slow down movement speed; focus mode
    "shoot",  -- player normal attack
    "spell",  -- bomb
    "special",  -- "C"
}

local SYSTEM_KEYS = {
    "select",  -- menu selection
    "escape",  -- call pause menu
    "snapshot",  -- take a snapshot
    "retry",  -- shortcut for start over a game in pause menu

    "toggle_collider",  -- display object collider
    "repslow",  -- decelerate replay speed
    "repfast",  -- accelerate replay speed
}

---return the list of game keys
function M.getGameKeys()
    return GAME_KEYS
end

---return the list of system keys
function M.getSystemKeys()
    return SYSTEM_KEYS
end

---------------------------------------------------------------------------------------------------
---getters

---@return number number of devices
function M.getDeviceCount()
    local n = 0
    for _, _ in pairs(_device_states) do
        n = n + 1
    end
    return n
end

---@return number number of devices
function M.getRecordedDeviceCount()
    local n = 0
    for _, _ in pairs(_recorded_device_states) do
        n = n + 1
    end
    return n
end

---get an array of currently active device id
---@return table an array of all device id
function M.getDeviceIDArray()
    local result = {}
    for device_id, _ in pairs(_device_states) do
        table.insert(result, device_id)
    end
    return result
end

---get an array of currently recorded device id
---@return table an array of all recorded device id
function M.getRecordedDeviceIDArray()
    local result = {}
    for device_id, _ in pairs(_recorded_device_states) do
        table.insert(result, device_id)
    end
    return result
end

---------------------------------------------------------------------------------------------------
---accessing the devices

---return if the device is in the active device table;
---recommend checking if device is active before accessing the device input
function M.isDeviceActive(device_id)
    return _device_states[device_id] ~= nil
end

---return if the device is in the recorded device table;
---recommend checking before accessing the device input
function M.isDeviceRecorded(device_id)
    return _recorded_device_states[device_id] ~= nil
end

---get current device input from the given device
---@param device_index number device index in the device table
---@param function_key_name string name of the function key; can be game key or system key
---@return boolean
function M.isDeviceKeyDown(device_index, function_key_name)
    return _device_states[device_index][function_key_name]
end
_IsDeviceKeyDown = M.isDeviceKeyDown

---get recorded input from the given device
---@param device_index number device index in the device table
---@param function_key_name string name of the function key; can only be a game key
---@return boolean
function M.isRecordedKeyDown(device_index, function_key_name)
    return _recorded_device_states[device_index][function_key_name]
end
_IsRecordedKeyDown = M.isRecordedKeyDown

---return if there exists a device among recorded devices, and on that device, the given key is pressed
---@param function_key_name string name of the function key; can be game key or system key
---@return boolean true if any device presses the input; otherwise return false
function M.isAnyDeviceKeyDown(function_key_name)
    for _, key_state_array in pairs(_device_states) do
        if key_state_array[function_key_name] then
            return true
        end
    end
    return false
end
_IsAnyDeviceKeyDown = M.isAnyDeviceKeyDow

---return if there exists a device among recorded devices, and on that device, the given key is pressed
---@param function_key_name string name of the function key; can only be a game key
---@return boolean true if any device presses the input; otherwise return false
function M.isAnyRecordedKeyDown(function_key_name)
    for _, key_state_array in pairs(_recorded_device_states) do
        if key_state_array[function_key_name] then
            return true
        end
    end
    return false
end
_IsAnyRecordedKeyDown = M.isAnyRecordedKeyDown

---@return number, number x, y position of the mouse
function M.getMousePosition()
    return _mouse_states[4], _mouse_states[5]
end

---@return number, number recorded x, y position of the mouse
function M.getRecordedMousePosition()
    return _recorded_mouse_states[4], _recorded_mouse_states[5]
end

---@return boolean if the mouse is pressed
function M.isMousePressed()
    return _mouse_states[1]
end

---@return boolean if the recorded mouse is pressed
function M.isRecordedMousePressed()
    return _recorded_mouse_states[1]
end

---------------------------------------------------------------------------------------------------
---key just down and key just released
---these ones are parametrized to avoid too much code duplication

---@param device_id number device id number
---@param function_key_name string name of the function key
---@param is_recorded boolean if true, return device input; if false return recorded input
---@param is_down boolean if true, return if the key is just pressed; otherwise return if the key is just released
function M.isDeviceKeyJustChanged(device_id, function_key_name, is_recorded, is_down)
    local states = _device_states
    local prev_states = _prev_device_states
    if is_recorded then
        states = _recorded_device_states
        prev_states = _prev_recorded_device_states
    end
    local prev_device_state = prev_states[device_id]
    local key_is_down_this_frame = states[device_id][function_key_name]
    local key_is_down_on_last_frame = prev_device_state ~= nil and prev_device_state[function_key_name]

    if is_down then
        return key_is_down_this_frame and not key_is_down_on_last_frame
    else
        return not key_is_down_this_frame and key_is_down_on_last_frame
    end
end

---@param function_key_name string name of the function key
---@param is_recorded boolean if true, return device input; if false return recorded input
---@param is_down boolean if true, return if the key is just pressed; otherwise return if the key is just released
function M.isAnyDeviceKeyJustChanged(function_key_name, is_recorded, is_down)
    local states = _device_states
    if is_recorded then
        states = _recorded_device_states
    end
    for device_id, _ in pairs(states) do
        if M.isDeviceKeyJustChanged(device_id, function_key_name, is_recorded, is_down) then
            return true
        end
    end
    return false
end

---return if the mouse is just pressed/released
---@param is_recorded boolean if true, return device input; if false return recorded input
---@param is_down boolean if true, return if the button is just pressed; otherwise return if the key is just released
function M.isMouseButtonJustChanged(is_recorded, is_down)
    local states = _mouse_states
    local prev_states = _prev_mouse_states
    if is_recorded then
        states = _recorded_mouse_states
        prev_states = _prev_recorded_mouse_states
    end

    local mouse_is_pressed_on_last_frame = prev_states ~= nil and prev_states[1]
    if is_down then
        return states[1] and not mouse_is_pressed_on_last_frame
    else
        return not states[1] and mouse_is_pressed_on_last_frame
    end
end

---------------------------------------------------------------------------------------------------
---recorded input reset and update

---reset the recorded key state table at the start of a play-through;
---immediately update fill input tables with zeros twice; this is to allow input to be accessible at any time
---@param is_replay_mode boolean whether the input is going to be processed in replay mode
function M.resetRecording(is_replay_mode)
    _is_replay_mode = is_replay_mode

    -- zero re-initialize all the variables
    _recorded_device_states = {}

    -- same for other tables
    _device_states = {}
    _prev_device_states = {}
    _prev_recorded_device_states = {}

    -- mouse
    _mouse_states = {false, false, false, 0, 0}  -- be careful about mouse behaviour
    _prev_mouse_states = _mouse_states
    _recorded_mouse_states = _mouse_states
    _prev_recorded_mouse_states = _mouse_states
end

---record raw device input in the current frame to _device_states and _mouse_states;
---update _prev_device_states and _prev_mouse_state by the current states
function M.updateInputSnapshot()

    -- device input
    _prev_device_states = _device_states
    _device_states = {}  -- clear the input table

    local device_id_array = _raw_input.getDeviceIDArray()
    for index = 1, #device_id_array do
        -- update the state table
        local device_id = device_id_array[index]
        local device_state = {}

        for i = 1, #GAME_KEYS do
            local function_key_name = GAME_KEYS[i]
            local is_down = _raw_input.isDeviceKeyDown(device_id, function_key_name)
            device_state[function_key_name] = is_down
        end
        for i = 1, #SYSTEM_KEYS do
            local function_key_name = SYSTEM_KEYS[i]
            local is_down = _raw_input.isDeviceKeyDown(device_id, function_key_name)
            device_state[function_key_name] = is_down
        end
        _device_states[device_id] = device_state
    end

    -- mouse input
    _prev_mouse_states = _mouse_states
    local b1, b2, b3 = _raw_input.getMouseState()
    local mouse_x, mouse_y = _raw_input.getMousePosition()
    _mouse_states = {b1, b2, b3, mouse_x, mouse_y}  -- overwrite mouse state
end

---update the input by one frame and record it to replay file;
---@param sequential_writer SequentialFileWriter stream for write to replay file
local function WriteRecordedInputToStream(sequential_writer)
    -- device input
    local device_count = M.getRecordedDeviceCount()
    sequential_writer:writeUInt(device_count)

    for device_id, device_state in pairs(_recorded_device_states) do
        -- compress input to bits
        local device_state_in_bit_array = {}
        for i = 1, #GAME_KEYS do
            local function_key_name = GAME_KEYS[i]
            device_state_in_bit_array[i] = device_state[function_key_name]
        end

        -- write to the replay file
        sequential_writer:writeUInt(device_id)  -- record device id
        sequential_writer:writeBitArray(device_state_in_bit_array)
    end

    -- mouse input
    local b1, b2, b3, x, y = unpack(_recorded_mouse_states)
    sequential_writer:writeBitArray({b1, b2, b3})
    sequential_writer:writeFloat(x)
    sequential_writer:writeFloat(y)
end

---update _recorded_device_states and _recorded_mouse_states by reading from the given input stream
---@param sequential_reader SequentialFileReader stream for read from replay file
local function ReadRecordedInputFromStream(sequential_reader)
    -- device input
    _recorded_device_states = {}  -- clear the recorded input table

    local device_count = sequential_reader:readUInt()
    for _ = 1, device_count do
        -- load recorded input for this device
        local device_id = sequential_reader:readUInt()
        local recorded_device_state = {}
        local bit_array = sequential_reader:readBitArray()
        for i = 1, #GAME_KEYS do
            local function_key_name = GAME_KEYS[i]
            recorded_device_state[function_key_name] = bit_array[i]
        end
        _recorded_device_states[device_id] = recorded_device_state
    end

    -- mouse input
    local b1, b2, b3 = unpack(sequential_reader:readBitArray())
    local x = sequential_reader:readFloat()
    local y = sequential_reader:readFloat()
    _recorded_mouse_states = {b1, b2, b3, x, y}  -- overwrite the mouse states
end

---update the recorded replay input from replay file;
---check if the replay input has ended before calling the function;
---@param sequential_reader SequentialFileReader stream for read from replay file
---@param sequential_writer SequentialFileWriter stream for write to replay file
function M.updateRecordedInputInReplayMode(sequential_reader, sequential_writer)
    assert(_is_replay_mode)

    -- device input
    -- update recorded input; update _prev form current input
    _prev_recorded_device_states = _recorded_device_states
    _prev_recorded_mouse_states = _recorded_mouse_states

    ReadRecordedInputFromStream(sequential_reader)
    WriteRecordedInputToStream(sequential_writer)
end

---update the input by one frame and record it to replay file;
---@param sequential_writer SequentialFileWriter stream for write to replay file
function M.updateRecordedInputInNonReplayMode(sequential_writer)
    assert(not _is_replay_mode)

    _prev_recorded_device_states = _recorded_device_states
    _prev_recorded_mouse_states = _recorded_mouse_states

    -- not in replay, just use normal input
    _recorded_device_states = _device_states
    _recorded_mouse_states = _mouse_states

    WriteRecordedInputToStream(sequential_writer)
end

---set replay mode to false and close the given replay file read stream
---@param sequential_reader SequentialFileReader stream for read from replay file
function M.changeToNonReplayMode(sequential_reader)
    _is_replay_mode = false
    sequential_reader:close()
end

---------------------------------------------------------------------------------------------------
---init

---this function should only be called on application startup
function M.init()
    _raw_input.init()
    M.resetRecording(false)  -- input is available after this function call
end


return M