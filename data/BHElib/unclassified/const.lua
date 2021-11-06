-- 碰撞组
-- collision groups

GROUP_GHOST           = 0
GROUP_ENEMY_BULLET    = 1
GROUP_ENEMY           = 2
GROUP_PLAYER_BULLET   = 3
GROUP_PLAYER          = 4
GROUP_ITEM            = 5
GROUP_ALL             = 16


-- 层次结构
-- layer ordering

LAYER_HUD                   = -700  -- for ui hud
LAYER_BG                    = -700
LAYER_SPELL_BG              = -699.9
LAYER_ENEMY_CAST_EFFECT     = -650
LAYER_ENEMY                 = -600
LAYER_ENEMY_DEATH_EFFECT    = -550
LAYER_PLAYER_BULLET         = -500
LAYER_PLAYER_BULLET_CANCEL  = -450
LAYER_PLAYER                = -400
LAYER_ITEM                  = -300
LAYER_ENEMY_BULLET          = -200
LAYER_BULLET_CANCEL         = -150
LAYER_BULLET_BLINK          = -100
LAYER_BULLET_EFFECT         = -100
LAYER_DIALOGUE_PORTRAIT     = -51
LAYER_DIALOGUE_BOX          = -50
LAYER_TOP                   = 0
LAYER_MENU                  = 0


-- 常量
-- math constants

---π
---@type number
PI                    = math.pi
---π*2
---@type number
PIx2                  = math.pi * 2
---π/2
---@type number
PI_2                  = math.pi * 0.5
---π/4
---@type number
PI_4                  = math.pi * 0.25
---√2
SQRT2                 = math.sqrt(2)
---√3
SQRT3                 = math.sqrt(3)
---√2/2
SQRT2_2               = math.sqrt(0.5)
---0.618*360
GOLD                  = 360 * (math.sqrt(5) - 1) / 2

INFINITE = math.huge