---------------------------------------------------------------------------------------------------
---task.lua
---date: 2021.2.16
---desc: Defines tasks (coroutines) for game objects
---modifier:
---     Karl, 2021.2.16, deleted the move_to functions temporarily
---     2021.8.30, deleted the maintenance of object and task stacks and some uncommonly used
---     functions; implemented task deletion using swap
---------------------------------------------------------------------------------------------------

task = {}

local task = task

---------------------------------------------------------------------------------------------------
---cache variables and functions

local max = math.max
local int = math.floor
local yield = coroutine.yield
local resume = coroutine.resume
local insert = table.insert
local status = coroutine.status
local rawget = rawget

---------------------------------------------------------------------------------------------------

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
---@param self table tasks under this object will be executed
function task.Do(self)
    local task_list = rawget(self, "task")  -- get self.task
    if task_list then
        -- loop through every task under self.task table
        local i = 1
        while i <= #task_list do
            local cur_task = task_list[i]
            if status(cur_task) ~= "dead" then
                -- push into the stack before executing the task
                --insert(_object_stack, self)
                --insert(_task_stack, cur_task)

                -- run the task
                local success, errmsg = resume(cur_task)
                if errmsg then
                    error(errmsg)
                end
                i = i + 1

                -- pop from the stack after executing the task
                --_object_stack[#_object_stack] = nil
                --_task_stack[#_task_stack] = nil
            else
                -- this implementation may break some important assumptions on tasks, but it should be relatively efficient
                local n = #task_list
                task_list[i] = task_list[n]
                task_list[n] = nil
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