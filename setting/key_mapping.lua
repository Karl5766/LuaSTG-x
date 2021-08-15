---------------------------------------------------------------------------------------------------
---key_mapping.lua
---date created: 2021.3.3
---desc: Manages the saving, loading and querying of function keys on keyboard and controller;
---     saving and loading refers to reading and writing of setting file; provides apis for
---     accessing raw (most up-to-time) keyboard and controller input
---------------------------------------------------------------------------------------------------

---@class SettingKeysManager
local M = {}

local controller_helper = require("platform.controller_helper")

---maps from device id to device label
local _devices
local _next_device_id = 1

---below defines some mapping from function key name to the keys of the device
---name of the function keys and the mapping are specified in the setting file
---although function key names are defined in setting, their categorization to game keys and system
---keys are defined in data/

---keyboard
local _keyboard_keymap
---controller; all controllers use the same mapping
local _controller_keymap

---initial key mapping setting tables
---@type JsonFileMirror
local _setting_file_mirror
local _keyboard_setting
local _controller_setting

---------------------------------------------------------------------------------------------------
---cache variables and functions

local _GetKeyState = lstg.GetKeyState
local _IsKeyboardKeyDown
local _IsControllerKeyDown
local _IsDeviceKeyDown

---------------------------------------------------------------------------------------------------
---getter

---get a device's label by its id
---@param device_id number id of the device
function M:getDeviceByID(device_id)
    return _devices[device_id]
end

---@return number number of keyboard/controller devices connected
function M:getDeviceCount()
    local n = 0
    for _, _ in pairs(_devices) do
        n = n + 1
    end
    return n
end

---get an array of currently active device id
---@return table an array of all device id
function M:getDeviceIDArray()
    local result = {}
    for device_id, _ in pairs(_devices) do
        table.insert(result, device_id)
    end
    return result
end

---------------------------------------------------------------------------------------------------
---setters

---@param function_key_name string name of the function key
function M:setKeyboardKeyMapping(function_key_name, keyboard_keycode)
    _keyboard_keymap[function_key_name] = keyboard_keycode
end

---@param function_key_name string name of the function key
function M:rememberKeyboardKeyMapping(function_key_name, keyboard_keycode)
    _keyboard_setting[function_key_name] = keyboard_keycode
    _setting_file_mirror:syncToFile()
end

---@param function_key_name string name of the function key
function M:setControllerGameKey(function_key_name, controller_key)
    _controller_keymap[function_key_name] = controller_key
end

---@param function_key_name string name of the function key
function M:rememberControllerGameKey(function_key_name, controller_key)
    _controller_setting[function_key_name] = controller_key
    _setting_file_mirror:syncToFile()
end

---------------------------------------------------------------------------------------------------
---access the input

---raise an error if the given key does not have a corresponding mapping
---@param function_key_name string name of the function key
---@return boolean if the corresponding keyboard key is down
function M:isKeyboardKeyDown(function_key_name)

    local keyboard_keycode = _keyboard_keymap[function_key_name]
    assert(keyboard_keycode, "Error: Keyboard mapping for \""..function_key_name.."\" is nil!")

    return _GetKeyState(keyboard_keycode)
end
_IsKeyboardKeyDown = M.isKeyboardKeyDown

---return false if the given key does not have a corresponding mapping
---@param controller_id number id of the controller to check
---@param function_key_name string name of the function key
---@return boolean if the corresponding controller key is down
function M.isControllerKeyDown(controller_id, function_key_name)
    local controller_keycode = _controller_keymap[function_key_name]
    if controller_keycode == nil then
        return false
    else
        return controller_helper.getKeyState(controller_id, controller_keycode[1], controller_keycode[2])
    end
end
_IsControllerKeyDown = M.isControllerKeyDown

---get raw input from the given device
---@param device_index number device index in the device table
---@param function_key_name string name of the function key
---@return boolean if the key is down; guaranteed not nil
function M:isDeviceKeyDown(device_index, function_key_name)
    local device_label = _devices[device_index]
    if device_label.device_type == "keyboard" then
        return _IsKeyboardKeyDown(self, function_key_name) == true
    elseif device_label.device_type == "controller" then
        return _IsControllerKeyDown(device_label.device, function_key_name) == true
    else
        error("ERROR: Unknown device type!")
    end
