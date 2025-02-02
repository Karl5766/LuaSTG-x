---------------------------------------------------------------------------------------------------
---controller_helper.lua
---desc: Provides basic apis for checking the key states of controllers
---modifier:
---     Karl, 2021.3.3, clean up of the code
---------------------------------------------------------------------------------------------------

local M = {}
--require('cocos.controller.ControllerConstants')
--local _KEY = cc.ControllerKey

-- key and axis may have same code
---status lists; status is retrieved by accessing status_list[controller][key]
---buttons, values are true/false; when uninitialized, is nil; nil is treated the same as false
local status_button = {}

---an axis represents one of xy directions; values are number in [-1, 1]; when uninitialized, is nil
local status_axis = {}
---both status_axis_positive and status_axis_negative can have nil values
local _threshold = 0.6
---changed as status_axis table change; is set to true when the axis passes +threshold; is set to false otherwise
local status_axis_positive = {}
---changed as status_axis table change; is set to true when the axis is less than -threshold; is set to false otherwise
local status_axis_negative = {}

---------------------------------------------------------------------------------------------------

---print a connection message and initialize status lists about the newly connected controller
---@param controller cc.Controller
local function onConnect(controller)
    local name = controller:getDeviceName()
    local controller_id = controller:getDeviceId()
    Print(string.format('controller connected: name: %q, id: %d', name, controller_id))
    status_button[controller_id] = {}
    status_axis[controller_id] = {}
    status_axis_positive[controller_id] = {}
    status_axis_negative[controller_id] = {}
    local event_param = {
        device_type = "controller",
        device = controller_id,
    }
    lstg.eventDispatcher:dispatchEvent('onInputDeviceConnect', event_param)
end

---print a disconnection message and set corresponding status lists' controller sections to nil
---@param controller cc.Controller
local function onDisconnect(controller)
    local name = controller:getDeviceName()
    local controller_id = controller:getDeviceId()
    Print(string.format('controller disconnected: name: %q, id: %d', name, controller_id))
    status_button[controller_id] = nil
    status_axis[controller_id] = nil
    status_axis_positive[controller_id] = nil
    status_axis_negative[controller_id] = nil
    local event_param = {
        device_type = "controller",
        device = controller_id,
    }
    lstg.eventDispatcher:dispatchEvent('onInputDeviceDisconnect', event_param)
end

---return if a controller has been connected to the game
---@param controller_id number the controller to check
---@return boolean whether the controller is connected
function M.isControllerConnected(controller_id)
    return status_button[controller_id] ~= nil
end

---if the given controller is not connected, connect c
---@param controller_id number the id of the controller to check
local function CheckAndConnect(controller_id)
    if not status_button[controller_id] then
        local controller = cc.Controller:getControllerByDeviceId(controller_id)
        onConnect(controller)
    end
end

---------------------------------------------------------------------------------------------------

local _last

---@param id any controller device id number
---@param keycode number keycode of the key
---@param is_axis boolean is controller axis
---@param is_pos boolean
local function _is_last(id, keycode, is_axis, is_pos)
    if _last then
        return _last.id == id and _last.key == keycode and _last.is_axis == is_axis and _last.is_pos == is_pos
    end
end

function M.getLast()
    return _last
end

---------------------------------------------------------------------------------------------------
---On Key Down/Up


--local _unpressed = {}

---@param controller_id number
---@param keycode number controller keycode
---@param value any
---@param isPressed boolean
---@param isAnalog boolean
local function onKeyDown(controller_id, keycode, value, isPressed, isAnalog)
    if keycode >= 1000 then
        keycode = keycode - 1000
    end
    --if not _unpressed[keycode] then
    --    print(keycode)
    --    _unpressed[keycode] = true
    --end
    CheckAndConnect(controller_id)
    status_button[controller_id][keycode] = true

    _last = {
        id  = controller_id,
        key = keycode,
    }
end

