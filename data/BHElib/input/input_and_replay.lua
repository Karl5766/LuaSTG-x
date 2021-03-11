---------------------------------------------------------------------------------------------------
---input_and_replay.lua
---author: Karl
---date created: 2021.3.3
---desc: Manages input devices, input apis and interactions between input and replay; because the
---     differences in the in-game replay input and normal system input, many apis have two versions
---     for each type of need. One I use the phrase "recorded", and the other "active" or with no
---     special descriptions;
---     by the way, the active input apis can be used independently without even initializing the
---     in-game replay input, if ever needed
---------------------------------------------------------------------------------------------------

---@class InputDeviceManager
local M = {}

local controller_helper = require("platform.controller_helper")
local key_mapping = require("setting.key_mapping")

---maps from device id to device label
local _devices
local _next_device_id = 1

---maps from device id to input key states
---in normal play-through, this records the same states as isDeviceKeyDown;
---in replay mode, this contains device states read from the
local _recorded_device_states = {}

---if the input device manager is in replay mode;
---this will influence the update of recorded device tables
local _is_replay_mode

---------------------------------------------------------------------------------------------------
---cache function

local pairs = pairs

---------------------------------------------------------------------------------------------------
---DeviceLabel a structure represents an input device
---struct DeviceLabel {
---     device_type,  -- string, can be "keyboard" or "controller"
---     device,  -- reference to the device; can be nil if the device is unique of its type
---}

---return if the two device labels are identical
---@param device_label1 DeviceLabel
---@param device_label2 DeviceLabel
---@return boolean true if two labels are the same
function M.isSameDevice(device_label1, device_label2)
    return device_label1.device_type == device_label2.device_type and device_label1.device == device_label2.device
end

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

    "toggle_collider",
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
    for _, _ in pairs(_devices) do
        n = n + 1
    end
end

---get a device's label by its id
---@param device_id number id of the device
function M.getDeviceByID(device_id)
    return _devices[device_id]
end

---get an array of currently active device id
---@return table an array of all device id
function M.getDeviceIDArray()
    local result = {}
    for device_id, _ in pairs(_devices) do
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

---return if the device is in the active device table;
---recommend checking if device is active before accessing the device input
function M.isDeviceActive(device_id)
    return _devices[device_id] ~= nil
end

---return if the device is in the active device table;
---recommend checking if device is active before accessing the device input
function M.isDeviceRecorded(device_id)
    return _recorded_device_states[device_id] ~= nil
end

---------------------------------------------------------------------------------------------------
---insertions and deletions

---Add a device to the active device table
---@param device_label DeviceLabel the device to insert
function M.insertDevice(device_label)
    assert(M.getDeviceCount() < 25, "Assertion failed: Too many input devices connected")

    _devices[_next_device_id] = device_label
    _next_device_id = _next_device_id + 1
end

---remove a device from devices table by its device id
---@param device_id number the id of the device to remove
function M.deleteDevice(device_id)
    _devices[device_id] = nil
end

---------------------------------------------------------------------------------------------------
---accessing the devices

---get raw input from the given device
---@param device_index number device index in the device table
---@param function_key_name string name of the function key
---@return boolean
function M.isDeviceKeyDown(device_index, function_key_name)
    local device_label = _devices[device_index]
    if device_label.device_type == "keyboard" then
        return key_mapping.isKeyboardKeyDown(function_key_name)
    elseif device_label.device_type == "controller" then
        return key_mapping.isControllerKeyDown(device_label.device, function_key_name)
    else
        error("ERROR: Unknown device type!")
    end
end

---get recorded input from the given device
---@param device_index number device index in the device table
---@param function_key_name string name of the function key
---@return boolean
function M.isRecordedKeyDown(device_index, function_key_name)
    return _recorded_device_states[device_index][function_key_name]
end

