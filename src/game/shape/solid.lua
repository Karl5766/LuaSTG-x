
local M = {}

---------------------------------------------------------------------------------------------------

local c4f_white = { a = 1, r = 1, g = 1, b = 1 }
local function color_to_c4f(c)
    if c then
        return { a = c.a / 255, r = c.r / 255, g = c.g / 255, b = c.b / 255 }
    else
        return c4f_white
    end
end

---------------------------------------------------------------------------------------------------

function M.circle(r, rot, nSeg, color)
    local node = cc.DrawNode:create()
    node:drawSolidCircle(cc.p(0, 0), r or 1, rot or 0, nSeg or 360, color_to_c4f(color))
    return node
end

function M.sector(r, rot, ang, nSeg, color)
    rot = math.rad(rot)
    ang = math.rad(ang)
    local delta = 2 * math.pi / nSeg
    local n = ang / delta
    local vertices = {}
    for i = 1, n do
        local rads = (i - 1) * delta
        local xx = r * math.cos(rads + rot)
        local yy = r * math.sin(rads + rot)
        table.insert(vertices, cc.p(xx, yy))
    end
    local node = cc.DrawNode:create()
    node:drawSolidPoly(vertices, #vertices, color_to_c4f(color))
    return node
end

function M.rect(w, h, color)
    local node = cc.DrawNode:create()
    node:drawSolidRect(cc.p(-w / 2, -h / 2), cc.p(w / 2, h / 2), color_to_c4f(color))
    return node
end

function M.triangle(x1, y1, x2, y2, x3, y3, color)
    local node = cc.DrawNode:create()
    node:drawTriangle(cc.p(x1, y1), cc.p(x2, y2), cc.p(x3, y3), color_to_c4f(color))
    return node
end

return M
