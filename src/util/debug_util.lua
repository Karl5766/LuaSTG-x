---------------------------------------------------------------------------------------------------
---debug_util.lua
---author: CHU
---desc: Declares a few functions for debug
---modifier:
---     Karl, 2021.3.11, split the code from plus/ to util/ and renamed the file; renamed a few
---     functions as well
---------------------------------------------------------------------------------------------------

---@class DebugUtil
local M = {}

---@brief 模拟TryCatch块
---@param t table 条件上下文
---
---执行一个try..catch..finally块
---当try语句中出现错误时，将把错误信息发送到catch语句块，否则返回try函数结果
---当catch语句块被执行时，若发生错误将重新抛出，否则返回catch函数结果
---finally块总是会保证在try或者catch后被执行
function M.simulateTryCatch(t)
    assert(t.try ~= nil, "invalid argument.")

    local ret = {
        xpcall(t.try,
               function(err)
                   return err
                           .. "\n<=== inner traceback ===>\n"
                           .. debug.traceback()
                           .. "\n<=======================>"
               end)
    }
    if ret[1] == true then
        if t.finally then
            t.finally()
        end
        return unpack(ret, 2)
    else
        local cret

        if t.catch then
            cret = {
                xpcall(t.catch(ret[2]),
                       function(err)
                           return "error in catch block: "
                                   .. err
                                   .. "\n<=== inner traceback ===>\n"
                                   .. debug.traceback()
                                   .. "\n<=======================>"
                       end)
            }
        end

        if t.finally then
            t.finally()
        end

        if cret == nil then
            error("unhandled error: " .. ret[2])
        else
            if cret[1] == true then
                return unpack(cret, 2)
            else
                error(cret[2])
            end
        end
    end
end

---create an error message box and exit the game;
---for desktop error message
---@param message string error message to display
---@param title string title of the message box
function M.errorAndExitOnDesktop(message, title)
    lstg.MessageBox(message, title)
    lstg.FrameEnd()
    os.exit()
end

---create an error message box and exit the game;
---for mobile error message
---@param message string error message to display
---@param title string title of the message box
function M.errorAndExitOnMobile(message, title)
    require('cc.ui.MessageBox').OK(title, message, function()
        cc.Director:getInstance():endToLua()
    end)
    for _, v in ipairs({ 'FrameFunc' }) do
        _G[v] = function()
        end
    end
end

---create a error message box of the given message and title;
---repeat the error in lstg_log.txt and the debug console;
---exit the game after that
---@param message string error message to display
---@param title string title of the message box
function M.error(message, title)
    print(message)  -- debug console
    lstg.SystemLog(message)  -- in log file

    local platform_info = require("platform.platform_info")
    if platform_info.isMobile() then
        M.errorAndExitOnMobile(message, title)
    else
        M.errorAndExitOnDesktop(message, title)
    end
end

return M