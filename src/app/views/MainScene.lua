---@class MainScene:ViewBase
local MainScene = class("MainScene", cc.load("mvc").ViewBase)

local director = cc.Director:getInstance()

for _, v in ipairs({ 'FocusLoseFunc', 'FocusGainFunc' }) do
    _G[v] = _G[v] or function()
    end
end

local skip_setting
local skip_selection
local _is_mod_loaded = false

---call lstg.loadMod only if it has not been called by this method
local function _safe_load_mod()
    if not _is_mod_loaded then
        _is_mod_loaded = true
        return lstg.loadMod()
    end
end

---Set skip_setting and skip_selection attributes of main scene object.
---@param skip_set boolean whether to skip setting
---@param skip_set boolean whether to skip mod selection
function MainScene.setSkip(skip_set, skip_sel)
    skip_setting, skip_selection = skip_set, skip_sel
end

---Start one of the two launcher uis or start the game,
---depending on the value of local skip_setting and skip_selection
function MainScene:onEnter()
    if not skip_setting then
        self:runSettingLauncher()
    elseif not skip_selection then
        self:runSelectionLauncher()
    else
        self:runGameScene()
    end
end

---run the setting launcher (launcher_ui)
function MainScene:runSettingLauncher()
    local ok, ret = pcall(require, 'main_scene')
    if not ok then
        require('platform.launcher_ui')()
    end
end

---run/switch to the selection launcher (launcher2_ui)
function MainScene:runSelectionLauncher()
    local scene = require('app.views.GameScene'):create(nil, setting.mod)
    _safe_load_mod()
    require('platform.launcher2_ui')()
end

---run/switch to the game scene
function MainScene:runGameScene()
    -- in game
    local scene = _safe_load_mod()

    --local scene = require('app.views.GameScene'):create(nil, setting.mod)
    --scene:showWithScene()

    if director:getRunningScene() then
        director:pushScene(scene)
    else
        director:runWithScene(scene)
    end
end

return MainScene
