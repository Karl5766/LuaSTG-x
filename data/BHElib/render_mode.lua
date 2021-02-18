---------------------------------------------------------------------------------------------------
---corefunc.lua
---desc: Defines render modes for game objects
---modifier:
---     Karl, 2021.2.17 split from corefunc.lua
---------------------------------------------------------------------------------------------------
---defines internal modes

local _bop = ccb.BlendOperation
local _bfac = ccb.BlendFactor
---渲染模式 render modes
INTERNAL_MODE = {
    ['add+add']   = { _bop.ADD, _bfac.SRC_ALPHA, _bfac.ONE },
    ['add+alpha'] = { _bop.ADD, _bfac.SRC_ALPHA, _bfac.ONE_MINUS_SRC_ALPHA },
    ['add+sub']   = { _bop.SUBTRACT, _bfac.SRC_ALPHA, _bfac.ONE },
    ['add+rev']   = { _bop.RESERVE_SUBTRACT, _bfac.SRC_ALPHA, _bfac.ONE },

    ['mul+add']   = { _bop.ADD, _bfac.SRC_ALPHA, _bfac.ONE },
    ['mul+alpha'] = { _bop.ADD, _bfac.SRC_ALPHA, _bfac.ONE_MINUS_SRC_ALPHA },
    ['mul+sub']   = { _bop.SUBTRACT, _bfac.SRC_ALPHA, _bfac.ONE },
    ['mul+rev']   = { _bop.RESERVE_SUBTRACT, _bfac.SRC_ALPHA, _bfac.ONE },

    ['']          = { _bop.ADD, _bfac.SRC_ALPHA, _bfac.ONE_MINUS_SRC_ALPHA },
}

---------------------------------------------------------------------------------------------------

local shader_path = "src/shader/"
local internalShaders = {
    add   = { "Common.vert", "ColorAdd.frag" },
    addF1 = { "Fog_Liner.vert", "ColorAdd_Fog.frag" },
    addF2 = { "Fog_Exp1.vert", "ColorAdd_Fog.frag" },
    addF3 = { "Fog_Exp2.vert", "ColorAdd_Fog.frag" },
    mul   = { "Common.vert", "ColorMulti.frag" },
    mulF1 = { "Fog_Liner.vert", "ColorMulti_Fog.frag" },
    mulF2 = { "Fog_Exp1.vert", "ColorMulti_Fog.frag" },
    mulF3 = { "Fog_Exp2.vert", "ColorMulti_Fog.frag" },
}

for k, v in pairs(INTERNAL_MODE) do
    local m = k:sub(1, 3)
    if m == '' then
        m = 'mul'
    end
    local s = internalShaders[m]
    local p = CreateShaderProgramFromPath(
            shader_path .. s[1], shader_path .. s[2])
    assert(p)
    local rm = lstg.RenderMode:create(k, v[1], v[2], v[3], p)
    assert(rm, i18n 'failed to create RenderMode')
    -- backup default RenderMode
    rm:clone('_' .. k)
    for i = 1, 3 do
        local k_fog = ('%sF%d'):format(m, i)
        local s_fog = internalShaders[k_fog]
        local p_fog = CreateShaderProgramFromPath(
                shader_path .. s_fog[1], shader_path .. s_fog[2])
        local name = ('%s+fog%d'):format(k, i)
        local rm_fog = lstg.RenderMode:create(name, v[1], v[2], v[3], p_fog)
        assert(rm_fog, i18n 'failed to create RenderMode')
    end
end
lstg.RenderMode:getByName(''):setAsDefault()

function CreateRenderMode(name, blendEquation, blendFuncSrc, blendFuncDst, shaderName)
    local shaderProgram
    if not shaderName then
        shaderProgram = lstg.RenderMode:getDefault():getProgram()
    else
        local res = FindResFX(shaderName)
        if res then
            shaderProgram = res:getProgram()
        end
    end
    assert(shaderProgram)
    if type(blendEquation) == 'string' then
        blendEquation = _bop[blendEquation:upper()]
    end
    if type(blendFuncSrc) == 'string' then
        blendFuncSrc = _bfac[blendFuncSrc:upper()]
    end
    if type(blendFuncDst) == 'string' then
        blendFuncDst = _bfac[blendFuncDst:upper()]
    end
    local ret = lstg.RenderMode:create(
            name, blendEquation, blendFuncSrc, blendFuncDst, shaderProgram)
    assert(ret, i18n 'failed to create RenderMode')
    return ret
end

local p_light = CreateShaderProgramFromPath(
        shader_path .. 'NormalTex.vert', shader_path .. 'NormalTex.frag')
if p_light then
    local rm = lstg.RenderMode:create(
            'lstg.light', _bop.ADD, _bfac.SRC_ALPHA, _bfac.ONE_MINUS_SRC_ALPHA, p_light)
    assert(rm, i18n 'failed to create RenderMode')
end