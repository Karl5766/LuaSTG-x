---------------------------------------------------------------------------------------------------
---task.lua
---date: 2021.2.16
---desc: Defines tasks (coroutines) for game objects
---modifier:
---     Karl, 2021.2.16, deleted the move_to functions temporarily
---------------------------------------------------------------------------------------------------

task = {}

local task = task
task.stack = {}
task.co = {}

local max = math.max
local int = math.floor
local yield = coroutine.yield
local resume = coroutine.resume
local insert = table.insert
local ipairs = ipairs
local pairs = pairs
local status = coroutine.status
local rawget = rawget

---新建任务 添加一个执行f的协程
---@param self table the object to put the task under
---@param f function 要执行的函数
function task.New(self, f)
    if not self.task then
        self.task = {}
    end
    local rt = coroutine.create(f)
    insert(self.task, rt)
    return rt
end

--TODO

---@~chinese 执行（resume）task中的协程
---
---@~english execute all the tasks under self.task
---
---@param self Object tasks under this object will be executed
function task.Do(self)
    local tsk = rawget(self, 'task')
    if tsk then
        for _, co in pairs(tsk) do
            if status(co) ~= 'dead' then
                insert(task.stack, self)
                insert(task.co, co)

                local _, errmsg = resume(co)
                if errmsg then
                    error(errmsg)
                end

                task.stack[#task.stack] = nil
                task.co[#task.co] = nil
            end
        end
    end
end

---清空self.tasks
function task.Clear(self)
    self.task = nil
end

---清空self.tasks除当前执行的task之外所有tasks;
---@param self Object the object to clear tasks of
function task.ClearExcept(self)
    local flag = false
    local co = task.co[#task.co]
    for i = 1, #self.task do
        if self.task[i] == co then
            flag = true
            break
        end
    end
    self.task = nil
    if flag then
        self.task = {}
        self.task[1] = co
    end
end

---延时t帧（挂起协程t次）,t省略则为1
---@param t number
function task.Wait(t)
    t = t or 1
    t = max(1, int(t))
    for i = 1, t do
        yield()
    end
end

---延时至timer达到t（挂起协程）
---@param t number
function task.Until(t)
    t = int(t)
    while task.GetSelf().timer < t do
        yield()
    end
end

---获取当前任务（协程）对应的对象
function task.GetSelf()
    local c = task.stack[#task.stack]
    if c.taskself then
        return c.taskself
    else
        return c
    end
end