---------------------------------------------------------------------------------------------------
---camera_debugger_prefab.lua
---date created: 2021.8.13
---reference: THlib/background/backgournd.lua
---desc: Defines camera debugger prefab
---modifiers:
---     Karl, 2021.8.13, moved the code from THlib and split the file background.lua to two parts,
---     this is the part with the definition of the camera_setter (renamed to camera debugger)
---------------------------------------------------------------------------------------------------

local Prefab = require("core.prefab")

---显示菜单，能够调整3D参数 | display the menu for global "3d" view parameters
---调试使用的辅助功能 | used for debugging
---@class Prefab.CameraDebugger:Prefab.Object
local M = Prefab.NewX(Prefab.Object)

local Coordinates = require("BHElib.unclassified.coordinates_and_screen")

---------------------------------------------------------------------------------------------------

function M:init()
    self.group = GROUP_GHOST
    self.text = { "eye", "at", "up", "fovy", "z", "fog", "color" }
    self.nitem = { 3, 3, 3, 1, 2, 2, 3 }
    self.pos = 1
    self.posx = 1
    self.pos_changed = 0
    self.edit = false
end

---TODO: replace api
function M:frame()
    if GetLastKey() == setting.keys.shoot then
        self.edit = true
        PlaySound("se:select00", 0.3)
        if not self.edit then
            self.posx = 1
        end
    end
    if GetLastKey() == setting.keys.spell then
        self.edit = false
        PlaySound("se:cancel00", 0.3)
    end
    if self.pos_changed > 0 then
        self.pos_changed = self.pos_changed - 1
    end
    if self.edit then
        local step = 0.1
        if KeyIsDown 'slow' then
            step = 0.01
        end
        if GetLastKey() == setting.keys.left then
            self.posx = self.posx - 1
            PlaySound("se:select00", 0.3)
        end
        if GetLastKey() == setting.keys.right then
            self.posx = self.posx + 1
            PlaySound("se:select00", 0.3)
        end
        self.posx = (self.posx - 1 + self.nitem[self.pos]) % self.nitem[self.pos] + 1
        if self.pos <= 3 or self.pos == 5 then
            local item = lstg.view3d[self.text[self.pos]]
            if GetLastKey() == setting.keys.up then
                item[self.posx] = item[self.posx] + step
                PlaySound('select00', 0.3)
            end
            if GetLastKey() == setting.keys.down then
                item[self.posx] = item[self.posx] - step
                PlaySound('select00', 0.3)
            end
        elseif self.pos == 6 then
            if GetLastKey() == setting.keys.up then
                lstg.view3d.fog[self.posx] = lstg.view3d.fog[self.posx] + step
                PlaySound('select00', 0.3)
                if lstg.view3d.fog[1] < -0.0001 then
                    if lstg.view3d.fog[1] > -0.9999 then
                        lstg.view3d.fog[1] = 0
                    elseif lstg.view3d.fog[1] > -1.9999 then
                        lstg.view3d.fog[1] = -1
                    end
                end
            end
            if GetLastKey() == setting.keys.down then
                lstg.view3d.fog[self.posx] = lstg.view3d.fog[self.posx] - step
                if lstg.view3d.fog[1] < -1.0001 then
                    lstg.view3d.fog[1] = -2
                elseif lstg.view3d.fog[1] < -0.0001 then
                    lstg.view3d.fog[1] = -1
                end
                PlaySound('select00', 0.3)
            end
            if abs(lstg.view3d.fog[1]) < 0.0001 then
                lstg.view3d.fog[1] = 0
            end
            if abs(lstg.view3d.fog[2]) < 0.0001 then
                lstg.view3d.fog[2] = 0
            end
        elseif self.pos == 7 then
            local c = {}
            local alpha
            local step = 10
            if KeyIsDown 'slow' then
                step = 1
            end
            alpha, c[1], c[2], c[3] = lstg.view3d.fog[3]:ARGB()
            if GetLastKey() == setting.keys.up then
                c[self.posx] = c[self.posx] + step
                PlaySound('select00', 0.3)
            end
            if GetLastKey() == setting.keys.down then
                c[self.posx] = c[self.posx] - step
                PlaySound('select00', 0.3)
            end
            c[self.posx] = max(0, min(c[self.posx], 255))
            lstg.view3d.fog[3] = Color(alpha, unpack(c))
        elseif self.pos == 4 then
            if GetLastKey() == setting.keys.up then
                lstg.view3d.fovy = lstg.view3d.fovy + step
                PlaySound('select00', 0.3)
            end
            if GetLastKey() == setting.keys.down then
                lstg.view3d.fovy = lstg.view3d.fovy - step
                PlaySound('select00', 0.3)
            end
        end
    else
        if GetLastKey() == setting.keys.up then
            self.pos = self.pos - 1
            self.pos_changed = ui.menu.shake_time
            PlaySound('select00', 0.3)
        end
        if GetLastKey() == setting.keys.down then
            self.pos = self.pos + 1
            self.pos_changed = ui.menu.shake_time
            PlaySound('select00', 0.3)
        end
        self.pos = (self.pos + 6) % 7 + 1
    end
    if KeyIsPressed 'special' then
        Print("--set camera")
        Print(string.format("Set3D('eye',%.2f,%.2f,%.2f)", unpack(lstg.view3d.eye)))
        Print(string.format("Set3D('at',%.2f,%.2f,%.2f)", unpack(lstg.view3d.at)))
        Print(string.format("Set3D('up',%.2f,%.2f,%.2f)", unpack(lstg.view3d.up)))
        Print(string.format("Set3D('fovy',%.2f)", lstg.view3d.fovy))
        Print(string.format("Set3D('z',%.2f,%.2f)", unpack(lstg.view3d.z)))
        Print(string.format("Set3D('fog',%.2f,%.2f,Color(%d,%d,%d,%d))", lstg.view3d.fog[1], lstg.view3d.fog[2], lstg.view3d.fog[3]:ARGB()))
        Print("--")
    end
