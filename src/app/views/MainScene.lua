---@class MainScene:ViewBase
local MainScene = class("MainScene", cc.load("mvc").ViewBase)
local director = cc.Director:getInstance()

for _, v in ipairs({ 'FocusLoseFunc', 'FocusGainFunc' }) do
    _G[v] = _G[v] or function()
    end
end

local _is_mod_loaded = false

---call lstg.loadMod only if it has not been called by this method
local function _safe_load_mod()
    if not _is_mod_loaded then
        _is_mod_loaded = true
        return lstg.loadMod()
    end
end

---Start one of the two launcher uis or start the game,
---depending on the value of local skip_setting and skip_selection
function MainScene:onEnter()
    self:runGameScene()
end

---run/switch to the game scene
function MainScene:runGameScene()
    -- in game
    local scene = _safe_load_mod()

    if director:getRunningScene() then
        director:pushScene(scene)
    else
        director:runWithScene(scene)
    end
end

return MainScene
