--TODO
---@class x.launcher:ViewBase
local M = class("MainScene", require('cc.ViewBase'))
local im = imgui
local wi = require('imgui.Widget')

local function createLabel(str, size)
    return cc.Label:createWithSystemFont(str, 'Arial', size or 32)
end
---
---@param label cc.Label
---@param onClick function
local function createButton(label, onClick)
    local h_pad = 8
    local btn = wi.Widget()
    local node = cc.Node()
    node:addChild(label)
    btn:addChild(node)
    btn:setHandler(function()
        local w = im.getWindowWidth() - im.getStyle().WindowPadding.x * 2
        local sz = label:getContentSize()
        local h = sz.height + h_pad
        node:setContentSize(w, h)
        label:setPosition(w / 2, h / 2)
        if im.ccNodeButton(node, 0) then
            if onClick then
                onClick()
            end
        end
    end)
    return btn
end

local function getDocking()
    local docking_window_flags = bit.bor(
    --im.WindowFlags.MenuBar,
            im.WindowFlags.NoDocking,
            im.WindowFlags.NoTitleBar,
            im.WindowFlags.NoCollapse,
            im.WindowFlags.NoResize,
            im.WindowFlags.NoMove,
            im.WindowFlags.NoBringToFrontOnFocus,
            im.WindowFlags.NoNavFocus,
            im.WindowFlags.NoBackground
    )
    local id = 0xaaa
    local function f()
        local viewport = im.getMainViewport()
        im.setNextWindowPos(viewport.Pos)
        im.setNextWindowSize(viewport.Size)
        im.setNextWindowViewport(viewport.ID)
        im.pushStyleVar(im.StyleVar.WindowRounding, 0)
        im.pushStyleVar(im.StyleVar.WindowBorderSize, 0)
        im.pushStyleVar(im.StyleVar.WindowPadding, im.p(0, 0))
        im.begin('Dock Space', nil, docking_window_flags)
        im.popStyleVar(3)
        im.dockSpace(id, im.p(0, 0), im.DockNodeFlags.PassthruCentralNode)
        im.endToLua()
    end
    return f, id
end

function M:onCreate()
    local dock_id = 'launcher.dock'
    require('imgui.lstg.util').load(nil, dock_id, true)
    local la = im.get()
    im.show()

    la:addChild(function()
        --im.setNextWindowDockID(im.getID('Dock Space'), im.Cond.Always)
        im.setNextWindowDockID(0x9F5F9276, im.Cond.Always)
    end)
    la:addChild(im.showDemoWindow)

    local wrapper = wi.styleVar(im.StyleVar.WindowPadding, im.p(0, 0))
    wrapper:addTo(la)

    local win = wi.Window('win1')
    win:addTo(wrapper)
    win:setFlags(im.WindowFlags.NoTitleBar)

    --

    --im.getStyle():scaleAllSizes(3)
    win:addChild(function()
        --local sp = im.getStyle().ItemSpacing
        im.pushStyleVar(im.StyleVar.ItemSpacing, im.p(0, 0))
        im.pushStyleVar(im.StyleVar.FramePadding, im.p(0, 0))
    end)

    local c1
    c1 = wi.Widget(function()
        local w = im.getWindowContentRegionWidth()
        local id = im.getID(tostring(self) .. 'c1')
        if im.beginChildFrame(id, im.p(w / 2, 0), 0) then
            local col = im.getStyleColorVec4(im.Col.WindowBg)
            col.w = 1
            im.pushStyleColor(im.Col.Header, col)
            wi._handler(c1)
            im.popStyleColor()
        end
        im.endChildFrame()
    end)
    local id1, id2 = '1', '2'
    --local id1 = tostring(im.getID('Dock Space'))
    --local id2 = ('%d'):format(im.getID(dock_id))
    local sel = require('imgui.cc.SelectableGroup')(
            { createLabel('AAA'), createLabel(id2), createLabel(id1) })
    sel:setOnSelect(function(_, idx)
        print(idx)
    end)

    sel:addChild(function()
        im.pushID(im.getID('Dock Space'))
        im.textUnformatted(('%x'):format(im.getID('Dock Space')))
        im.textUnformatted(('%x'):format(im.getID(dock_id)))
        im.popID()
    end)

    c1:addChild(sel)
    win:addChild(c1)

    win:addChild(im.sameLine)

    local c2
    c2 = wi.Widget(function()
        local w = im.getWindowContentRegionWidth()
        local col = im.getStyleColorVec4(im.Col.WindowBg)
        col.w = 1
        im.pushStyleColor(im.Col.FrameBg, col)
        local id = im.getID(tostring(self) .. 'c2')
        if im.beginChildFrame(id, im.p(w / 2, 0), 0) then
            wi._handler(c2)
        end
        im.endChildFrame()
        im.popStyleColor()
    end)
    local sel2 = require('imgui.cc.SelectableGroup')(
            { createLabel('A'), createLabel('BBB'), createLabel('CCC') })
    sel2:setOnSelect(function(_, idx)
        print(idx)
    end)

    c2:addChild(sel2)
    win:addChild(c2)

    win:addChild(function()
        im.popStyleVar(2)
    end)

    local mods = M.enumMods(plus.getWritablePath() .. 'mod/')
    local mod_sel
end

function M.enumMods(path)
    SystemLog(string.format('enum MODs in %q', path))
    local ret = {}
    local files = plus.EnumFiles(path)
    for i, v in ipairs(files) do
        if v.isDirectory then
            if plus.FileExists(path .. v.name .. '/root.lua') then
                table.insert(ret, v)
            end
        else
            if string.lower(v.name:match(".+%.(%w+)$") or '') == 'zip' then
                v.name = v.name:sub(1, -5)
                assert(v.name ~= '')
                table.insert(ret, v)
            end
        end
    end
    table.sort(ret, function(a, b)
        if a.isDirectory ~= b.isDirectory then
            return a.isDirectory
        end
        return a.name < b.name
    end)
    return ret
end

function M.saveSetting()
    lstg.saveSettingFile()
end

return M
