---------------------------------------------------------------------------------------------------
---game_object.lua
---date: 2021.2.16
---desc: Defines the inheritance of game objects, and two base classes Object and Object3d for all
---     other game objects to inherit from.
---modifier:
---     Karl, 2021.2.16, renamed the file from class.lua to game_object.lua. Removed the global
---     lists and changed to the same naming conventions as the rest of the project
---------------------------------------------------------------------------------------------------

-- names of the 6 callbacks that each game object has
local callbacks = { 'init', 'del', 'frame', 'render', 'colli', 'kill', }

---@~chinese 定义一个类，基类会给新类复制6个回调函数；新类的is_class属性会被设为true，base属性指向基类，
---
---@~chinese 新类会继承define表中所有非number类型的属性
---
---@~english Define a class, the callback_base will assign its 6 callbacks to the new class;
---
---@~english the new class will have is_class attribute set to ture, and base attribute set to
---callback_base
---
---@~english additionally, the new class will inherit all non-numerical attributes from attribute_base
---
---@~english the newly defined object class can be used in New() after it is registered as game class
---
------@param callback_base Object 新类继承此类的6个默认回调函数
-----@param define table 新类继承此表除默认回调函数外的所有等非数值属性
-----@return Object 新定义的类
function Class(callback_base, attribute_base)
    if (type(callback_base) ~= 'table') or not callback_base.is_class then
        error(i18n 'Invalid base class')
    end
    local new_class = { 0, 0, 0, 0, 0, 0 }
    if attribute_base then
        for k, v in pairs(attribute_base) do
            if type(k) ~= 'number' then
                new_class[k] = v
            end
        end
    end
    new_class.is_class = true
    new_class.init = callback_base.init
    new_class.del = callback_base.del
    new_class.frame = callback_base.frame
    new_class.render = callback_base.render
    new_class.colli = callback_base.colli
    new_class.kill = callback_base.kill
    new_class.base = callback_base
    return new_class
end

---------------------------------------------------------------------------------------------------
---base classes

---@~chinese 所有game object的基类
---
---@~English the base class of all game objects
---@type Object
Object = {
    0, 0, 0, 0, 0, 0;
    is_class = true,
    init     = function()
    end,
    del      = function()
    end,
    frame    = function()
    end,
    render   = DefaultRenderFunc,
    colli    = function(other)
    end,
    kill     = function()
    end
}

Object3d = Class(Object)
Object3d['.3d'] = true

---------------------------------------------------------------------------------------------------

local _class_num = 0  -- number of classes registered by RegisterGameClass()
local _class_id = {}  -- a table that maps registered game classes to their unique ids

---@~chinese 把class注册为game class；class的6个回调函数属性如果不是函数则设为默认回调函数
---
---@~chinese class会被赋予一个独一无二的整数id;class的".classname"会被设置为class对应的全局变量名；
---
---@~english register a class as game class; if its 6 callbacks are not of type "function",
---they will be set to default game object callback functions.
---
---@~english class will be assigned a unique id different from any other class registered
---by this function at index 7
---
---@param class Object the class to register
function RegisterGameClass(class)
    for i = 1, 6 do
        if type(class[i]) ~= "function" then
            class[i] = class[callbacks[i]]
        end
    end

    if class[3] == Object.frame then
        class[3] = nil
    end
    if class[4] == DefaultRenderFunc then
        class[4] = nil
    end

    if _class_id[class] == nil then
        _class_num = _class_num + 1
        _class_id[class] = _class_num
        class[7] = _class_num
    else
        class[7] = _class_id[class]
    end

    RegisterClass(class)

    local class_name
    for key, value in pairs(_G) do
        if value == class then
            class_name = key
            break
        end
    end
    class['.classname'] = class_name
end

---register base object classes, so that the engine recognizes them
local function Init()
    RegisterGameClass(Object)
    RegisterGameClass(Object3d)
end
Init()

---------------------------------------------------------------------------------------------------