---------------------------------------------------------------------------------------------------
---key_mapping.lua
---date created: 2021.3.3
---desc: Manages the saving, loading and querying of function keys on keyboard and controller;
---     saving and loading refers to reading and writing of setting file;
---------------------------------------------------------------------------------------------------

---@class SettingKeysManager
local M = {}

local controller_helper = require("platform.controller_helper")

---below defines some mapping from function key name to the keys of the device
---name of the function keys and the mapping are specified in the setting file

---keyboard
local _keyboard_keymap
---controller; all controllers use the same mapping
local _controller_keymap

---init setting tables
local _keyboard_setting
local _controller_setting

---cache variables and functions

local _GetKeyState = lstg.GetKeyState

---------------------------------------------------------------------------------------------------
---init

---initialize keyboard and controller key mappings from the setting;
---this function should only be called on application startup
function M.init(keyboard_keys, controller_keys)
    _keyboard_keymap = {}
    _keyboard_setting = keyboard_keys
    M.copyMapping(_keyboard_keymap, keyboard_keys)

    _controller_keymap = {}
    _controller_setting = controller_keys
    M.copyMapping(_controller_keymap, controller_keys)
end

---------------------------------------------------------------------------------------------------
---getters

---@param function_key_name string name of the function key
---@return boolean if the corresponding keyboard key is down
function M.isKeyboardKeyDown(function_key_name)
    local keyboard_keycode = _keyboard_keymap[function_key_name]
    return _GetKeyState(keyboard_keycode)
end

---@param controller cc.Controller the controller to check
---@param function_key_name string name of the function key
---@return boolean if the corresponding controller key is down
function M.isControllerKeyDown(controller, function_key_name)
    local controller_keycode = _controller_keymap[function_key_name]
    return controller_helper.getKeyState(controller, controller_keycode[1], controller_keycode[2])
end

---------------------------------------------------------------------------------------------------
---setters

---@param function_key_name string name of the function key
function M.setKeyboardKeyMapping(function_key_name, keyboard_keycode)
    _keyboard_keymap[function_key_name] = keyboard_keycode
end

---@param function_key_name string name of the function key
function M.rememberKeyboardKeyMapping(function_key_name, keyboard_keycode)
    _keyboard_setting[function_key_name] = keyboard_keycode
end

---@param function_key_name string name of the function key
function M.setControllerGameKey(function_key_name, controller_key)
    _controller_keymap[function_key_name] = controller_key
end

---@param function_key_name string name of the function key
function M.rememberControllerGameKey(function_key_name, controller_key)
    _controller_setting[function_key_name] = controller_key
end

---------------------------------------------------------------------------------------------------

---load mapping from one table to another
---@param mapping_table table table to load into
---@param setting_mapping_table table table to load from
function M.copyMapping(mapping_table, setting_mapping_table)
    for function_key_name, device_key in pairs(setting_mapping_table) do
        mapping_table[function_key_name] = device_key
    end
end

return M