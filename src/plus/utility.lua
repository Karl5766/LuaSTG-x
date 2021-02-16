local function classCreater(instance, class, ...)
    local ctor = rawget(class, "init")
    if ctor then
        ctor(instance, ...)  ---在有构造函数的情况下直接调用
    else
        ---在没有构造函数的情况下去调用基类的构造函数
        local super = rawget(class, "super")
        if super then
            classCreater(instance, super, ...)
        end
    end
end

---@brief 声明一个类
---@param base table 基类
function plus.Class(base)
    local class = { _mbc = {}, super = base }

    local function new(t, ...)
        local instance = {}
        setmetatable(instance, { __index = t })
        classCreater(instance, t, ...)
        return instance
    end

    local function indexer(t, k)
        local member = t._mbc[k]
        if member == nil then
            if base then
                member = base[k]
                t._mbc[k] = member
            end
        end
        return member
    end

    setmetatable(class, {
        __call  = new,
        __index = indexer
    })

    return class
end

---@brief 模拟TryCatch块
---@param t table 条件上下文
---
---执行一个try..catch..finally块
---当try语句中出现错误时，将把错误信息发送到catch语句块，否则返回try函数结果
---当catch语句块被执行时，若发生错误将重新抛出，否则返回catch函数结果
---finally块总是会保证在try或者catch后被执行
function plus.TryCatch(t)
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

---gives an error by a messagebox
---@param msg string
---@param title string
---@param exit boolean true if omitted
function plus.error(msg, title, exit)
    msg = msg or ''
    title = title or ''
    exit = exit or (exit == nil)
    local emsg = exit and ', exit' or ''
    SystemLog(string.format('error: [%s]%s' .. emsg, title, msg))
    MessageBox(msg, title)
    if exit then
        lstg.FrameEnd()
        os.exit()
    end
end