end
_IsDeviceKeyDown = M.isDeviceKeyDown

---return if there exists a device among active devices, and on that device, the given key is pressed
---@param function_key_name string name of the function key
---@return boolean true if any device presses the input; otherwise return false
function M:isAnyDeviceKeyDown(function_key_name)
    for i, _ in pairs(_devices) do
        if _IsDeviceKeyDown(self, i, function_key_name) then
            return true
        end
    end
    return false
end

local _GetMousePosition = lstg.GetMousePosition
local _glv = cc.Director:getInstance():getOpenGLView()
---@~chinese 获取鼠标的resolution坐标系位置，以窗口左下角为原点。
---
---@~english Get mouse position in resolution coordinates starts from the bottom left of the window.
---
---@return number,number
function M:getMousePosition()
    local res = _glv:getDesignResolutionSize()
    local rect = _glv:getViewPortRect()
    local x, y = _GetMousePosition()
    y = res.height - y
    x = x + rect.x / _glv:getScaleX()
    y = y + rect.y / _glv:getScaleY()
    --local ui_scale_x, ui_scale_y = require("BHElib.unclassified.coordinates_and_screen").getUIScale()
    --x = x / ui_scale_x
    --y = y / ui_scale_y
    return x, y
end

---@return boolean, boolean, boolean button1, button2, button3
function M:getMouseState()
    local b1 = GetMouseState(1)
    local b2 = GetMouseState(2)
    local b3 = GetMouseState(3)
    return b1, b2, b3
end

---------------------------------------------------------------------------------------------------
---DeviceLabel is a structure represents an input device
---struct DeviceLabel {
---     device_type,  -- string, can be "keyboard" or "controller"
---     device,  -- reference to the device; can be nil if the device is unique of its type
---}

---return if the two device labels are identical
---@param device_label1 DeviceLabel
---@param device_label2 DeviceLabel
---@return boolean true if two labels are the same
function M:isSameDevice(device_label1, device_label2)
    return device_label1.device_type == device_label2.device_type and device_label1.device == device_label2.device
end

---------------------------------------------------------------------------------------------------
---insertions and deletions

---Add a device to the active device table
---@param device_label DeviceLabel the device to insert
local function InsertDevice(device_label)
    assert(M:getDeviceCount() < 25, "Assertion failed: Too many input devices connected")

    _devices[_next_device_id] = device_label
    _next_device_id = _next_device_id + 1
end

---remove a device from devices table by its device id
---@param device_id number the id of the device to remove
local function DeleteDevice(device_id)
    _devices[device_id] = nil
end

---------------------------------------------------------------------------------------------------
---init

---load all connected devices
---this function should only be called on application startup
local function InputDeviceInit()

    -- initialize active device table
    _devices = {}

    local keyboard_label = {
        device_type = "keyboard",
        device = nil,
    }
    InsertDevice(keyboard_label)

    local controllers = controller_helper.getAllControllerLabels()
    for _, label in ipairs(controllers) do
        InsertDevice(label)
    end

    -- devices may connect after this function is called;
    lstg.eventDispatcher:addListener("onInputDeviceConnect", function(device_label)
        InsertDevice(device_label)
    end)

    -- devices may disconnect during the game
    lstg.eventDispatcher:addListener("onInputDeviceDisconnect", function(device_label)
        -- find device and remove it
        for id, label in pairs(_devices) do
            if M:isSameDevice(label, device_label) then
                DeleteDevice(id)
                return
            end
        end
        error("ERROR: Disconnected device is not found in devices table! ")
    end)
end

---initialize keyboard and controller key mappings from the setting;
---this function should only be called on application startup
local function KeyMappingInit(setting_file_mirror, keyboard_keys, controller_keys)
    _setting_file_mirror = setting_file_mirror

    _keyboard_setting = keyboard_keys
    _keyboard_keymap = table.deepcopy(keyboard_keys)

    _controller_setting = controller_keys
    _controller_keymap = table.deepcopy(controller_keys)
end

---this function should only be called on application startup
function M:init()
    local setting_file_mirror = require("setting.setting_file_mirror")
    local file_content = setting_file_mirror:getContent()
    KeyMappingInit(setting_file_mirror, file_content.keyboard_keys, file_content.controller_keys)

    InputDeviceInit()
end

return M