end

local function _str(num)
    return string.format('%.2f', num)
end

function M:render()
    local y = 340
    SetViewMode 'ui'
    SetImageState('white', '', Color(0xFF000000))
    RenderRect('white', 424, 632, 256, 464)
    RenderTTF('sc_pr', 'camera setting', 528, 528, y + 4.5 * ui.menu.sc_pr_line_height, y + 4.5 * ui.menu.sc_pr_line_height, Color(255, unpack(ui.menu.title_color)), 'centerpoint')
    ui.DrawMenuTTF('sc_pr', '', self.text, self.pos, 432, y, 1, self.timer, self.pos_changed, 'left')
    local _a, _r, _g, _b = lstg.view3d.fog[3]:ARGB()
    ui.DrawMenuTTF('sc_pr', '', {
        _str(lstg.view3d.eye[1]),
        _str(lstg.view3d.at[1]),
        _str(lstg.view3d.up[1]),
        _str(lstg.view3d.fovy),
        _str(lstg.view3d.z[1]),
        _str(lstg.view3d.fog[1]),
        tostring(_r)
    }, self.pos, 496, y, 1, self.timer, self.pos_changed, 'right')
    ui.DrawMenuTTF('sc_pr', '', {
        _str(lstg.view3d.eye[2]),
        _str(lstg.view3d.at[2]),
        _str(lstg.view3d.up[2]),
        '',
        _str(lstg.view3d.z[2]),
        _str(lstg.view3d.fog[2]),
        tostring(_g)
    }, self.pos, 560, y, 1, self.timer, self.pos_changed, 'right')
    ui.DrawMenuTTF('sc_pr', '', {
        _str(lstg.view3d.eye[3]),
        _str(lstg.view3d.at[3]),
        _str(lstg.view3d.up[3]),
        '',
        '',
        '',
        tostring(_b)
    }, self.pos, 624, y, 1, self.timer, self.pos_changed, 'right')
    if self.edit and self.timer % 30 < 15 then
        RenderTTF('sc_pr', '_', 432 + self.posx * 64, 432 + self.posx * 64, y + (4 - self.pos) * ui.menu.sc_pr_line_height, y + (4 - self.pos) * ui.menu.sc_pr_line_height, Color(255, unpack(ui.menu.title_color)), 'right', 'vcenter', 'noclip')
    end
    SetViewMode 'world'
end

Prefab.Register(M)

return M