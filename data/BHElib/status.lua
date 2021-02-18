---@~chinese del对象的附属，将对象状态置为"del"
---
---@~english delete the object and its servants; the status of object will be set to "del" so it is recognized to be
---deleted by the engine at the end of the frame
---@param o Object the object to be marked as deleted
function RawDel(o)
    if o then
        o.status = "del"
        if o._servants then
            _del_servants(o)
        end
    end
end

---@~chinese kill对象的附属，将对象状态置为"kill"
---
---@~english kill the object and its servants; the status of object will be set to "kill" so it is recognized to be
---killed by the engine at the end of the frame
---@param o Object the object to be marked as killed
function RawKill(o)
    if o then
        o.status = "kill"
        if o._servants then
            _kill_servants(o)
        end
    end
end

---@~chinese 将对象状态置为"normal"
---
---@~english set the status of object as "normal"
---@param o Object the object to be preserved, as to not be deleted/killed at the end of the frame
function PreserveObject(o)
    o.status = "normal"
end

--重写内置的Kill，kill对象的附属
do
    local old = lstg.Kill
    function Kill(o)
        if o then
            if o._servants then
                _kill_servants(o)
            end
            old(o)
        end
    end
end

--重写内置的Del，del对象的附属
do
    local old = lstg.Del
    function Del(o)
        if o then
            if o._servants then
                _del_servants(o)
            end
            old(o)
        end
    end
end
