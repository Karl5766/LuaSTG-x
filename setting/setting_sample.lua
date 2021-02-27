--------------------------------------------------------------------------
---setting_sample.lua
---desc: A sample of what setting.ini may look like
---modifier:
---     Karl, 2021.2.27 adds a file header, and removed some entries
--------------------------------------------------------------------------

local KEY = require('keycode')
---@class lstg.setting
local M = {
    allowsnapshot  = true,
    username       = 'User',
    font           = '',
    timezone       = 8,
    resx           = 1706,
    resy           = 960,
    windowed       = true,
    vsync          = true,
    sevolume       = 100,
    bgmvolume      = 100,

    keys           = {
        up      = KEY.UP,
        down    = KEY.DOWN,
        left    = KEY.LEFT,
        right   = KEY.RIGHT,
        slow    = KEY.SHIFT,
        shoot   = KEY.Z,
        spell   = KEY.X,
        special = KEY.SPACE,
    },
    keysys         = {
        repfast         = KEY.CTRL,
        repslow         = KEY.ALT,
        menu            = KEY.ESCAPE,
        snapshot        = KEY.HOME,

        toggle_collider = KEY.F8,
    },
    -- note: key codes in [keys] and [keysys] should be mutex

    posteffect     = true,
    -- desktop
    windowsize_w   = 1708,
    windowsize_h   = 960,
    -- mobile
    orientation    = 'landscape',
    touchkey       = true,

    controller_map = {
        keys   = {
            up      = { 14 },
            down    = { 16 },
            left    = { 19 },
            right   = { 15 },
            slow    = { 05 },
            shoot   = { 09 },
            spell   = { 04 },
            special = { 07 },
        },
        keysys = {
            repfast  = { 01, true },
            repslow  = { 01, false },
            menu     = { 06 },
            snapshot = { 10 },
        },
    },
    --
    render_skip    = 0,
    --
    imgui_visible  = false,
}

return M
