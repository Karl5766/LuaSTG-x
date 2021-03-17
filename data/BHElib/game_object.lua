---------------------------------------------------------------------------------------------------
---object_prefab.lua
---desc: Defines the inheritance of game objects, and two base prefabs Object and Object3d for all
---     other prefabs to inherit from.
---modifier:
---     Karl, 2021.2.16, renamed the file from class.lua to game_object.lua. Removed the global
---     lists and changed to the same naming conventions as the rest of the project
---     Karl, 2021.3.16, renamed Class() to NewPrefab() under zino's suggestion; moved code from
---     to this file
---------------------------------------------------------------------------------------------------
---cache variables and functions

local type = type
local pairs = pairs

---------------------------------------------------------------------------------------------------

-- names of the 6 callbacks that each game object has
local callbacks = { 'init', 'del', 'frame', 'render', 'colli', 'kill', }
local callbacks_lookup_table = {}
for i = 1, #callbacks do
    local callback_name = callbacks[i]
    callbacks_lookup_table[callback_name] = true
end

---game objects are created from prefabs
---prefabs are tables that can be used to initialize game objects with pre-defined callback
---functions. A game object can be created from a prefab by New(prefab_name, ...), where ... are
---parameters to the init function defined in the prefab
---note New can only be called on the prefab after it is registered to the engine with
---RegisterClass()

---@~chinese 定义一个类，基类会给新类复制6个回调函数；新类的is_class属性会被设为true，base属性指向基类，
---
---@~english Define a prefab, the callback_base will assign its 6 callbacks to the new class;
---
---@~english the new prefab will have is_class attribute set to ture, and base attribute set to
---callback_base
---
---@param callback_base Prefab 新类继承此类的6个默认回调函数
---@return Prefab 新定义的prefab
function MakePrefab(callback_base, attribute_base)
    if (type(callback_base) ~= 'table') or not callback_base.is_class then
        error(i18n 'Invalid base prefab')
    end
    local new_prefab = { 0, 0, 0, 0, 0, 0 }
    if attribute_base then
        for key, value in pairs(attribute_base) do
            if type(value) ~= "number" then
                new_prefab[key] = value
            end
        end
    end
    new_prefab.is_class = true
    new_prefab.init = callback_base.init
    new_prefab.del = callback_base.del
    new_prefab.frame = callback_base.frame
    new_prefab.render = callback_base.render
    new_prefab.colli = callback_base.colli
    new_prefab.kill = callback_base.kill
    new_prefab.base = callback_base
    return new_prefab
end

local RawNew = lstg.RawNew

--- Create extended game object class.
--- You can use classname(...) to create an instance of game object.
--- Example: `classname = xclass(object)`
---@param base object
---@param define table
---@return object
function xclass(base)

    local ret = MakePrefab(base, base)
    ret['.x'] = true
    if base['.3d'] then
        ret['.3d'] = true
    end
    local methods
    local function get_methods()
        for k, v in pairs(ret) do
            if type(v) == 'function' and type(k) == 'string' and not callbacks_lookup_table[k] then
                methods[k] = v
            end
        end
    end
    local mt = { __call = function(t, ...)
        local obj = RawNew(ret)
        if not methods then
            get_methods()
        end
        for k, v in pairs(methods) do
            obj[k] = v
        end
        ret[1](obj, ...)
        return obj
    end }
    return setmetatable(ret, mt)
end

---------------------------------------------------------------------------------------------------
---base prefabs

---@~chinese 所有game object的基类
---
---@~English the base prefab of all game objects
---@type Prefab
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

Object3d = MakePrefab(Object)
Object3d['.3d'] = true

---------------------------------------------------------------------------------------------------

local _prefab_num = 0  -- number of prefabs registered by RegisterGameClass()
local _prefab_id = {}  -- a table that maps registered prefabs to their unique ids

---@~chinese 把prefab注册为game class；prefab的6个回调函数属性如果不是函数则设为默认回调函数
---
---@~chinese prefab会被赋予一个独一无二的整数id;prefab的".classname"会被设置为prefab对应的全局变量名；
---
---@~english register a prefab as game class; if its 6 callbacks are not of type "function",
---they will be set to default game object callback functions.
---
---@~english prefab will be assigned a unique id different from any other prefab registered
---by this function at index 7
---
---@param prefab Prefab the prefab to register
function RegisterPrefab(prefab)
    for i = 1, 6 do
        if type(prefab[i]) ~= "function" then
            prefab[i] = prefab[callbacks[i]]
        end
    end

    if prefab[3] == Object.frame then
        prefab[3] = nil
    end
    if prefab[4] == DefaultRenderFunc then
        prefab[4] = nil
    end

    if _prefab_id[prefab] == nil then
        _prefab_num = _prefab_num + 1
        _prefab_id[prefab] = _prefab_num
        prefab[7] = _prefab_num
    else
        prefab[7] = _prefab_id[prefab]
    end

    RegisterClass(prefab)

    local prefab_name
    for key, value in pairs(_G) do
        if value == prefab then
            prefab_name = key
            break
        end
    end
    prefab['.classname'] = prefab_name
end

---register base object classes, so that the engine recognizes them
local function Init()
    RegisterPrefab(Object)
    RegisterPrefab(Object3d)
end
Init()

---------------------------------------------------------------------------------------------------