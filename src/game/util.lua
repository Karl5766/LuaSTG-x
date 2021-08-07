local M = {}

function M.stopMusics()
    local t_global, t_stage = EnumRes(ENUM_RES_TYPE.bgm)
    for _, v in pairs(t_global) do
        StopMusic(v)
    end
    for _, v in pairs(t_stage) do
        StopMusic(v)
    end
end

function M.stopSounds()
    local t_global, t_stage = EnumRes(ENUM_RES_TYPE.snd)
    for _, v in pairs(t_global) do
        StopSound(v)
    end
    for _, v in pairs(t_stage) do
        StopSound(v)
    end
end

function M.stopAudios()
    M.stopMusics()
    M.stopSounds()
end

local resTypeNames = {
    [1] = 'Texture',
    [2] = 'Sprite',
    [3] = 'Animation',
    [4] = 'Music',
    [5] = 'SoundEffect',
    [6] = 'Particle',
    [7] = 'Font',
    [8] = 'FX',
    [9] = 'RenderTarget',
}

function M.collectResInfo()
    local t = {}
    local count = {
        global       = 0,
        stage        = 0,
        Texture      = 0,
        Sprite       = 0,
        Animation    = 0,
        Music        = 0,
        SoundEffect  = 0,
        Particle     = 0,
        Font         = 0,
        FX           = 0,
        RenderTarget = 0,
    }
    local pools = lstg.getResourcePool()
    for _, poolName in ipairs({ 'global', 'stage' }) do
        local pool = pools[poolName]
        for i = 1, #resTypeNames do
            local p = pool[i]
            local keys = p:keys()
            table.sort(keys)
            for i, key in ipairs(keys) do
                ---@type lstg.Resource
                local res = p:at(key)
                local typeName = resTypeNames[res:getType()] or 'N/A'
                local path = res:getPath()
                local info = res:getInfo()
                table.insert(t, {
                    name     = key,
                    info     = info,
                    typeName = typeName,
                    path     = path,
                    poolName = poolName
                })
                if count[poolName] then
                    count[poolName] = count[poolName] + 1
                else
                    count[poolName] = 1
                end
                if count[typeName] then
                    count[typeName] = count[typeName] + 1
                else
                    count[typeName] = 1
                end
            end
        end
    end
    return t, count
end

return M
