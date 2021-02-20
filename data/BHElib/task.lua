---------------------------------------------------------------------------------------------------
---task.lua
---date: 2021.2.16
---desc: Defines tasks (coroutines) for game objects
---modifier:
---     Karl, 2021.2.16, deleted the move_to functions temporarily
---------------------------------------------------------------------------------------------------

task = {}

local task = task
local _object_stack = {}  -- corresponding objects of the tasks
local _task_stack = {}  -- current task stack; similar to function call stack

local max = math.max
local int = math.floor
local yield = coroutine.yield
local resume = coroutine.resume
local insert = table.insert
local ipairs = ipairs
local pairs = pairs
local status = coroutine.status
local rawget = rawget

---@~chinese 新建task，添加一个执行f的协程
---
---@~english create a new task, return its coroutine
---@param self Object the object to put the task under
---@param f function 要执行的函数
---@return thread the lua coroutine created for the new task
function task.New(self, f)
    if not self.task then
        self.task = {}
    end
    local rt = coroutine.create(f)
    insert(self.task, rt)
    return rt
end

---@~chinese 执行（resume）task中的协程；清除已执行完的task
---
---@~english execute all the tasks under self.task
---@param self Object tasks under this object will be executed
function task.Do(self)
    local task_list = rawget(self, 'task')  -- get self.task
    if task_list then
        local j = 0

        -- loop through every task under self.task table
        for i = 1, #task_list do
            local cur_task = task_list[i]
            if status(cur_task) ~= 'dead' then
                -- push into the stack before executing the task
                insert(_object_stack, self)
                insert(_task_stack, cur_task)

                -- run the task
                local _, errmsg = resume(cur_task)
                if errmsg then
                    error(errmsg)
                end

                -- pop from the stack after executing the task
                _object_stack[#_object_stack] = nil
                _task_stack[#_task_stack] = nil

                task_list[i] = nil
                j = j + 1
                task_list[j] = cur_task
            else
                task_list[i] = nil
            end
        end
    end
end

---@~chinese 清空self.tasks
---
---@~english clear all tasks in self.tasks
---@param self Object clear tasks of this object
function task.Clear(self)
    self.task = nil
end

---@~chinese 清空self.tasks中除当前执行的task之外所有tasks; 如不包含当前task则清空所有task
---
---@~english clear every task in self.tasks except the currently running task
---@param self Object clear tasks of this object
function task.ClearExcept(self)
    local flag = false
    local cur_task = _task_stack[#_task_stack]
    for i = 1, #self.task do
        if self.task[i] == cur_task then
            flag = true
            break
        end
    end
    self.task = nil
    if flag then
        self.task = { cur_task }
    end
end

---@~chinese 等待t帧（挂起协程t次）
---
---@~english wait t frames (call coroutine.yield() t times)
---@param t number the time to wait in frames, wait 1 frame if t is nil
function task.Wait(t)
    t = t or 1
    t = max(1, int(t))
    for i = 1, t do
        yield()
    end
end

---@~chinese 等待到timer达到t（挂起协程）
---
---@~english wait until the value of self.timer is as large as t
---@param t number the end value of self.timer
function task.Until(t)
    t = int(t)
    while task.GetSelf().timer < t do
        yield()
    end
end

---@~chinese 获取当前task（协程）对应的对象
---
---@~english get the object of the currently executing task
---@return Object the object this task is executing under
function task.GetSelf()
    return _object_stack[#_object_stack]
end