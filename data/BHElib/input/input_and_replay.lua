---------------------------------------------------------------------------------------------------
---input_and_replay.lua
---author: Karl
---date created: 2021.3.3
---desc: Manages input devices, input apis and interactions between input and replay
---------------------------------------------------------------------------------------------------

---@class InputDeviceManager
local M = {}

local controller_helper = require("platform.controller_helper")
local key_mapping = require("setting.key_mapping")

---store an array of labels about all current active input devices
local _devices
---devices exceed maximum device count, to be activated
local _device_wait_queue

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
local function IsSameDevice(device_label1, device_label2)
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

---------------------------------------------------------------------------------------------------
---getters

---return the list of game keys
function M.getGameKeys()
    return GAME_KEYS
end

---return the list of system keys
function M.getSystemKeys()
    return SYSTEM_KEYS
end

---------------------------------------------------------------------------------------------------
---query and update device list

---return if the device is in the active device array;
---recommend checking if device is active before accessing the device input
function M.isDeviceActive(device_label)
    for i = 1, #_devices do
        if IsSameDevice(_devices[i], device_label) then
            return true
        end
    end
    return false
end

---return the list of active devices
function M.getActiveDeviceList()
    return _devices
end

---@param device_label DeviceLabel the device to activate
local function ActivateDevice(device_label)
    Print(string.format("A %s device is activated.", device_label.device_type))
    lstg.eventDispatcher:dispatchEvent('onInputDeviceActivate', device_label.device_type)
end

---@param device_label DeviceLabel the device to push to active device list
local function PushDevice(device_label)
    _devices[#_devices + 1] = device_label
    ActivateDevice(device_label)
end

---@param device_label DeviceLabel the device to deactivate
local function DeactivateDevice(device_label)
    Print(string.format("A %s device is deactivated.", device_label.device_type))
    lstg.eventDispatcher:dispatchEvent('onInputDeviceDeactivate', device_label.device_type)
end

---@param device_label DeviceLabel the device to push to device wait queue
local function PushWaitList(device_label)
    _device_wait_queue[#_device_wait_queue + 1] = device_label
    DeactivateDevice(device_label)
end

---set the maximum number of connected devices;
---overpopulated devices will be popped back to waiting queue;
---otherwise if there is any empty room, devices in the waiting queue will be set to active
---@param max_device_count number maximum number of input devices that can be active after the refresh
function M.refreshDevices(max_device_count)
    local device_count = #_devices
    if device_count < max_device_count then
        -- move device from wait queue to active list
        while #_device_wait_queue > 0 and device_count < max_device_count do
            PushDevice(_device_wait_queue[1])
            table.remove(_device_wait_queue, 1)
            device_count = device_count + 1
        end
    else
        -- move device from active list back to wait queue
        while device_count > max_device_count do
            PushWaitList(_devices[device_count])
            table.remove(_devices, device_count)
            device_count = device_count - 1
        end
    end
end

---------------------------------------------------------------------------------------------------
---accessing the devices

---get raw input from the given device
---@param device_label DeviceLabel device to access
---@param function_key_name string name of the function key
---@return boolean
function M.isDeviceKeyDown(device_label, function_key_name)
    if device_label.device_type == "keyboard" then
        return key_mapping.isKeyboardKeyDown(function_key_name)
    elseif device_label.device_type == "controller" then
        return key_mapping.isControllerKeyDown(device_label.device, function_key_name)
    else
        error("ERROR: Unknown device type!")
    end
end

---return if there exists a device among active devices, and on that device, the given key is pressed
---@param function_key_name string name of the function key
---@return boolean true if any device presses the input; otherwise return false
function M.isAnyDeviceKeyDown(function_key_name)
    for i = 1, #_devices do
        if M.isDeviceKeyDown(_devices[i], function_key_name) then
            return true
        end
    end
    return false
end

---------------------------------------------------------------------------------------------------
---init

---load all connected devices
local function InputDeviceInit()
    _devices = {}
    _device_wait_queue = {}

    local keyboard_label = {
        device_type = "keyboard",
        device = nil,
    }
    _device_wait_queue[1] = keyboard_label

    local controllers = controller_helper.getAllControllerInfo()
    for _, controller in ipairs(controllers) do
        table.insert(_device_wait_queue, controller)
    end

    M.refreshDevices(3)

    -- devices may connect after this function is called;
    lstg.eventDispatcher:addListener("onInputDeviceConnect", function(device_label)
        table.insert(_device_wait_queue, device_label)
    end)

    -- devices may disconnect during the game
    lstg.eventDispatcher:addListener("onInputDeviceDisconnect", function(device_label)
        -- find device and remove it
        for i, label in ipairs(_devices) do
            if IsSameDevice(label, device_label) then
                table.remove(_devices, i)
                DeactivateDevice(device_label)
                return
            end
        end
        for i, label in ipairs(_device_wait_queue) do
            if IsSameDevice(label, device_label) then
                table.remove(_device_wait_queue, i)
                return
            end
        end
    end)
end

function M.init()
    key_mapping.init(setting.keyboard_keys, setting.controller_keys)

    InputDeviceInit()
end

return M