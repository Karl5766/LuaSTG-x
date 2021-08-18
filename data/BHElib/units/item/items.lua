---------------------------------------------------------------------------------------------------
---items.lua
---author: Karl
---date created: 2021.8.6
---desc: Defines various items in the game
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")
local CollectableItem = require("BHElib.units.item.collectable_item")

---@class Item
local M = {}

---------------------------------------------------------------------------------------------------

local _item_global = {
    init_y = 1,
    acc_y = -0.01,
    max_descend_speed = -1.5,
    flying_speed = 10,
    collect_radius = 20,
    collect_time = 0,
    del_y = -244
}

local function InitItemBase(self, stage)
    CollectableItem.init(
            self,
            _item_global.init_y,
            _item_global.acc_y,
            _item_global.max_descend_speed,
            _item_global.flying_speed,
            _item_global.collect_radius,
            _item_global.collect_time,
            _item_global.del_y,
            stage)
end

---------------------------------------------------------------------------------------------------

local function DefineSimpleItem(image, on_collect)
    local Item = Prefab.NewX(CollectableItem)

    function Item:init(stage)
        self.img = image
        InitItemBase(self, stage)
    end

    Item.onCollect = on_collect

    function Item:onBorderCollect(player)
        self:setFlyTarget(player)
    end

    Prefab.Register(Item)
    return Item
end

---------------------------------------------------------------------------------------------------

local _sound_name = "se:item00"
local _vol = 0.15

M.Power = DefineSimpleItem("image:item_power", function(self, player)
    CollectableItem.onCollect(self, player)
    player:addPower(1)
    PlaySound(_sound_name, _vol, 0, true)
end)

M.Point = DefineSimpleItem("image:item_point", function(self, player)
    CollectableItem.onCollect(self, player)
    self.stage:addScore(12800)
    PlaySound(_sound_name, _vol, 0, true)
end)

M.FullPower = DefineSimpleItem("image:item_full_power", function(self, player)
    CollectableItem.onCollect(self, player)
    player:addPower(400)
    PlaySound(_sound_name, _vol, 0, true)
end)

M.BigPower = DefineSimpleItem("image:item_big_power", function(self, player)
    CollectableItem.onCollect(self, player)
    player:addPower(100)
    PlaySound(_sound_name, _vol, 0, true)
end)

M.Extend = DefineSimpleItem("image:item_extend", function(self, player)
    CollectableItem.onCollect(self, player)
    local player_resource = player:getPlayerResource()
    player_resource.num_life = player_resource.num_life + 1
    PlaySound(_sound_name, _vol, 0, true)
end)

M.Bomb = DefineSimpleItem("image:item_bomb", function(self, player)
    CollectableItem.onCollect(self, player)
    local player_resource = player:getPlayerResource()
    player_resource.num_bomb = player_resource.num_bomb + 1
    PlaySound(_sound_name, _vol, 0, true)
end)

---------------------------------------------------------------------------------------------------

-- small faith (faith point)
do
    local Item = Prefab.NewX(CollectableItem)

    function Item:init(stage)
        self.img = "image:item_small_faith"
        CollectableItem.init(
                self,
                _item_global.init_y,
                _item_global.acc_y,
                _item_global.max_descend_speed,
                _item_global.flying_speed,
                _item_global.collect_radius,
                0,
                _item_global.del_y,
                stage)
    end

    function Item:onCollect(player)
        CollectableItem.onCollect(self, player)
        self.stage:addScore(3200)
        PlaySound(_sound_name, _vol, 0, true)
    end

    function Item:frame()
        if self.timer == 20 then
            self:setFlyTarget(self.stage:getPlayer())
        end
        CollectableItem.frame(self)
    end

    Prefab.Register(Item)
    M.SmallFaith = Item
end

return M