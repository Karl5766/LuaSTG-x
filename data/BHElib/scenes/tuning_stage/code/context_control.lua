
local hot_iter = HotIter()
if external_objects.hot_iter then
    hot_iter:inheritIndices(external_objects.hot_iter)
end
external_objects.hot_iter = hot_iter

IterTypes:addBulletTypeColorIter(hot_iter, "Bullet")

local function SETXY(cur, next, i)
	local y = player.y
	next.xshift = player.x
	if next.i % 2 == 0 then
		y = y - 150
	else
		y = y + 150
	end
	local limit_y = 234
	y = min(limit_y, max(-limit_y, y))
	next.yshift = y
end

local function op_xy(next, x, y)
	return next.xshift + x, next.yshift + y
end

local function APPLYXY(cur, next, i)
	next.x, next.y = op_xy(next, next.x, next.y)
end

local function SCR(cur, next, i)
	local master = next.s_master
	local x, y = op_xy(next, next.x, next.y) 
	next.aimang = Angle(x, y, player.x, player.y)
end