---@param controller_id number
---@param keycode number controller keycode
---@param value any
---@param isPressed boolean
---@param isAnalog boolean
local function onKeyUp(controller_id, keycode, value, isPressed, isAnalog)
    if keycode >= 1000 then
        keycode = keycode - 1000
    end
    --Print(string.format('[CTR] %d   up: %02d', c:getDeviceId(), keycode))
    CheckAndConnect(controller_id)
    status_button[controller_id][keycode] = false
    if _is_last(controller_id, keycode, nil, nil) then
        _last = nil
    end
end

---------------------------------------------------------------------------------------------------
---On Axis Change

---_axis_t[cur_level][prev_level] = {(boolean)set_positive, (boolean)set_negative}
local _axis_t = {
    { nil, { nil, true }, { false, true }, },
    { { nil, false }, nil, { false, nil }, },
    { { true, false }, { true, nil }, nil, },
}
--_axis_t[1][2] = {nil, true}  -- from 2 to 1
--_axis_t[1][3] = {false, true}  -- from 3 to 1
--_axis_t[2][1] = {nil, false}  -- from 1 to 2
--_axis_t[2][3] = {false, nil}  -- from 3 to 2

local function _set_axis(controller_id, key, set_positive, set_negative)
    if set_positive ~= nil then
        status_axis_positive[controller_id][key] = set_positive
        if set_positive then
            _last = {
                id      = controller_id,
                key     = key,
                is_axis = true,
                is_pos  = true,
            }
        else
            if _is_last(controller_id, key, true, true) then
                _last = nil
            end
        end
    end
    if set_negative ~= nil then
        status_axis_negative[controller_id][key] = set_negative
        if set_negative then
            _last = {
                id      = controller_id,
                key     = key,
                is_axis = true,
                is_pos  = false,
            }
        else
            if _is_last(controller_id, key, true, false) then
                _last = nil
            end
        end
    end
end

local function onAxisEvent(controller_id, key, cur_position, isPressed, isAnalog)
    if key >= 1000 then
        key = key - 1000
    end
    CheckAndConnect(controller_id)

    local prev_position = status_axis[controller_id][key]
    status_axis[controller_id][key] = cur_position
    local cur_level, prev_level
    if cur_position < -_threshold then
        cur_level = 1
    elseif cur_position > _threshold then
        cur_level = 3
    else
        cur_level = 2
    end

    if not prev_position then
        prev_position = cur_position
    end
    if prev_position < -_threshold then
        prev_level = 1
    elseif prev_position > _threshold then
        prev_level = 3
    else
        prev_level = 2
    end

    local set_action = _axis_t[cur_level][prev_level]
    if set_action then
        _set_axis(controller_id, key, set_action[1],set_action[2])
    end
end

---------------------------------------------------------------------------------------------------

function M.init()
    for _, controller in ipairs(GetAllControllers()) do
        onConnect(controller)
    end
    SetOnControllerConnect(onConnect)
    SetOnControllerDisconnect(onDisconnect)
    SetOnControllerKeyDown(onKeyDown)
    SetOnControllerKeyUp(onKeyUp)
    SetOnControllerAxisEvent(onAxisEvent)

    cc.Director:getInstance():getEventDispatcher():addCustomEventListener(
            "director_after_update",
            function()
                _last = nil
            end
    )
    lstg.eventDispatcher:addListener('onFocusLose', function()
        _last = nil
    end, 100, 'controller.last.clear')
end

---return information about all the connected controllers
---@return table an array of controller device labels; see input_and_recording.lua
function M.getAllControllerLabels()
    local result = {}
    local controllers = GetAllControllers()
    for _, controller in ipairs(controllers) do
        local info = {
            device_type = "controller",
            device = controller:getDeviceId()
        }
        table.insert(result, info)
    end
    return result
end

---test if a controller key is pressed
---@param controller number id of the controller to check on
---@param key number the key value of the key to check; for non-axis keys, the next parameter axis_direction is nil
---@param axis_direction boolean if not nil, return the if the axis passes the threshold value at the specified direction;
---@return boolean
function M.getKeyState(controller_id, key, axis_direction)
    if axis_direction == nil then
        return status_button[controller_id][key] == true
    elseif axis_direction == true then
        return status_axis_positive[controller_id][key]
    else
        return status_axis_negative[controller_id][key]
    end
end

return M
