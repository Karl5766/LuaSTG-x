---------------------------------------------------------------------------------------------------
---coordinates_and_screen.lua
---date: 2021.2.12
---desc:
---modifier:
---     Karl, 2021.2.14, split the file from screen.lua; formatted the local variables
---------------------------------------------------------------------------------------------------

local _world = {
    l      = -192, r = 192, b = -224, t = 224,  -- world
    boundl = -224, boundr = 224, boundb = -256, boundt = 256,  -- out of bound deletion
    scrl   = 128, scrr = 512, scrb = 16, scrt = 464,  -- screen
    pl     = -192, pr = 192, pb = -224, pt = 224
}
---contains four kinds of coordinate boundaries
---l/r/b/t: world的逻辑坐标范围
---bound(l/r/b/t): 边界范围，超出范围的游戏对象会自动回收
---scr(l/r/b/t): l/r/b/t在screen坐标系下的坐标
---p(l/r/b/t): 用于player限位
lstg.world = _world

function _SetBound()
    SetBound(_world.boundl, _world.boundr, _world.boundb, _world.boundt)
end
_SetBound()

----------------------------------------------------------------------------------

--- 坐标系变换
--- 计算结果结果并非实际屏幕坐标系，而是screen的坐标系
--- 用于boss扭曲效果时请将结果加上screen.dx和screen.dy

---@param x number x in world coordinates
---@param y number y in world coordinates
---@return number, number coordinates in screen coordinates
function WorldToScreen(x, y)
    local scale_x = (_world.r - _world.l) / (_world.scrr - _world.scrl)
    local scale_y = (_world.t - _world.b) / (_world.scrt - _world.scrb)
    local ret_x = (_world.scrl + scale_x * (x - _world.l))
    local ret_y = (_world.scrb + scale_y * (y - _world.b))
    return ret_x, ret_y
end

---@param x number x in world coordinates
---@param y number y in world coordinates
---@param flipY boolean if true, the result y starts from top of screen and increases moving down, instead of from bottom of screen and increases moving up
---@return number, number coordinates in game coordinates
function WorldToGame(x, y, flipY)
    x, y = WorldToScreen(x, y)
    if flipY then
        y = screen.height - y
    end
    local scale = screen.scale
    return (x + screen.dx) * scale, (y + screen.dy) * scale
end