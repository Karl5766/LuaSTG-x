---按键状态
KeyState = {}
---上一帧按键状态
KeyStatePre = {}

local _GetKeyState = lstg.GetKeyState
local _GetLastKey = lstg.GetLastKey
local ch = require('platform.controller_helper')

---@~chinese 返回最后一次输入的按键的按键代码。
---
---@~english Returns code of last pressed key.
---
---@return number
function GetLastKey()
    local ret = _GetLastKey()
    if ret == 0 then
        --return ch.getLastKey()
    else
        return ret
    end
end

---key是否被按下
---@param key string
---@return boolean
function KeyIsDown(key)
    return KeyState[key]
end

---key是否刚刚被按下
---@param key string
---@return boolean
function KeyIsPressed(key)
    return KeyState[key] and (not KeyStatePre[key])
end

---key是否被按下
KeyPress = KeyIsDown

---key是否刚刚被按下
KeyTrigger = KeyIsPressed

---key是否刚刚松开
---@param key string
---@return boolean
function KeyIsReleased(key)
    return KeyStatePre[key] and (not KeyState[key])
end