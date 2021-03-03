---------------------------------------------------------------------------------------------------
---ControllerHelper.lua
---desc: Provides basic apis for checking the key states of controllers
---modifier:
---     Karl, 2021.3.3,
---------------------------------------------------------------------------------------------------


local M = {}
--require('cocos.controller.ControllerConstants')
--local _KEY = cc.ControllerKey

-- key and axis may have same code
---status lists status_list[controller][controller_keycode]
local status_button = {}
local status_axis = {}
local status_axis_pos = {}
local status_axis_neg = {}
function M.getInnerStatus()
    return status_button, status_axis
end

local mapping = { button = {}, axis = { pos = {}, neg = {} } }
---maps a particular keyboard keycode to its status list and its index in the list
local mapping_inv = {}

--

---initialize the info about the given controller on connect
---@param controller cc.Controller
local function onConnect(controller)
    local name = controller:getDeviceName()
    local id = controller:getDeviceId()
    Print(string.format('controller connected: name: %q, id: %d', name, id))
    status_button[controller] = {}
    status_axis[controller] = {}
    status_axis_pos[controller] = {}
    status_axis_neg[controller] = {}
end

---@param c cc.Controller
local function onDisconnect(controller)
    local name = controller:getDeviceName()
    local id = controller:getDeviceId()
    Print(string.format('controller disconnected: name: %q, id: %d', name, id))
    status_button[controller] = nil
    status_axis[controller] = nil
    status_axis_pos[controller] = nil
    status_axis_neg[controller] = nil
    --mapping[c] = nil
end

---if c is not connected, connect c
local function CheckAndConnect(controller)
    if not status_button[controller] then
        onConnect(controller)
    end
end

local _last

---@param id any device id number
---@param keycode number keycode of the key
---@param is_axis boolean is controller axis
---@param is_pos boolean
local function _is_last(id, keycode, is_axis, is_pos)
    if _last then
        return _last.id == id and _last.key == keycode and _last.is_axis == is_axis and _last.is_pos == is_pos
    end
end

---@param controlle cc.Controller
---@param keycode number
---@param value any
---@param isPressed boolean
---@param isAnalog boolean
local function onKeyDown(controller, keycode, value, isPressed, isAnalog)
    if keycode >= 1000 then
        keycode = keycode - 1000
    end
    CheckAndConnect(controller)
    status_button[controller][keycode] = true
    --local code = -1
    --for k, v in pairs(mapping_inv) do
    --    if v.key == keycode and not v.is_axis then
    --        code = k
    --        break
    --    end
    --end
    --Print(string.format('[CTR] %d down: %02d => %d', c:getDeviceId(), keycode, code))
    _last = {
        id  = controller:getDeviceId(),
        key = keycode,
    }
end

local function onKeyUp(c, keycode, value, isPressed, isAnalog)
    if keycode >= 1000 then
        keycode = keycode - 1000
    end
    --Print(string.format('[CTR] %d   up: %02d', c:getDeviceId(), keycode))
    CheckAndConnect(c)
    status_button[c][keycode] = false
    if _is_last(c:getDeviceId(), keycode, nil, nil) then
        _last = nil
    end
end

local _threshold = 0.6
local _axis_t = {
    { nil, { nil, true }, { false, true }, },
    { { nil, false }, nil, { false, nil }, },
    { { true, false }, { true, nil }, nil, },
}
local function _set_axis(c, keycode, posVal, negVal)
    if posVal ~= nil then
        status_axis_pos[c][keycode] = posVal
        if posVal then
            _last = {
                id      = c:getDeviceId(),
                key     = keycode,
                is_axis = true,
                is_pos  = true,
            }
        else
            if _is_last(c:getDeviceId(), keycode, true, true) then
                _last = nil
            end
        end
    end
    if negVal ~= nil then
        status_axis_neg[c][keycode] = negVal
        if negVal then
            _last = {
                id      = c:getDeviceId(),
                key     = keycode,
                is_axis = true,
                is_pos  = false,
            }
        else
            if _is_last(c:getDeviceId(), keycode, true, false) then
                _last = nil
            end
        end
    end
end

local function onAxisEvent(c, keycode, value, isPressed, isAnalog)
    if keycode >= 1000 then
        keycode = keycode - 1000
    end
    CheckAndConnect(c)
    local last = status_axis[c][keycode]
    if not last then
        status_axis[c][keycode] = value
        last = value
    end
    --if math.abs(last - value) < 0.1 then
    --    return
    --end
    status_axis[c][keycode] = value
    local i1, i2
    if value < -_threshold then
        i1 = 1
    elseif value > _threshold then
        i1 = 3
    else
        i1 = 2
    end
    if last < -_threshold then
        i2 = 1
    elseif last > _threshold then
        i2 = 3
    else
        i2 = 2
    end
    local val = _axis_t[i1][i2]
    if val then
        _set_axis(c, keycode, val[1], val[2])
        --Print('set_axis', keycode, string.format('%.3f', last), string.format('%.3f', value), val[1], val[2])
    end
