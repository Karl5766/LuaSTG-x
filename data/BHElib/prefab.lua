---------------------------------------------------------------------------------------------------
---prefab.lua
---desc: Defines the inheritance of game objects, and two base prefabs Object and Object3d for all
---     other prefabs to inherit from.
---modifier:
---     Karl, 2021.2.16, renamed the file from class.lua to game_object.lua. Removed the global
---     lists and changed to the same naming conventions as the rest of the project
---     2021.3.16, renamed Class to Prefab under zino's suggestion; moved code from
---     to this file
---     2021.4.9, re-writes the file again for require() format
---------------------------------------------------------------------------------------------------

---@class Prefab
---a namespace, functions that initialize and register prefabs and prefabs that are registered
---will be put under this namespace.
local Prefab = {}

---------------------------------------------------------------------------------------------------
---cache variables and functions

local type = type
local pairs = pairs
local Insert = table.insert

---------------------------------------------------------------------------------------------------

-- names of the 6 callbacks that each game object has
local callbacks = { "init", "del", "frame", "render", "colli", "kill" }
Prefab.callbacks = callbacks
local callbacks_lookup_table = {}
for i = 1, #callbacks do
    local callback_name = callbacks[i]
    callbacks_lookup_table[callback_name] = true
end
-- a table that contains all prefabs created; used for register all game classes at once
local all_prefabs = {}

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
function Prefab.New(callback_base, attribute_base)
    if (type(callback_base) ~= 'table') or not callback_base.is_class then
        error(i18n 'Invalid base')
    end
    local new_prefab = { 0, 0, 0, 0, 0, 0 }
    if attribute_base then
        for key, value in pairs(attribute_base) do
            if type(key) ~= "number" then
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

    Insert(all_prefabs, new_prefab)
    return new_prefab
end

local RawNew = lstg.RawNew

--- Create extended game object class.
--- You can use classname(...) to create an instance of game object.
--- Example: `classname = xclass(object)`
---@param base object
---@param define table
---@return object
function Prefab.NewX(base)

    local ret = Prefab.New(base, base)
    ret['.x'] = true
    if base['.3d'] then
        ret['.3d'] = true
    end
    local methods
    local function get_methods()
        methods = {}
        for k, v in pairs(ret) do
            if type(v) == 'function' and type(k) == 'string' and not callbacks_lookup_table[k] then
                methods[k] = v
                print(k)
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
xclass = Prefab.NewX

---------------------------------------------------------------------------------------------------

local _prefab_num = 0  -- number of prefabs registered by RegisterGameClass()
local _prefab_id = {}  -- a table that maps registered prefabs to their unique ids

---@~chinese 在引擎上登记game class；prefab的6个回调函数属性如果不是函数则设为默认回调函数
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
function Prefab.Register(prefab)
    for i = 1, 6 do
        if type(prefab[i]) ~= "function" then
            prefab[i] = prefab[callbacks[i]]
        end
    end

    if prefab[3] == DefaultFrameFunc then
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
end

---------------------------------------------------------------------------------------------------
---Object

---@~chinese 所有game object的基类
---
---@~English the base prefab of all game objects
---@type Prefab
local DefaultFrameFunc = function() end
Prefab.Object = {
    0, 0, 0, 0, 0, 0;
    is_class = true,
    init     = function()
    end,
    del      = function()
    end,
    frame    = DefaultFrameFunc,
    render   = DefaultRenderFunc,
    colli    = function(other)
    end,
    kill     = function()
    end
}
Prefab.Register(Prefab.Object)

---------------------------------------------------------------------------------------------------
---Object3d

Prefab.Object3d = Prefab.New(Prefab.Object)
Prefab.Object3d['.3d'] = true
Prefab.Register(Prefab.Object3d)

---------------------------------------------------------------------------------------------------
---Renderer

local SetRenderView = require("BHElib.coordinates_and_screen").setRenderView
Prefab.Renderer = Prefab.New(Prefab.Object)
function Prefab.Renderer:init(layer, master, coordinates_name)
    self.group = GROUP_GHOST
    self.layer = layer
    self.master = master
    self.coordinates_name = coordinates_name
end

function Prefab.Renderer:render()
    local master = self.master
    SetRenderView(self.coordinates_name)
    master:render()
    SetRenderView("game")  -- game objects are usually rendered in "game" view
end

Prefab.Register(Prefab.Renderer)

---------------------------------------------------------------------------------------------------

---objects can only be created from defined prefabs after this function is run
---prefabs should be defined before calling this function
function Prefab.RegisterAllDefinedPrefabs()
    for i = 1, #all_prefabs do
        Prefab.Register(all_prefabs[i])
    end
end

return Prefab