---return if there exists a device among active devices, and on that device, the given key is pressed
---@param function_key_name string name of the function key
---@return boolean true if any device presses the input; otherwise return false
function M.isAnyDeviceKeyDown(function_key_name)
    for i, _ in pairs(_devices) do
        if M.isDeviceKeyDown(i, function_key_name) then
            return true
        end
    end
    return false
end

---return if there exists a device among recorded devices, and on that device, the given key is pressed
---@param function_key_name string name of the function key
---@return boolean true if any device presses the input; otherwise return false
function M.isAnyRecordedKeyDown(function_key_name)
    for _, key_state_array in pairs(_recorded_device_states) do
        if key_state_array[function_key_name] then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------------------------------
---device input init

---load all connected devices
local function InputDeviceInit()

    -- initialize active device table
    _devices = {}

    local keyboard_label = {
        device_type = "keyboard",
        device = nil,
    }
    _devices[1] = keyboard_label

    local controllers = controller_helper.getAllControllerLabels()
    for _, label in ipairs(controllers) do
        M.insertDevice(label)
    end

    -- devices may connect after this function is called;
    lstg.eventDispatcher:addListener("onInputDeviceConnect", function(device_label)
        M.insertDevice(device_label)
    end)

    -- devices may disconnect during the game
    lstg.eventDispatcher:addListener("onInputDeviceDisconnect", function(device_label)
        -- find device and remove it
        for id, label in pairs(_devices) do
            if M.isSameDevice(label, device_label) then
                M.deleteDevice(id)
                return
            end
        end
        error("ERROR: Disconnected device is not found in devices table! ")
    end)
end

function M.init()
    key_mapping.init(setting.keyboard_keys, setting.controller_keys)

    InputDeviceInit()
end

---------------------------------------------------------------------------------------------------
---recorded input init and update

---reset the recorded key state table;
---there should not be replay input access between this function and the first updateRecordedInput call
---@param is_replay_mode boolean whether the input is going to be processed in replay mode
function M.resetRecording(is_replay_mode)
    _is_replay_mode = is_replay_mode

    -- set to nil, as there is not supposed to be accesses to replay input before the first update
    _recorded_device_states = nil
end

---update the replay input by one frame;
---check if the replay input has ended before calling the function;
---@param replay_file_reader SequentialFileReader stream for read from replay file
function M.updateRecordedInputInReplayMode(replay_file_reader)
    assert(_is_replay_mode)

    _recorded_device_states = {}  -- clear the recorded input table

    local device_count = replay_file_reader:readUInt()
    for _ = 1, device_count do
        -- load recorded input for this device
        local device_id = replay_file_reader:readUInt()
        local recorded_device_state = _recorded_device_states[device_id]

        local bit_array = replay_file_reader:readBitArray()
        for i = 1, #GAME_KEYS do
            local function_key_name = GAME_KEYS[i]
            recorded_device_state[function_key_name] = bit_array[i]
        end
    end
end

---update the input by one frame and record it to replay file;
---@param replay_file_writer SequentialFileWriter stream for write to replay file
function M.updateRecordedInputInNonReplayMode(replay_file_writer)
    assert(not _is_replay_mode)

    _recorded_device_states = {}  -- clear the recorded input table

    local device_count = M.getDeviceCount()
    replay_file_writer:writeUInt(device_count)

    for id, _ in pairs(_devices) do
        -- update the state table
        local device_state = {}
        local device_state_in_bit_array = {}  -- compress input to bits and save to replay file

        for i = 1, #GAME_KEYS do
            local function_key_name = GAME_KEYS[i]
            local is_down = M.isDeviceKeyDown(id, function_key_name)
            device_state[id] = is_down
            device_state_in_bit_array[i] = is_down
        end
        _recorded_device_states[id] = device_state

        -- write to the replay file
        replay_file_writer:writeUInt(id)  -- record device id
        replay_file_writer:writeBitArray(device_state_in_bit_array)
    end
end


return M