end

function M.init()
    for _, v in ipairs(GetAllControllers()) do
        onConnect(v)
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

    M.loadFromSetting(setting.controller_map.keys, setting.controller_map.keysys)
end

---@param keycode number the keycode of the key to be checked
---@return boolean true if any controller presses this key at the moment
function M.getStatus(keycode)
    local m = mapping_inv[keycode]
    if not m then
        return
    end
    local target_status
    if m.is_axis then
        if m.is_pos then
            target_status = status_axis_pos
        else
            target_status = status_axis_neg
        end
    else
        target_status = status_button
    end
    --Print(m.key, m.is_axis, m.is_pos)
    for _, controller in pairs(target_status) do
        return controller[m.key]
    end
end

function M.getLast()
    return _last
end

---@return number the corresponding keycode of the last key; if no key is found, return 0
function M.getLastKey()
    local ret
    if _last then
        local key = _last.key
        if _last.is_axis then
            if _last.is_pos then
                ret = mapping.axis.pos[key]
            else
                ret = mapping.axis.neg[key]
            end
        else
            ret = mapping.button[key]
        end
    end
    return ret or 0
end

---initialize mapping and mapping_inv tables
---@param game_keys table a map from every in-game key names (E.g. "slow") to its controller setting keycode
---@param system_keys table a map from every system key names to its controller setting keycode
function M.loadFromSetting(game_keys, system_keys, keyboard_game_keys, keyboard_system_keys)
    mapping = { button = {}, axis = { pos = {}, neg = {} } }
    for key_function_name, controller_keycode in pairs(game_keys) do
        local keyboard_keycode = setting.keys[key_function_name]
        local keycode = controller_keycode[1] or -1
        mapping_inv[keyboard_keycode] = { key = keycode }
        if #controller_keycode > 1 then
            mapping_inv[keyboard_keycode].is_axis = true
            if controller_keycode[2] then
                mapping.axis.pos[keycode] = keyboard_keycode
                mapping_inv[keyboard_keycode].is_pos = true
            else
                mapping.axis.neg[keycode] = keyboard_keycode
                mapping_inv[keyboard_keycode].is_pos = false
            end
        else
            mapping.button[keycode] = keyboard_keycode
        end
    end
    for k, v in pairs(system_keys) do
        local keyboard_keycode = setting.keysys[k]
        local keycode = v[1] or -1
        mapping_inv[keyboard_keycode] = { key = keycode }
        if #v > 1 then
            mapping_inv[keyboard_keycode].is_axis = true
            if v[2] then
                mapping.axis.pos[keycode] = keyboard_keycode
                mapping_inv[keyboard_keycode].is_pos = true
            else
                mapping.axis.neg[keycode] = keyboard_keycode
                mapping_inv[keyboard_keycode].is_pos = false
            end
        else
            mapping.button[keycode] = keyboard_keycode
        end
    end
    --Print(stringify(mapping))
    --Print(stringify(mapping_inv))
end

---for controller setting menu
function M.convertSetting()
    local ret = {}
    if setting.controller_map then
        local keys = setting.controller_map.keys or {}
        local keysys = setting.controller_map.keysys or {}
        for k, v in pairs(keys) do
            ret[k] = { v[1], v[2] }
        end
        for k, v in pairs(keysys) do
            ret[k] = { v[1], v[2] }
        end
    end
    return ret
end

function M.setMapping(name, key, is_axis, is_pos)
    local k1 = setting.controller_map.keys[name]
    local k2 = setting.controller_map.keysys[name]
    local s = is_axis and { key, is_pos } or { key }
    local ik
    if k1 then
        setting.controller_map.keys[name] = s
        ik = setting.keys[name]
    elseif k2 then
        setting.controller_map.keysys[name] = s
        ik = setting.keysys[name]
    end
    mapping_inv[ik] = { key = key }
    if is_axis then
        mapping_inv[ik].is_axis = true
        if is_pos then
            mapping.axis.pos[key] = ik
            mapping_inv[ik].is_pos = true
        else
            mapping.axis.neg[key] = ik
            mapping_inv[ik].is_pos = false
        end
    else
        mapping.button[key] = ik
    end
end

return M
