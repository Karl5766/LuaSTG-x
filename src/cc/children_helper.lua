local M = {}

function M.getChildrenGraph(node)
    local name = ''
    if node.getName then
        name = node:getName()
    end
    local ret = {}
    if name == '' then
        name = tostring(node['.classname']) .. ' | ' .. tostring(node)
    end
    if node.getChildren then
        ret = { name = name, node = node, children = {} }
        for _, v in ipairs(node:getChildren()) do
            table.insert(ret.children, M.getChildrenGraph(v))
        end
    end
    return ret
end

---Save the value at name..num under table t;
---num is the least number that t[name..num] is false/nil.
local function save(t, name, value)
    if t[name] then
        for i = 1, 100 do
            local name_ = name .. i
            if not t[name_] then
                t[name_] = value
                return
            end
        end
    end
    t[name] = value
end

---Recursively return a list of t[node_name] = node of a node and all its children.
---"classname | tostring(node)..num" will be used as node_name if getName() is not implemented
---@param node node an object that implements the classname, tostring(), getName() and getChildren() interfaces
---@param t table if set, return under the table instead of creating a new one
function M.getChildrenWithName(node, t)
    t = t or {}
    local name = ''
    if node.getName then
        name = node:getName()
    end
    if name == '' then
        name = tostring(node['.classname']) .. ' | ' .. tostring(node)
    end
    if node.getChildren then
        save(t, name, node)
        for _, v in ipairs(node:getChildren()) do
            M.getChildrenWithName(v, t)
        end
    end
    return t
end

return M
